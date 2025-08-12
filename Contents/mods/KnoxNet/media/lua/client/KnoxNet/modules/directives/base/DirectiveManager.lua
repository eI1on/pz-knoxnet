local Logger = require("KnoxNet/Logger")

---@class DirectiveManager
local DirectiveManager = {}

DirectiveManager.directiveTypes = {}

DirectiveManager.activeDirectives = {}
DirectiveManager.completedDirectives = {}

-- Register a new directive type
---@param typeName string The name of the directive type
---@param directiveClass table The class representing this directive type
function DirectiveManager.registerDirectiveType(typeName, directiveClass)
	if not typeName or not directiveClass then
		return
	end

	DirectiveManager.directiveTypes[typeName] = directiveClass
end

-- Create a new directive of the specified type
---@param typeName string The directive type name
---@param data table Initial data for the directive
---@return BaseDirective|nil directive The created directive or nil if type not found
function DirectiveManager.createDirective(typeName, data)
	local DirectiveClass = DirectiveManager.directiveTypes[typeName]
	if not DirectiveClass then
		Logger:warning("Attempted to create unknown directive type: " .. tostring(typeName))
		return nil
	end

	data = data or {}
	local directive = DirectiveClass:new(data)

	return directive
end

-- Find a directive by its ID
---@param directiveId string The directive ID to find
---@return BaseDirective|nil directive The found directive or nil
function DirectiveManager.findDirectiveById(directiveId)
	if not directiveId then
		return nil
	end

	for _, directive in ipairs(DirectiveManager.activeDirectives) do
		if directive.id == directiveId then
			return directive
		end
	end

	for _, directive in ipairs(DirectiveManager.completedDirectives) do
		if directive.id == directiveId then
			return directive
		end
	end

	return nil
end

function DirectiveManager.updateAllDirectives()
	for _, directive in ipairs(DirectiveManager.activeDirectives) do
		directive:updateProgress()
	end

	local i = 1
	while i <= #DirectiveManager.activeDirectives do
		local directive = DirectiveManager.activeDirectives[i]
		if directive.completed then
			table.remove(DirectiveManager.activeDirectives, i)
			table.insert(DirectiveManager.completedDirectives, directive)
		else
			i = i + 1
		end
	end

	DirectiveManager.saveDirectives()
end

function DirectiveManager.saveDirectives()
	local serializedActive = {}
	for _, directive in ipairs(DirectiveManager.activeDirectives) do
		table.insert(serializedActive, {
			type = directive.directiveType,
			data = directive:serialize(),
		})
	end

	local serializedCompleted = {}
	for _, directive in ipairs(DirectiveManager.completedDirectives) do
		table.insert(serializedCompleted, {
			type = directive.directiveType,
			data = directive:serialize(),
		})
	end

	ModData.add("KnoxNet_ActiveDirectives", serializedActive)
	ModData.add("KnoxNet_CompletedDirectives", serializedCompleted)
end

function DirectiveManager.loadDirectives()
	DirectiveManager.activeDirectives = {}
	DirectiveManager.completedDirectives = {}

	local serializedActive = ModData.get("KnoxNet_ActiveDirectives") or {}
	for _, serialized in ipairs(serializedActive) do
		local DirectiveClass = DirectiveManager.directiveTypes[serialized.type]
		if DirectiveClass then
			local directive = DirectiveClass:new({})
			directive:deserialize(serialized.data)
			table.insert(DirectiveManager.activeDirectives, directive)
		end
	end

	local serializedCompleted = ModData.get("KnoxNet_CompletedDirectives") or {}
	for _, serialized in ipairs(serializedCompleted) do
		local DirectiveClass = DirectiveManager.directiveTypes[serialized.type]
		if DirectiveClass then
			local directive = DirectiveClass:new({})
			directive:deserialize(serialized.data)
			table.insert(DirectiveManager.completedDirectives, directive)
		end
	end
end

-- Delete a directive by its ID
---@param directiveId string The ID of the directive to delete
---@return boolean success Whether deletion was successful
function DirectiveManager.deleteDirective(directiveId)
	if not directiveId then
		return false
	end

	for i, directive in ipairs(DirectiveManager.activeDirectives) do
		if directive.id == directiveId then
			table.remove(DirectiveManager.activeDirectives, i)
			DirectiveManager.saveDirectives()
			return true
		end
	end

	for i, directive in ipairs(DirectiveManager.completedDirectives) do
		if directive.id == directiveId then
			table.remove(DirectiveManager.completedDirectives, i)
			DirectiveManager.saveDirectives()
			return true
		end
	end

	return false
end

-- Get all directives that are available for a specific terminal
---@param terminalId string|nil The terminal ID or nil for global directives
---@return BaseDirective[] directives List of applicable directives
function DirectiveManager.getDirectivesForTerminal(terminalId)
	local results = {}

	for _, directive in ipairs(DirectiveManager.activeDirectives) do
		if not directive.terminalSpecific or directive.terminalId == terminalId then
			table.insert(results, directive)
		end
	end

	return results
end

-- Get all completed directives
---@param limit number|nil Maximum number of directives to return
---@param offset number|nil Offset to start from
---@return BaseDirective[] directives List of completed directives
function DirectiveManager.getCompletedDirectives(limit, offset)
	limit = limit or #DirectiveManager.completedDirectives
	offset = offset or 0

	local results = {}
	local count = 0
	local added = 0

	for _, directive in ipairs(DirectiveManager.completedDirectives) do
		count = count + 1
		if count > offset and added < limit then
			table.insert(results, directive)
			added = added + 1
		end
	end

	return results
end

-- Process a player contribution to a directive
---@param directiveId string The directive ID
---@param playerId string The player ID
---@param item InventoryItem The item being contributed
---@return boolean success Whether contribution was successful
function DirectiveManager.contributeToDirective(directiveId, playerId, item)
	local directive = DirectiveManager.findDirectiveById(directiveId)
	if not directive or not directive.isActive then
		return false
	end

	local success = directive:addContribution(playerId, item)

	if success then
		DirectiveManager.saveDirectives()
	end

	return success
end

-- Award rewards for a directive to a player
---@param directiveId string The directive ID
---@param playerId string The player ID
---@param playerObj IsoPlayer|nil The player object (if available)
---@return boolean success Whether rewards were given
function DirectiveManager.awardRewards(directiveId, playerId, playerObj)
	local directive = DirectiveManager.findDirectiveById(directiveId)
	if not directive then
		return false
	end

	local success = directive:awardReward(playerId, playerObj)

	if success then
		DirectiveManager.saveDirectives()
	end

	return success
end

return DirectiveManager
