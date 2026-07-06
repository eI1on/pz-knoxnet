local JSON = require("ElyonLib/FileUtils/JSON")
local TextUtils = require("ElyonLib/TextUtils/TextUtils")
local Shared = require("KnoxNet/Shared")

local ObjectMessages = {}
local BODY_PREVIEW_LIMIT = 120

local function safeId(value, maxLen)
	return TextUtils.sanitizeFileSegment(tostring(value or "_"), maxLen or 96)
end

local function normalizeNamespace(namespace)
	namespace = safeId(namespace or "default", 64)
	if namespace == "" then return "default" end
	return namespace
end

local function path(name)
	return Shared.DATA_DIR .. "/objects/" .. normalizeNamespace(name)
end

local function readJson(filePath)
	local reader = getFileReader(filePath, false)
	if not reader then return nil end
	local lines = {}
	local line = reader:readLine()
	while line do
		lines[#lines + 1] = line
		line = reader:readLine()
	end
	reader:close()
	local content = table.concat(lines, "\n")
	if content == "" then return nil end
	return JSON.parse(content)
end

local function writeJson(filePath, data)
	local writer = getFileWriter(filePath, true, false)
	if not writer then return false end
	writer:write(JSON.stringify(data or {}))
	writer:close()
	return true
end

local function conversationId(a, b)
	a = tostring(a or "")
	b = tostring(b or "")
	if a:lower() > b:lower() then
		a, b = b, a
	end
	return "obj_" .. safeId(a, 64) .. "_" .. safeId(b, 64)
end

local function conversationPath(namespace, id)
	return path(namespace) .. "/c_" .. safeId(id, 128) .. ".json"
end

local function indexPath(namespace, objectId)
	return path(namespace) .. "/i_" .. safeId(objectId, 96) .. ".json"
end

local function loadConversation(namespace, id)
	local data = readJson(conversationPath(namespace, id))
	if type(data) ~= "table" then
		return { id = id, messages = {} }
	end
	data.id = data.id or id
	data.messages = type(data.messages) == "table" and data.messages or {}
	return data
end

local function saveConversation(namespace, conversation)
	return writeJson(conversationPath(namespace, conversation.id), conversation)
end

local function loadIndex(namespace, objectId)
	local data = readJson(indexPath(namespace, objectId))
	if type(data) ~= "table" then
		return { objectId = tostring(objectId or ""), conversations = {} }
	end
	data.objectId = tostring(data.objectId or objectId or "")
	data.conversations = type(data.conversations) == "table" and data.conversations or {}
	return data
end

local function saveIndex(namespace, objectId, index)
	index = index or { objectId = tostring(objectId or ""), conversations = {} }
	index.objectId = tostring(objectId or "")
	index.conversations = type(index.conversations) == "table" and index.conversations or {}
	return writeJson(indexPath(namespace, objectId), index)
end

local function upsertIndex(namespace, ownerId, peerId, summary)
	local index = loadIndex(namespace, ownerId)
	local rows = index.conversations
	local found = false
	for i = 1, #rows do
		if tostring(rows[i].peerId or "") == tostring(peerId or "") then
			rows[i] = summary
			found = true
			break
		end
	end
	if not found then rows[#rows + 1] = summary end
	table.sort(rows, function(a, b)
		return (tonumber(a.updatedAtTs) or 0) > (tonumber(b.updatedAtTs) or 0)
	end)
	saveIndex(namespace, ownerId, index)
end

local function bodyPreview(body)
	body = tostring(body or "")
	if #body <= BODY_PREVIEW_LIMIT then return body end
	return string.sub(body, 1, BODY_PREVIEW_LIMIT)
end

local function summaryFor(id, peerId, message, count)
	return {
		id = id,
		peerId = tostring(peerId or ""),
		count = tonumber(count) or 0,
		updatedAtTs = tostring(message.createdAtTs or ""),
		lastFromId = tostring(message.fromId or ""),
		lastToId = tostring(message.toId or ""),
		lastBody = bodyPreview(message.body),
		lastGameDate = tostring(message.gameDate or ""),
	}
end

local function removeIndexEntry(namespace, ownerId, peerId)
	local index = loadIndex(namespace, ownerId)
	for i = #index.conversations, 1, -1 do
		if tostring(index.conversations[i].peerId or "") == tostring(peerId or "") then
			table.remove(index.conversations, i)
		end
	end
	saveIndex(namespace, ownerId, index)
end

function ObjectMessages.conversationId(a, b)
	return conversationId(a, b)
end

function ObjectMessages.append(namespace, fromId, toId, body, meta, maxMessages)
	fromId = tostring(fromId or "")
	toId = tostring(toId or "")
	body = tostring(body or "")
	if fromId == "" or toId == "" or body == "" then return nil end
	local id = conversationId(fromId, toId)
	local conversation = loadConversation(namespace, id)
	local now = Shared.now()
	local message = {
		id = Shared.generateId("objmsg"),
		fromId = fromId,
		toId = toId,
		body = body,
		createdAtTs = now,
		gameDate = type(meta) == "table" and tostring(meta.gameDate or "") or "",
	}
	conversation.messages[#conversation.messages + 1] = message
	local cap = math.max(0, math.floor(tonumber(maxMessages) or 0))
	if cap > 0 then
		while #conversation.messages > cap do table.remove(conversation.messages, 1) end
	end
	saveConversation(namespace, conversation)
	upsertIndex(namespace, fromId, toId, summaryFor(id, toId, message, #conversation.messages))
	upsertIndex(namespace, toId, fromId, summaryFor(id, fromId, message, #conversation.messages))
	return message, conversation
end

function ObjectMessages.messages(namespace, ownerId, peerId, limit)
	local id = conversationId(ownerId, peerId)
	local conversation = loadConversation(namespace, id)
	local cap = math.max(0, math.floor(tonumber(limit) or 0))
	if cap <= 0 or #conversation.messages <= cap then
		return conversation.messages
	end
	local out = {}
	local first = #conversation.messages - cap + 1
	for i = first, #conversation.messages do
		out[#out + 1] = conversation.messages[i]
	end
	return out
end

function ObjectMessages.conversations(namespace, ownerId)
	local index = loadIndex(namespace, ownerId)
	return index.conversations
end

function ObjectMessages.deleteConversation(namespace, ownerId, peerId)
	local id = conversationId(ownerId, peerId)
	local conversation = loadConversation(namespace, id)
	conversation.messages = {}
	saveConversation(namespace, conversation)
	removeIndexEntry(namespace, ownerId, peerId)
	removeIndexEntry(namespace, peerId, ownerId)
end

return ObjectMessages
