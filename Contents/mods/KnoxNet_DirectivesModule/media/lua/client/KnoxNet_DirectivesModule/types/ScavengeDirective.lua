local DirectiveConstants = require("KnoxNet_DirectivesModule/core/DirectiveConstants")
local BaseDirective = require("KnoxNet_DirectivesModule/core/BaseDirective")

---@class ScavengeDirective : BaseDirective
---@field goal number Total number of items to collect
---@field acceptedItems table<number, {item:string, minCondition:number|nil, minUses:number|nil, count:number, collected:number}>
local ScavengeDirective = {}
setmetatable(ScavengeDirective, { __index = BaseDirective })
ScavengeDirective.__index = ScavengeDirective

---Creates a new scavenge directive instance.
---@param data table Initial directive data.
---@return ScavengeDirective directive The created directive instance.
function ScavengeDirective:new(data)
	data.id = data.id or self:generateId("scv_")
	data.directiveType = DirectiveConstants.DIRECTIVE_TYPES.SCAVENGE

	local directive = BaseDirective.new(self, data) ---@class ScavengeDirective

	directive.goal = data.goal or 0
	directive.acceptedItems = data.acceptedItems or {}

	if directive.goal == 0 and #directive.acceptedItems > 0 then
		for _, item in ipairs(directive.acceptedItems) do
			directive.goal = directive.goal + (item.count or 1)
		end
	end

	directive:updateProgress()
	return directive
end

---Override to return the specialized form fields for Scavenge directives
---@return table fields Form fields specifically for Scavenge directives
function ScavengeDirective:getFormFields()
	local fields = BaseDirective.getFormFields(self)

	table.insert(fields, {
		label = "ACCEPTED ITEMS",
		type = "section",
		key = "acceptedItemsHeader",
	})

	table.insert(fields, {
		label = "Total Item Goal:",
		type = "number",
		value = self.goal,
		key = "goal",
	})

	for i, item in ipairs(self.acceptedItems) do
		table.insert(fields, {
			label = "Item " .. i .. " Type:",
			type = "text",
			value = item.item,
			key = "acceptedItem_" .. i .. "_type",
		})

		table.insert(fields, {
			label = "Item " .. i .. " Quantity:",
			type = "number",
			value = item.count,
			key = "acceptedItem_" .. i .. "_count",
		})

		table.insert(fields, {
			label = "Item " .. i .. " Min Condition:",
			type = "number",
			value = item.minCondition or 0,
			key = "acceptedItem_" .. i .. "_minCondition",
		})

		table.insert(fields, {
			label = "Item " .. i .. " Min Uses:",
			type = "number",
			value = item.minUses or 0,
			key = "acceptedItem_" .. i .. "_minUses",
		})
	end

	table.insert(fields, {
		label = "Add Accepted Item",
		type = "button",
		value = "Add Item",
		key = "addAcceptedItem",
	})

	return fields
end

---Override to handle Scavenge-specific form field values
---@param fields table Array of form fields with values
function ScavengeDirective:applyFormFields(fields)
	BaseDirective.applyFormFields(self, fields)

	for _, field in ipairs(fields) do
		if field.key == "goal" then
			self.goal = tonumber(field.value) or 0
		elseif string.find(field.key, "acceptedItem_") then
			local parts = string.split(field.key, "_")
			local index = tonumber(parts[2]) or 1
			local property = parts[3]

			if not self.acceptedItems[index] then
				self.acceptedItems[index] = {
					item = "",
					count = 0,
					collected = 0,
				}
			end

			if property == "type" then
				self.acceptedItems[index].item = field.value
			elseif property == "count" then
				self.acceptedItems[index].count = tonumber(field.value) or 1
			elseif property == "minCondition" then
				self.acceptedItems[index].minCondition = tonumber(field.value) or 0
			elseif property == "minUses" then
				self.acceptedItems[index].minUses = tonumber(field.value) or 0
			end
		elseif field.key == "addAcceptedItem" and field.clicked then
			self:addAcceptedItem("", 0, 0, 0)
		end
	end
	if self.goal == 0 then
		for _, item in ipairs(self.acceptedItems) do
			self.goal = self.goal + (item.count or 1)
		end
	end

	self:updateProgress()
end

-- Add an accepted item to this directive
---@param itemFullType string Full item type (e.g., "Base.Axe")
---@param minCondition number|nil Minimum condition (0.0-1.0)
---@param minUses number|nil Minimum uses
---@param count number|nil Required count of this item
---@return number index Index of the added item
function ScavengeDirective:addAcceptedItem(itemFullType, minCondition, minUses, count)
	if not itemFullType then
		return -1
	end

	local index = #self.acceptedItems + 1
	self.acceptedItems[index] = {
		item = itemFullType,
		minCondition = minCondition,
		minUses = minUses,
		count = count or 1,
		collected = 0,
	}

	return index
end

-- Remove an accepted item
---@param index number Index of the item to remove
---@return boolean success Whether removal was successful
function ScavengeDirective:removeAcceptedItem(index)
	if not self.acceptedItems[index] then
		return false
	end

	table.remove(self.acceptedItems, index)
	return true
end

-- Check if an item is acceptable for this directive
---@param itemType string Item type to check
---@param condition number|nil Item condition (0.0-1.0)
---@param uses number|nil Item uses
---@return boolean acceptable Whether item is acceptable
function ScavengeDirective:isItemAcceptable(itemType, condition, uses)
	for _, acceptedItem in ipairs(self.acceptedItems) do
		if acceptedItem.item == itemType then
			local conditionCheck = not acceptedItem.minCondition
				or (condition and condition >= acceptedItem.minCondition)
			local usesCheck = not acceptedItem.minUses or (uses and uses >= acceptedItem.minUses)

			if conditionCheck and usesCheck then
				return true
			end
		end
	end

	return false
end

---Override to calculate the total items needed for this directive
---@return number total Total goal for this directive
function ScavengeDirective:calculateTotalGoal()
	if self.goal > 0 then
		return self.goal
	end

	local total = 0
	for _, item in ipairs(self.acceptedItems) do
		total = total + item.count
	end
	return total
end

---@param playerId string Player identifier
---@param itemType string Item type contributed
---@param condition number|nil Item condition
---@param uses number|nil Item uses
---@return boolean success Whether contribution was successful
function ScavengeDirective:addContributionByDetails(playerId, itemType, condition, uses)
	if not self:isItemAcceptable(itemType, condition, uses) then
		return false
	end

	if not self.contributions[playerId] then
		self.contributions[playerId] = {
			total = 0,
			items = {},
		}
	end

	local playerContrib = self.contributions[playerId]

	local itemKey = itemType
	if condition then
		itemKey = itemKey .. "|cond=" .. tostring(condition)
	end
	if uses then
		itemKey = itemKey .. "|uses=" .. tostring(uses)
	end

	if not playerContrib.items[itemKey] then
		playerContrib.items[itemKey] = {
			type = itemType,
			condition = condition,
			uses = uses,
			count = 0,
		}
	end

	playerContrib.items[itemKey].count = playerContrib.items[itemKey].count + 1
	playerContrib.total = playerContrib.total + 1

	for _, acceptedItem in ipairs(self.acceptedItems) do
		if acceptedItem.item == itemType then
			acceptedItem.collected = acceptedItem.collected + 1
			break
		end
	end

	self:updateProgress()
	return true
end

---Handle contribution from inventory item
---@param playerId string The ID of the contributing player.
---@param item InventoryItem|DrainableComboItem The item being contributed.
---@return boolean success True if the item was accepted and counted.
function ScavengeDirective:addContribution(playerId, item)
	local itemType = item:getFullType()
	local condition = item.getCondition and item:getCondition() or nil
	local uses = nil

	if instanceof(item, "DrainableComboItem") then
		uses = item:getDrainableUsesInt()
	end

	return self:addContributionByDetails(playerId, itemType, condition, uses)
end

function ScavengeDirective:updateProgress()
	local totalNeeded = self:calculateTotalGoal()
	if totalNeeded <= 0 then
		self.progress = 0
		return
	end

	local totalCollected = 0
	for _, item in ipairs(self.acceptedItems) do
		totalCollected = totalCollected + item.collected
	end

	self.progress = math.min(1.0, totalCollected / totalNeeded)

	if self.progress >= 1.0 and not self.completed then
		self:markComplete()
	end
end

---Serializes the directive into a table for saving to disk or syncing over the network.
---@return table data The serialized directive data.
function ScavengeDirective:serialize()
	local data = BaseDirective.serialize(self)
	data.directiveType = "Scavenge"
	data.goal = self.goal
	data.acceptedItems = self.acceptedItems
	return data
end

---Loads a directive's state from a previously serialized data table.
---@param data table The directive data to load.
function ScavengeDirective:deserialize(data)
	BaseDirective.deserialize(self, data)
	self.goal = data.goal or 0
	self.acceptedItems = data.acceptedItems or {}
	self:updateProgress()
end

local DirectiveManager = require("KnoxNet_DirectivesModule/core/DirectiveManager")
DirectiveManager.registerDirectiveType("Scavenge", ScavengeDirective)

return ScavengeDirective
