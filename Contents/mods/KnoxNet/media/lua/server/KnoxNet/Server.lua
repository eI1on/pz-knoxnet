local Shared = require("KnoxNet/Shared")
local Persistence = require("KnoxNet/ChatPersistence")
local PlayerUtils = require("ElyonLib/PlayerUtils/PlayerUtils")
local AccessLevelUtils = require("ElyonLib/PlayerUtils/AccessLevelUtils")
local Logger = require("ElyonLib/Core/Logger"):new("KnoxNet", tostring(Shared.VERSION))

local Server = {}
Server.initialized = false
Server.knownUsers = {}
-- sorted usernames array (persisted). Server.knownUsers remains username -> true for membership tests.
Server.knownUsersSorted = {}
Server.lastMessageAtByUser = {}

local MODULE = Shared.MODULE
local C = Shared.COMMANDS
local A = Shared.GROUP_ACTION

local function send(player, command, args)
	if not (isClient and isClient()) and not (isServer and isServer()) then
		local KnoxClient = require("KnoxNet/Client")
		KnoxClient.receiveServerCommand(MODULE, command, args or {})
		return
	end
	if player and sendServerCommand then
		sendServerCommand(player, MODULE, command, args or {})
	end
end

local function onlinePlayer(username)
	return PlayerUtils.getOnlinePlayerByUsername(username)
end

local function rememberUser(username)
	username = Shared.normalizeUsername(username)
	if username and not Server.knownUsers[username] then
		Server.knownUsers[username] = true
		Server.knownUsersSorted[#Server.knownUsersSorted + 1] = username
		table.sort(Server.knownUsersSorted, function(a, b)
			return tostring(a):lower() < tostring(b):lower()
		end)
		Persistence.saveKnownUsers(Server.knownUsersSorted)
	end
end

local function userExists(username)
	username = Shared.normalizeUsername(username)
	if not username then
		return false
	end
	if AccessLevelUtils.isSinglePlayer() then
		return true
	end
	if Server.knownUsers[username] then
		return true
	end
	if onlinePlayer(username) then
		return true
	end
	return false
end

local function sendError(player, message, chatId)
	send(player, C.ERROR, { message = tostring(message or "KnoxNet error."), conversationId = chatId })
end

local function saveMeta(meta)
	meta.updatedAtTs = Shared.now()
	return Persistence.saveMeta(meta)
end

local function makeDmMeta(a, b)
	local id = Shared.dmIdFor(a, b)
	local now = Shared.now()
	local members = { a }
	if b ~= a then
		members[#members + 1] = b
	end
	return {
		id = id,
		kind = Shared.KIND.DM,
		title = "",
		members = members,
		admins = {},
		ownerUsername = nil,
		mutedUntilByUser = {},
		unreadCountByUser = {},
		createdAtTs = now,
		updatedAtTs = now,
		lastMessage = nil,
		version = Shared.VERSION,
	}
end

local function memberTitle(meta, viewer)
	if not meta then
		return ""
	end
	if meta.kind == Shared.KIND.GROUP then
		return meta.title or "Group"
	end
	for i = 1, #(meta.members or {}) do
		if meta.members[i] ~= viewer then
			return meta.members[i]
		end
	end
	return viewer or "Direct Chat"
end

local function pushConversationList(player)
	local username = Shared.playerUsername(player)
	rememberUser(username)
	local idx = Persistence.loadUserIndex(username)
	local rows = {}
	for i = 1, #(idx.entries or {}) do
		local chatId = idx.entries[i].id
		if chatId and not idx.hiddenConversationIds[chatId] then
			local meta = Persistence.loadMeta(chatId)
			if meta and Shared.isMember(meta, username) and not meta.disbanded then
				local summary = Shared.copySummary(meta, username)
				summary.title = memberTitle(meta, username)
				rows[#rows + 1] = summary
			end
		end
	end
	table.sort(rows, function(a, b)
		return (tonumber(a.updatedAtTs) or 0) > (tonumber(b.updatedAtTs) or 0)
	end)
	send(player, C.CONVERSATION_LIST_RESULT, { conversations = rows, settings = Shared.getSettings() })
end

local function knownUsersList()
	return Server.knownUsersSorted
end

local function notifyMembers(meta, command, payload, exclude)
	for i = 1, #(meta.members or {}) do
		local username = meta.members[i]
		if username ~= exclude then
			local p = onlinePlayer(username)
			if p then
				local copy = { message = payload and payload.message }
				copy.conversation = Shared.copySummary(meta, username)
				if copy.conversation then
					copy.conversation.title = memberTitle(meta, username)
				end
				send(p, command, copy)
			end
		end
	end
end

local function pushListsToOnlineMembers(meta)
	for i = 1, #(meta.members or {}) do
		local p = onlinePlayer(meta.members[i])
		if p then
			pushConversationList(p)
		end
	end
end

local function createOrGetDm(player, otherUsername)
	local from = Shared.playerUsername(player)
	otherUsername = Shared.normalizeUsername(otherUsername)
	if not otherUsername then
		return nil, "Recipient is required."
	end
	if not userExists(otherUsername) then
		return nil, "Recipient does not exist or has not used KnoxNet yet."
	end

	local id = Shared.dmIdFor(from, otherUsername)
	local meta = Persistence.loadMeta(id)
	if not meta then
		meta = makeDmMeta(from, otherUsername)
		Persistence.saveMeta(meta)
		Persistence.saveHistory(id, { conversationId = id, messages = {} })
	end
	Persistence.upsertUserChat(from, id)
	if otherUsername ~= from then
		Persistence.upsertUserChat(otherUsername, id)
	end
	return meta
end

local function createGroup(player, args)
	local settings = Shared.getSettings()
	if not Shared.canCreateGroup(player, settings) then
		return nil, "You are not allowed to create groups."
	end
	local owner = Shared.playerUsername(player)
	local members = Shared.parseCsvUsers(args and args.members or "")
	Shared.addUnique(members, owner)
	if #members < 1 then
		return nil, "A group needs at least one member."
	end
	if #members > settings.maxGroupMembers then
		return nil, "Group has too many members."
	end
	for i = 1, #members do
		if not userExists(members[i]) and members[i] ~= owner then
			return nil, "Unknown member: " .. tostring(members[i])
		end
	end

	if settings.maxGroupsPerPlayer > 0 then
		local idx = Persistence.loadUserIndex(owner)
		local count = 0
		for i = 1, #(idx.entries or {}) do
			local m = Persistence.loadMeta(idx.entries[i].id)
			if m and m.kind == Shared.KIND.GROUP and not m.disbanded then
				count = count + 1
			end
		end
		if count >= settings.maxGroupsPerPlayer then
			return nil, "You have reached the group limit."
		end
	end

	local now = Shared.now()
	local title = Shared.trim(args and args.title or "")
	if title == "" then
		title = "Group Chat"
	end
	local meta = {
		id = Shared.generateId("grp"),
		kind = Shared.KIND.GROUP,
		title = title:sub(1, 64),
		members = members,
		admins = { owner },
		ownerUsername = owner,
		mutedUntilByUser = {},
		unreadCountByUser = {},
		createdAtTs = now,
		updatedAtTs = now,
		lastMessage = nil,
		version = Shared.VERSION,
	}
	Persistence.saveMeta(meta)
	Persistence.saveHistory(meta.id, { conversationId = meta.id, messages = {} })
	for i = 1, #members do
		Persistence.upsertUserChat(members[i], meta.id)
	end
	return meta
end

local function fetchMessages(player, args)
	local username = Shared.playerUsername(player)
	local chatId = args and args.conversationId
	local meta = Persistence.loadMeta(chatId)
	if not meta or not Shared.isMember(meta, username) then
		sendError(player, "Conversation not found.", chatId)
		return
	end
	local settings = Shared.getSettings()
	local limit = math.floor(tonumber(args.limit) or settings.historyPageSize)
	limit = math.max(1, math.min(settings.historyPageMax, limit))
	local beforeTs = tonumber(args.beforeTs)
	local history = Persistence.loadHistory(chatId)
	local result = {}
	for i = #history.messages, 1, -1 do
		local m = history.messages[i]
		local ts = tonumber(m.createdAtTs) or 0
		if not beforeTs or ts < beforeTs then
			table.insert(result, 1, m)
			if #result >= limit then
				break
			end
		end
	end
	send(player, C.MESSAGES_RESULT, {
		conversationId = chatId,
		messages = result,
		beforeTs = beforeTs,
		hasOlder = #history.messages > #result,
		conversation = Shared.copySummary(meta, username),
	})
end

local function appendMessage(player, args)
	local username = Shared.playerUsername(player)
	local chatId = args and args.conversationId
	local meta = Persistence.loadMeta(chatId)
	if not meta or not Shared.isMember(meta, username) or meta.disbanded then
		sendError(player, "Conversation not found.", chatId)
		return
	end

	local settings = Shared.getSettings()
	local ok, body, attachments = Shared.validateMessageBody(args and args.body or "", settings, args and args.attachments)
	if not ok then
		sendError(player, body, chatId)
		return
	end

	local now = Shared.now()
	local nowNum = tonumber(now) or os.time()
	if settings.rateLimitSeconds > 0 then
		local last = tonumber(Server.lastMessageAtByUser[username]) or 0
		if nowNum - last < settings.rateLimitSeconds then
			sendError(player, "You are sending messages too quickly.", chatId)
			return
		end
	end

	local mutedUntil = tonumber(meta.mutedUntilByUser and meta.mutedUntilByUser[username]) or 0
	if mutedUntil > nowNum then
		sendError(player, "You are muted in this group until " .. Shared.formatUnixLocal(mutedUntil) .. ".", chatId)
		return
	elseif mutedUntil > 0 then
		meta.mutedUntilByUser[username] = nil
	end

	local msg = {
		id = Shared.generateId("msg"),
		conversationId = chatId,
		fromUsername = username,
		fromDisplayName = Shared.playerDisplayName(player),
		body = body,
		attachments = attachments,
		createdAtTs = now,
		kind = "message",
	}
	local history = Persistence.loadHistory(chatId)
	history.messages[#history.messages + 1] = msg
	if settings.maxStoredMessagesPerChat > 0 then
		while #history.messages > settings.maxStoredMessagesPerChat do
			table.remove(history.messages, 1)
		end
	end
	Persistence.saveHistory(chatId, history)

	meta.lastMessage = {
		id = msg.id,
		fromUsername = msg.fromUsername,
		body = msg.body ~= "" and msg.body:sub(1, 140) or (Shared.firstLocationAttachment(msg.attachments) and "[Location]" or ""),
		createdAtTs = msg.createdAtTs,
	}
	meta.updatedAtTs = now
	meta.unreadCountByUser = meta.unreadCountByUser or {}
	for i = 1, #(meta.members or {}) do
		local member = meta.members[i]
		Persistence.upsertUserChat(member, chatId)
		if member ~= username then
			meta.unreadCountByUser[member] = (tonumber(meta.unreadCountByUser[member]) or 0) + 1
		end
	end
	meta.unreadCountByUser[username] = 0
	Persistence.saveMeta(meta)
	Server.lastMessageAtByUser[username] = now

	notifyMembers(meta, C.NEW_MESSAGE, { message = msg }, nil)
end

local function markRead(player, args)
	local username = Shared.playerUsername(player)
	local chatId = args and args.conversationId
	local meta = Persistence.loadMeta(chatId)
	if not meta or not Shared.isMember(meta, username) then
		return
	end
	meta.unreadCountByUser = meta.unreadCountByUser or {}
	meta.unreadCountByUser[username] = 0
	Persistence.saveMeta(meta)
	local idx = Persistence.loadUserIndex(username)
	idx.readTsByChat[chatId] = Shared.now()
	Persistence.saveUserIndex(username, idx)
	pushConversationList(player)
end

local function requireGroupAdmin(player, meta)
	local username = Shared.playerUsername(player)
	if not Shared.isGroup(meta) then
		return false, username, "This is not a group."
	end
	if not Shared.isMember(meta, username) then
		return false, username, "You are not a member."
	end
	if not Shared.isAdmin(meta, username) then
		return false, username, "You are not a group admin."
	end
	return true, username
end

local function groupAction(player, args)
	local settings = Shared.getSettings()
	local chatId = args and args.conversationId
	local meta = Persistence.loadMeta(chatId)
	if not meta then
		sendError(player, "Group not found.", chatId)
		return
	end
	local ok, actor, err = requireGroupAdmin(player, meta)
	if not ok then
		sendError(player, err, chatId)
		return
	end

	local action = args.action
	local target = Shared.normalizeUsername(args.username)
	local changed = false

	if action == A.ADD_MEMBER then
		if not target or not userExists(target) then
			sendError(player, "Unknown member.", chatId)
			return
		end
		if #meta.members >= settings.maxGroupMembers then
			sendError(player, "Group is full.", chatId)
			return
		end
		changed = Shared.addUnique(meta.members, target)
		Persistence.upsertUserChat(target, chatId)
	elseif action == A.REMOVE_MEMBER then
		if target == meta.ownerUsername then
			sendError(player, "The group owner cannot be removed.", chatId)
			return
		end
		changed = Shared.removeValue(meta.members, target)
		Shared.removeValue(meta.admins, target)
		Persistence.removeUserChat(target, chatId)
	elseif action == A.PROMOTE then
		if not Shared.isMember(meta, target) then
			sendError(player, "Target is not a member.", chatId)
			return
		end
		changed = Shared.addUnique(meta.admins, target)
	elseif action == A.DEMOTE then
		if target == meta.ownerUsername then
			sendError(player, "The owner cannot be demoted.", chatId)
			return
		end
		if not settings.adminsCanDemoteAdmins and actor ~= meta.ownerUsername then
			sendError(player, "Only the owner can demote admins.", chatId)
			return
		end
		changed = Shared.removeValue(meta.admins, target)
	elseif action == A.MUTE then
		if not Shared.isMember(meta, target) then
			sendError(player, "Target is not a member.", chatId)
			return
		end
		local minutes = math.max(1, math.min(10080, math.floor(tonumber(args.minutes) or 10)))
		meta.mutedUntilByUser[target] = Shared.timestampString((tonumber(Shared.now()) or os.time()) + (minutes * 60))
		changed = true
	elseif action == A.UNMUTE then
		meta.mutedUntilByUser[target] = nil
		changed = true
	elseif action == A.RENAME then
		if not settings.adminsCanRenameGroups and actor ~= meta.ownerUsername then
			sendError(player, "Only the owner can rename this group.", chatId)
			return
		end
		local title = Shared.trim(args.title or "")
		if title == "" then
			sendError(player, "Group name is required.", chatId)
			return
		end
		meta.title = title:sub(1, 64)
		changed = true
	elseif action == A.DISBAND then
		if not settings.adminsCanDisbandGroups and actor ~= meta.ownerUsername then
			sendError(player, "Only the owner can disband this group.", chatId)
			return
		end
		meta.disbanded = true
		for i = 1, #(meta.members or {}) do
			Persistence.removeUserChat(meta.members[i], chatId)
		end
		changed = true
	else
		sendError(player, "Unknown group action.", chatId)
		return
	end

	if changed then
		saveMeta(meta)
		pushListsToOnlineMembers(meta)
	end
end

function Server.processCommand(command, player, args)
	if not player then
		return
	end
	local username = Shared.playerUsername(player)
	rememberUser(username)
	if command == C.BOOTSTRAP or command == C.CONVERSATION_LIST then
		send(player, C.BOOTSTRAP_RESULT, {
			username = username,
			displayName = Shared.playerDisplayName(player),
			settings = Shared.getSettings(),
			knownUsers = knownUsersList(),
		})
		pushConversationList(player)
	elseif command == C.FETCH_MESSAGES then
		fetchMessages(player, args or {})
	elseif command == C.SEND_MESSAGE then
		appendMessage(player, args or {})
	elseif command == C.CREATE_DM then
		local meta, err = createOrGetDm(player, args and args.username)
		if not meta then
			sendError(player, err)
			return
		end
		pushListsToOnlineMembers(meta)
	elseif command == C.CREATE_GROUP then
		local meta, err = createGroup(player, args or {})
		if not meta then
			sendError(player, err)
			return
		end
		pushListsToOnlineMembers(meta)
	elseif command == C.LEAVE_GROUP then
		local meta = Persistence.loadMeta(args and args.conversationId)
		if meta and meta.kind == Shared.KIND.GROUP and Shared.isMember(meta, username) then
			if username == meta.ownerUsername and #meta.members > 1 then
				sendError(player, "The owner cannot leave while other members remain.", meta.id)
				return
			end
			Shared.removeValue(meta.members, username)
			Shared.removeValue(meta.admins, username)
			Persistence.removeUserChat(username, meta.id)
			saveMeta(meta)
			pushConversationList(player)
			pushListsToOnlineMembers(meta)
		end
	elseif command == C.HIDE_CONVERSATION then
		Persistence.setHidden(username, args and args.conversationId, true)
		pushConversationList(player)
	elseif command == C.UNHIDE_CONVERSATION then
		Persistence.setHidden(username, args and args.conversationId, false)
		pushConversationList(player)
	elseif command == C.MARK_READ then
		markRead(player, args or {})
	elseif command == C.GROUP_ACTION then
		groupAction(player, args or {})
	end
end

function Server.onClientCommand(module, command, player, args)
	if module == MODULE then
		Server.processCommand(command, player, args or {})
	end
end

function Server.init()
	if Server.initialized then
		return
	end
	Server.initialized = true
	Server.knownUsersSorted = Persistence.loadKnownUsers()
	Server.knownUsers = {}
	for i = 1, #Server.knownUsersSorted do
		local u = Server.knownUsersSorted[i]
		Server.knownUsers[u] = true
	end
	Persistence.saveSettings(Shared.getSettings())
	Events.OnClientCommand.Add(Server.onClientCommand)
	Logger:info("Server initialized.")
end

if isServer and isServer() then
	Events.OnServerStarted.Add(Server.init)
end

return Server
