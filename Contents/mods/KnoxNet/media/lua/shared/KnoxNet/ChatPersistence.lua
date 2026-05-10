local JSON = require("ElyonLib/FileUtils/JSON")
local TextUtils = require("ElyonLib/TextUtils/TextUtils")
local Shared = require("KnoxNet/Shared")

local Persistence = {}

local function path(name)
	return Shared.DATA_DIR .. "/" .. name
end

local function chatPath(kind, chatId)
	return path("chats/" .. Shared.safeFileId(chatId) .. "/" .. kind .. ".json")
end

local function oldChatPath(kind, chatId)
	return path("chat_" .. kind .. "_" .. Shared.safeFileId(chatId) .. ".json")
end

local function userPath(username)
	return path("users/" .. TextUtils.sanitizeFileSegment(username, 80) .. ".json")
end

local function oldUserPath(username)
	return path("user_" .. TextUtils.sanitizeFileSegment(username, 80) .. ".json")
end

local function readJsonQuiet(filePath)
	local reader = getFileReader(filePath, false)
	if not reader then
		return nil
	end

	local lines = {}
	local line = reader:readLine()
	while line do
		lines[#lines + 1] = line
		line = reader:readLine()
	end
	reader:close()

	local content = table.concat(lines, "\n")
	if content == "" then
		return nil
	end
	return JSON.parse(content)
end

local function writeJsonQuiet(filePath, data)
	local content = JSON.stringify(data)
	local writer = getFileWriter(filePath, true, false)
	if not writer then
		return false
	end
	writer:write(content)
	writer:close()
	return true
end

local function normalizeLastMessage(lastMessage)
	if type(lastMessage) ~= "table" then
		return lastMessage
	end
	lastMessage.createdAtTs = Shared.normalizeTimestamp(lastMessage.createdAtTs)
	return lastMessage
end

local function normalizeMessage(message)
	if type(message) ~= "table" then
		return message
	end
	message.createdAtTs = Shared.normalizeTimestamp(message.createdAtTs)
	return message
end

local function normalizeMeta(meta)
	if type(meta) ~= "table" then
		return meta
	end
	meta.createdAtTs = Shared.normalizeTimestamp(meta.createdAtTs) or Shared.now()
	meta.updatedAtTs = Shared.normalizeTimestamp(meta.updatedAtTs) or meta.createdAtTs
	meta.lastMessage = normalizeLastMessage(meta.lastMessage)
	meta.mutedUntilByUser = type(meta.mutedUntilByUser) == "table" and meta.mutedUntilByUser or {}
	for username, ts in pairs(meta.mutedUntilByUser) do
		meta.mutedUntilByUser[username] = Shared.normalizeTimestamp(ts)
	end
	return meta
end

local function normalizeHistory(history)
	if type(history) ~= "table" then
		return history
	end
	history.messages = type(history.messages) == "table" and history.messages or {}
	for i = 1, #history.messages do
		history.messages[i] = normalizeMessage(history.messages[i])
	end
	return history
end

local function normalizeUserIndex(index, username)
	if type(index) ~= "table" then
		index = {}
	end
	index.username = username
	index.entries = type(index.entries) == "table" and index.entries or {}
	for i = 1, #index.entries do
		local entry = index.entries[i]
		if type(entry) == "table" then
			entry.joinedAtTs = Shared.normalizeTimestamp(entry.joinedAtTs) or Shared.now()
		end
	end
	index.readTsByChat = type(index.readTsByChat) == "table" and index.readTsByChat or {}
	for chatId, ts in pairs(index.readTsByChat) do
		index.readTsByChat[chatId] = Shared.normalizeTimestamp(ts)
	end
	index.hiddenConversationIds = type(index.hiddenConversationIds) == "table" and index.hiddenConversationIds or {}
	index.knownUsers = type(index.knownUsers) == "table" and index.knownUsers or {}
	return index
end

function Persistence.loadSettings()
	local data = readJsonQuiet(path("settings/settings.json")) or readJsonQuiet(path("settings.json"))
	if type(data) == "table" then
		local merged = Shared.getSettings()
		local keys = Shared.SETTINGS_KEYS
		for i = 1, #keys do
			local k = keys[i]
			local v = data[k]
			if v ~= nil then
				merged[k] = v
			end
		end
		return merged
	end
	return Shared.getSettings()
end

local function sortUserList(list)
	table.sort(list, function(a, b)
		return tostring(a):lower() < tostring(b):lower()
	end)
end

function Persistence.loadKnownUsers()
	local data = readJsonQuiet(path("users/known_users.json")) or readJsonQuiet(path("known_users.json"))
	if type(data) ~= "table" or type(data.users) ~= "table" then
		return {}
	end
	local u = data.users
	if u[1] ~= nil then
		local list = {}
		for i = 1, #u do
			list[i] = u[i]
		end
		sortUserList(list)
		return list
	end
	local list = {}
	for username in pairs(u) do
		list[#list + 1] = username
	end
	sortUserList(list)
	return list
end

function Persistence.saveKnownUsers(sortedUserList)
	local data = { users = sortedUserList or {} }
	return writeJsonQuiet(path("users/known_users.json"), data) or writeJsonQuiet(path("known_users.json"), data)
end

function Persistence.saveSettings(settings)
	local data = settings or Shared.getSettings()
	return writeJsonQuiet(path("settings/settings.json"), data) or writeJsonQuiet(path("settings.json"), data)
end

function Persistence.loadMeta(chatId)
	local data = readJsonQuiet(chatPath("meta", chatId)) or readJsonQuiet(oldChatPath("meta", chatId))
	if type(data) ~= "table" then
		return nil
	end
	data.members = type(data.members) == "table" and data.members or {}
	data.admins = type(data.admins) == "table" and data.admins or {}
	data.mutedUntilByUser = type(data.mutedUntilByUser) == "table" and data.mutedUntilByUser or {}
	data.unreadCountByUser = type(data.unreadCountByUser) == "table" and data.unreadCountByUser or {}
	return normalizeMeta(data)
end

function Persistence.saveMeta(meta)
	if type(meta) ~= "table" or type(meta.id) ~= "string" then
		return false
	end
	meta = normalizeMeta(meta)
	return writeJsonQuiet(chatPath("meta", meta.id), meta) or writeJsonQuiet(oldChatPath("meta", meta.id), meta)
end

function Persistence.loadHistory(chatId)
	local data = readJsonQuiet(chatPath("history", chatId)) or readJsonQuiet(oldChatPath("history", chatId))
	if type(data) ~= "table" then
		return { conversationId = chatId, messages = {} }
	end
	data.conversationId = data.conversationId or chatId
	return normalizeHistory(data)
end

function Persistence.saveHistory(chatId, history)
	history = history or { conversationId = chatId, messages = {} }
	history.conversationId = chatId
	history = normalizeHistory(history)
	return writeJsonQuiet(chatPath("history", chatId), history) or writeJsonQuiet(oldChatPath("history", chatId), history)
end

function Persistence.loadUserIndex(username)
	username = Shared.normalizeUsername(username) or "_unknown"
	local data = readJsonQuiet(userPath(username)) or readJsonQuiet(oldUserPath(username))
	return normalizeUserIndex(data, username)
end

function Persistence.saveUserIndex(username, index)
	index = normalizeUserIndex(index or Persistence.loadUserIndex(username), username)
	return writeJsonQuiet(userPath(username), index) or writeJsonQuiet(oldUserPath(username), index)
end

function Persistence.hasEntry(index, chatId)
	for i = 1, #(index.entries or {}) do
		if index.entries[i].id == chatId then
			return true
		end
	end
	return false
end

function Persistence.upsertUserChat(username, chatId)
	local index = Persistence.loadUserIndex(username)
	if not Persistence.hasEntry(index, chatId) then
		index.entries[#index.entries + 1] = { id = chatId, joinedAtTs = Shared.now() }
	end
	index.hiddenConversationIds[chatId] = nil
	Persistence.saveUserIndex(username, index)
end

function Persistence.removeUserChat(username, chatId)
	local index = Persistence.loadUserIndex(username)
	for i = #(index.entries or {}), 1, -1 do
		if index.entries[i].id == chatId then
			table.remove(index.entries, i)
		end
	end
	Persistence.saveUserIndex(username, index)
end

function Persistence.setHidden(username, chatId, hidden)
	local index = Persistence.loadUserIndex(username)
	index.hiddenConversationIds[chatId] = hidden and true or nil
	Persistence.saveUserIndex(username, index)
end

return Persistence
