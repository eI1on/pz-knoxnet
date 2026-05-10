require "ISUI/ISUIElement"

local Shared = require("KnoxNet/Shared")
local NetUtils = require("ElyonLib/Net/NetUtils")
local MenuDock = require("ElyonLib/UI/MenuDock/MenuDock")
local HudNotify = require("ElyonLib/UI/Notifications/HudNotify")
local PlayerUtils = require("ElyonLib/PlayerUtils/PlayerUtils")

local Client = {}

Client.username = nil
Client.displayName = nil
Client.settings = Shared.getSettings()
Client.conversations = {}
Client.messagesByChat = {}
Client.uiRef = nil
Client.initialized = false
Client.totalUnread = 0
Client.knownUsers = {}

local MODULE = Shared.MODULE
local C = Shared.COMMANDS

local function execute(command, args)
	return NetUtils.executeProcessCommand(MODULE, "KnoxNet/Server", command, args or {})
end

local function recomputeUnread()
	local total = 0
	for i = 1, #Client.conversations do
		total = total + (tonumber(Client.conversations[i].unreadCount) or 0)
	end
	Client.totalUnread = total
	MenuDock.setEntryBadge("knoxnet", { text = tostring(total), maxBeforePlus = 99 })
end

local function findConversationIndex(id)
	for i = 1, #Client.conversations do
		if Client.conversations[i].id == id then
			return i
		end
	end
	return nil
end

local function upsertConversation(summary)
	if type(summary) ~= "table" or type(summary.id) ~= "string" then
		return
	end
	local ix = findConversationIndex(summary.id)
	if ix then
		Client.conversations[ix] = summary
	else
		Client.conversations[#Client.conversations + 1] = summary
	end
	table.sort(Client.conversations, function(a, b)
		return (tonumber(a.updatedAtTs) or 0) > (tonumber(b.updatedAtTs) or 0)
	end)
	recomputeUnread()
end

local function notifyUI(method, ...)
	if Client.uiRef and Client.uiRef[method] then
		Client.uiRef[method](Client.uiRef, ...)
	end
end

function Client.bootstrap()
	execute(C.BOOTSTRAP, {})
end

function Client.requestConversations()
	execute(C.CONVERSATION_LIST, {})
end

function Client.fetchMessages(conversationId, beforeTs, limit)
	execute(C.FETCH_MESSAGES, { conversationId = conversationId, beforeTs = beforeTs, limit = limit })
end

function Client.sendMessage(conversationId, body, attachments)
	execute(C.SEND_MESSAGE, { conversationId = conversationId, body = body, attachments = attachments })
end

function Client.createDm(username)
	execute(C.CREATE_DM, { username = username })
end

function Client.createGroup(title, members)
	execute(C.CREATE_GROUP, { title = title, members = members })
end

function Client.leaveGroup(conversationId)
	execute(C.LEAVE_GROUP, { conversationId = conversationId })
end

function Client.markRead(conversationId)
	execute(C.MARK_READ, { conversationId = conversationId })
end

function Client.groupAction(conversationId, action, patch)
	patch = patch or {}
	patch.conversationId = conversationId
	patch.action = action
	execute(C.GROUP_ACTION, patch)
end

function Client.getPlayerOptions()
	local seen = {}
	local result = {}
	local function add(username)
		username = Shared.normalizeUsername(username)
		if username and not seen[username] then
			seen[username] = true
			result[#result + 1] = username
		end
	end

	local players = PlayerUtils.getOnlinePlayers()
	for i = 1, #players do
		add(Shared.playerUsername(players[i]))
	end
	for i = 1, #Client.knownUsers do
		add(Client.knownUsers[i])
	end
	table.sort(result, function(a, b)
		return tostring(a):lower() < tostring(b):lower()
	end)
	return result
end

local function applyConversationList(args)
	if type(args.settings) == "table" then
		Client.settings = args.settings
	end
	Client.conversations = type(args.conversations) == "table" and args.conversations or Client.conversations
	recomputeUnread()
	notifyUI("onConversationsChanged")
end

local function applyMessages(args)
	if type(args) ~= "table" or type(args.conversationId) ~= "string" then
		return
	end
	local chatId = args.conversationId
	local existing = Client.messagesByChat[chatId] or {}
	local incoming = type(args.messages) == "table" and args.messages or {}
	if args.beforeTs then
		local merged = {}
		for i = 1, #incoming do
			merged[#merged + 1] = incoming[i]
		end
		for i = 1, #existing do
			merged[#merged + 1] = existing[i]
		end
		Client.messagesByChat[chatId] = merged
	else
		Client.messagesByChat[chatId] = incoming
	end
	if args.conversation then
		upsertConversation(args.conversation)
	end
	notifyUI("onMessagesChanged", chatId, args.beforeTs ~= nil)
end

local function applyNewMessage(args)
	if type(args) ~= "table" or type(args.message) ~= "table" then
		return
	end
	local msg = args.message
	local chatId = msg.conversationId
	if args.conversation then
		upsertConversation(args.conversation)
	end
	Client.messagesByChat[chatId] = Client.messagesByChat[chatId] or {}
	Client.messagesByChat[chatId][#Client.messagesByChat[chatId] + 1] = msg
	local isMine = msg.fromUsername == Client.username
	local selected = Client.uiRef and Client.uiRef.selectedConversationId == chatId and Client.uiRef:getIsVisible()
	if selected then
		Client.markRead(chatId)
	elseif not isMine and Client.settings.notifyLiveMessages ~= false then
		local title = args.conversation and args.conversation.title or "KnoxNet"
		local body = tostring(msg.body or "")
		if body == "" and Shared.firstLocationAttachment(msg.attachments) then
			body = "[Location]"
		end
		HudNotify.push({
			title = title,
			body = tostring(msg.fromDisplayName or msg.fromUsername or "") .. ": " .. body,
			type = "message",
			ttlSeconds = 5,
		})
	end
	notifyUI("onMessagesChanged", chatId, false)
end

function Client.receiveServerCommand(module, command, args)
	if module ~= MODULE then
		return
	end
	args = args or {}
	if command == C.BOOTSTRAP_RESULT then
		Client.username = args.username
		Client.displayName = args.displayName or args.username
		Client.knownUsers = type(args.knownUsers) == "table" and args.knownUsers or Client.knownUsers
		if type(args.settings) == "table" then
			Client.settings = args.settings
		end
	elseif command == C.CONVERSATION_LIST_RESULT then
		applyConversationList(args)
	elseif command == C.MESSAGES_RESULT then
		applyMessages(args)
	elseif command == C.NEW_MESSAGE then
		applyNewMessage(args)
	elseif command == C.ERROR then
		HudNotify.push({ title = "KnoxNet", body = tostring(args.message or "Action failed."), type = "error", ttlSeconds = 5 })
		notifyUI("onError", args.message)
	end
end

local function init()
	if Client.initialized then
		return
	end
	Client.initialized = true
	Client.bootstrap()
end

local function onFirstTick()
	init()
	Events.OnTick.Remove(onFirstTick)
end

if not isServer() then
	Events.OnServerCommand.Add(Client.receiveServerCommand)
	Events.OnTick.Add(onFirstTick)
end

return Client
