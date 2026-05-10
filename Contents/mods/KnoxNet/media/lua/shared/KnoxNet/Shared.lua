local TextUtils = require("ElyonLib/TextUtils/TextUtils")
local AccessLevelUtils = require("ElyonLib/PlayerUtils/AccessLevelUtils")
local DateTimeUtility = require("ElyonLib/DateTime/DateTimeUtility")

local Shared = {}

Shared.VERSION = 1
Shared.MOD_ID = "KnoxNet"
Shared.MODULE = "KnoxNet"
Shared.DATA_DIR = "KnoxNet"

Shared.KIND = {
	DM = "dm",
	GROUP = "group",
}

Shared.COMMANDS = {
	BOOTSTRAP = "Bootstrap",
	BOOTSTRAP_RESULT = "BootstrapResult",
	CONVERSATION_LIST = "ConversationList",
	CONVERSATION_LIST_RESULT = "ConversationListResult",
	FETCH_MESSAGES = "FetchMessages",
	MESSAGES_RESULT = "MessagesResult",
	SEND_MESSAGE = "SendMessage",
	NEW_MESSAGE = "NewMessage",
	CREATE_DM = "CreateDm",
	CREATE_GROUP = "CreateGroup",
	LEAVE_GROUP = "LeaveGroup",
	HIDE_CONVERSATION = "HideConversation",
	UNHIDE_CONVERSATION = "UnhideConversation",
	MARK_READ = "MarkRead",
	GROUP_ACTION = "GroupAction",
	ERROR = "Error",
}

Shared.GROUP_ACTION = {
	ADD_MEMBER = "addMember",
	REMOVE_MEMBER = "removeMember",
	PROMOTE = "promote",
	DEMOTE = "demote",
	MUTE = "mute",
	UNMUTE = "unmute",
	RENAME = "rename",
	DISBAND = "disband",
}

Shared.ATTACHMENT_KIND = {
	LOCATION = "location",
}

Shared.DEFAULT_SETTINGS = {
	maxMessageLength = 500,
	historyPageSize = 50,
	historyPageMax = 100,
	maxStoredMessagesPerChat = 0,
	maxGroupMembers = 24,
	maxGroupsPerPlayer = 12,
	groupCreateAccess = "all",
	adminsCanDemoteAdmins = false,
	adminsCanRenameGroups = true,
	adminsCanDisbandGroups = true,
	notifyLiveMessages = true,
	rateLimitSeconds = 1,
	retainMessagesIndefinitely = true,
}

Shared.SETTINGS_KEYS = {
	"maxMessageLength",
	"historyPageSize",
	"historyPageMax",
	"maxStoredMessagesPerChat",
	"maxGroupMembers",
	"maxGroupsPerPlayer",
	"groupCreateAccess",
	"adminsCanDemoteAdmins",
	"adminsCanRenameGroups",
	"adminsCanDisbandGroups",
	"notifyLiveMessages",
	"rateLimitSeconds",
	"retainMessagesIndefinitely",
}

local function sandboxValue(key)
	if not SandboxVars or not SandboxVars.KnoxNet then
		return nil
	end
	return SandboxVars.KnoxNet[key]
end

function Shared.getSettings()
	local s = {}
	local keys = Shared.SETTINGS_KEYS
	local defaults = Shared.DEFAULT_SETTINGS
	for i = 1, #keys do
		local k = keys[i]
		s[k] = defaults[k]
	end

	local numericKeys = {
		"maxMessageLength",
		"historyPageSize",
		"historyPageMax",
		"maxStoredMessagesPerChat",
		"maxGroupMembers",
		"maxGroupsPerPlayer",
		"rateLimitSeconds",
	}
	for i = 1, #numericKeys do
		local key = numericKeys[i]
		local v = tonumber(sandboxValue(key))
		if v ~= nil then
			s[key] = v
		end
	end

	local groupAccess = sandboxValue("groupCreateAccess")
	if groupAccess == "admin" or groupAccess == "none" or groupAccess == "all" then
		s.groupCreateAccess = groupAccess
	end

	local boolKeys = {
		"adminsCanDemoteAdmins",
		"adminsCanRenameGroups",
		"adminsCanDisbandGroups",
		"notifyLiveMessages",
		"retainMessagesIndefinitely",
	}
	for i = 1, #boolKeys do
		local key = boolKeys[i]
		local v = sandboxValue(key)
		if v ~= nil then
			s[key] = v == true
		end
	end

	s.maxMessageLength = math.max(1, math.min(4000, math.floor(tonumber(s.maxMessageLength) or 500)))
	s.historyPageSize = math.max(1, math.min(200, math.floor(tonumber(s.historyPageSize) or 50)))
	s.historyPageMax = math.max(s.historyPageSize, math.min(500, math.floor(tonumber(s.historyPageMax) or 100)))
	s.maxStoredMessagesPerChat = math.max(0, math.floor(tonumber(s.maxStoredMessagesPerChat) or 0))
	s.maxGroupMembers = math.max(2, math.min(100, math.floor(tonumber(s.maxGroupMembers) or 24)))
	s.maxGroupsPerPlayer = math.max(0, math.min(100, math.floor(tonumber(s.maxGroupsPerPlayer) or 12)))
	s.rateLimitSeconds = math.max(0, math.floor(tonumber(s.rateLimitSeconds) or 1))
	if s.retainMessagesIndefinitely then
		s.maxStoredMessagesPerChat = 0
	end

	return s
end

function Shared.trim(value)
	return TextUtils.trim(tostring(value or ""))
end

function Shared.normalizeUsername(username)
	username = Shared.trim(username)
	if username == "" then
		return nil
	end
	return username
end

function Shared.playerUsername(player)
	if player then
		local u = Shared.normalizeUsername(player:getUsername())
		if u then
			return u
		end
		u = Shared.normalizeUsername(player:getDisplayName())
		if u then
			return u
		end
	end
	if getPlayer then
		local p = getPlayer()
		if p and p ~= player then
			return Shared.playerUsername(p)
		end
	end
	return "Player"
end

function Shared.playerDisplayName(player)
	if player then
		local n = Shared.trim(player:getDisplayName())
		if n ~= "" then
			return n
		end
	end
	return Shared.playerUsername(player)
end

function Shared.timestampString(value)
	local n = tonumber(value) or os.time()
	return string.format("%.0f", n)
end

function Shared.normalizeTimestamp(value)
	if value == nil or value == "" then
		return nil
	end
	return Shared.timestampString(value)
end

function Shared.now()
	return Shared.timestampString(os.time())
end

function Shared.formatUnixLocal(ts)
	ts = tonumber(ts)
	if not ts then
		return ""
	end
	local utcDate = os.date("!*t", ts)
	if not utcDate then
		return ""
	end
	local localDate = DateTimeUtility.toLocalTime(utcDate)
	if not localDate then
		return ""
	end
	return string.format(
		"%04d-%02d-%02d %02d:%02d",
		localDate.year or 1970,
		localDate.month or 1,
		localDate.day or 1,
		localDate.hour or 0,
		localDate.min or 0
	)
end

function Shared.generateId(prefix)
	prefix = prefix or "id"
	local rand = ZombRand and ZombRand(100000, 999999)
	return prefix .. "_" .. Shared.timestampString(os.time()) .. "_" .. tostring(rand)
end

function Shared.dmIdFor(a, b)
	a = Shared.normalizeUsername(a) or ""
	b = Shared.normalizeUsername(b) or ""
	if a:lower() > b:lower() then
		a, b = b, a
	end
	return "dm_" .. TextUtils.sanitizeFileSegment(a, 48) .. "_" .. TextUtils.sanitizeFileSegment(b, 48)
end

function Shared.safeFileId(chatId)
	return TextUtils.sanitizeFileSegment(chatId, 96)
end

function Shared.contains(list, value)
	if type(list) ~= "table" then
		return false
	end
	for i = 1, #list do
		if list[i] == value then
			return true
		end
	end
	return false
end

function Shared.addUnique(list, value)
	if not value then
		return false
	end
	if Shared.contains(list, value) then
		return false
	end
	list[#list + 1] = value
	table.sort(list, function(a, b)
		return tostring(a):lower() < tostring(b):lower()
	end)
	return true
end

function Shared.removeValue(list, value)
	if type(list) ~= "table" then
		return false
	end
	for i = #list, 1, -1 do
		if list[i] == value then
			table.remove(list, i)
			return true
		end
	end
	return false
end

function Shared.parseCsvUsers(text)
	local users = {}
	local seen = {}
	text = tostring(text or "")
	for part in string.gmatch(text .. ",", "([^,]*),") do
		local u = Shared.normalizeUsername(part)
		if u and not seen[u] then
			seen[u] = true
			users[#users + 1] = u
		end
	end
	return users
end

function Shared.normalizeAttachments(attachments)
	if type(attachments) ~= "table" then
		return {}
	end
	local out = {}
	for i = 1, #attachments do
		local attachment = attachments[i]
		if type(attachment) == "table" then
			if attachment.type == Shared.ATTACHMENT_KIND.LOCATION then
				local x = math.floor(tonumber(attachment.x) or 0)
				local y = math.floor(tonumber(attachment.y) or 0)
				local z = math.floor(tonumber(attachment.z) or 0)
				out[#out + 1] = {
					type = Shared.ATTACHMENT_KIND.LOCATION,
					x = x,
					y = y,
					z = z,
					label = Shared.trim(attachment.label or "Shared location"):sub(1, 48),
				}
			end
		end
	end
	return out
end

function Shared.firstLocationAttachment(attachments)
	if type(attachments) ~= "table" then
		return nil
	end
	for i = 1, #attachments do
		if type(attachments[i]) == "table" and attachments[i].type == Shared.ATTACHMENT_KIND.LOCATION then
			return attachments[i]
		end
	end
	return nil
end

function Shared.validateMessageBody(body, settings, attachments)
	settings = settings or Shared.getSettings()
	body = tostring(body or ""):gsub("\r", "")
	body = body:gsub("^%s+", ""):gsub("%s+$", "")
	attachments = Shared.normalizeAttachments(attachments)
	if body == "" and #attachments == 0 then
		return false, "Message cannot be empty."
	end
	if #body > settings.maxMessageLength then
		return false, "Message is too long."
	end
	return true, body, attachments
end

function Shared.canCreateGroup(player, settings)
	settings = settings or Shared.getSettings()
	if settings.groupCreateAccess == "none" then
		return false
	end
	if settings.groupCreateAccess == "admin" then
		return AccessLevelUtils.hasAdminAccess(player)
	end
	return true
end

function Shared.isGroup(meta)
	return meta and meta.kind == Shared.KIND.GROUP
end

function Shared.isMember(meta, username)
	return meta and Shared.contains(meta.members, username)
end

function Shared.isAdmin(meta, username)
	return meta and (meta.ownerUsername == username or Shared.contains(meta.admins, username))
end

function Shared.copySummary(meta, username)
	if not meta then
		return nil
	end
	local lastMessage = meta.lastMessage
	if type(lastMessage) == "table" then
		lastMessage = {
			id = lastMessage.id,
			fromUsername = lastMessage.fromUsername,
			body = lastMessage.body,
			createdAtTs = Shared.normalizeTimestamp(lastMessage.createdAtTs),
		}
	end
	return {
		id = meta.id,
		kind = meta.kind,
		title = meta.title,
		members = meta.members or {},
		admins = meta.admins or {},
		ownerUsername = meta.ownerUsername,
		createdAtTs = Shared.normalizeTimestamp(meta.createdAtTs),
		updatedAtTs = Shared.normalizeTimestamp(meta.updatedAtTs),
		lastMessage = lastMessage,
		unreadCount = tonumber(meta.unreadCountByUser and meta.unreadCountByUser[username]) or 0,
		disbanded = meta.disbanded == true,
		mutedUntil = Shared.normalizeTimestamp(meta.mutedUntilByUser and meta.mutedUntilByUser[username]),
	}
end

return Shared
