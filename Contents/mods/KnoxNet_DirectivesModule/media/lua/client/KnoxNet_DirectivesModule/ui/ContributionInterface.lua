local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local DirectiveManager = require("KnoxNet_DirectivesModule/core/DirectiveManager")

---@class ContributionInterface : ISPanel
local ContributionInterface = ISPanel:derive("ContributionInterface")

ContributionInterface.instance = nil

ContributionInterface.COLORS = {
	BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
	BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 },
	TEXT = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
	TEXT_DIM = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
	HIGHLIGHT = { r = 0.3, g = 0.7, b = 0.3, a = 1.0 },
	BUTTON = {
		NORMAL = { r = 0.2, g = 0.2, b = 0.6, a = 0.7 },
		HOVER = { r = 0.3, g = 0.3, b = 0.8, a = 0.8 },
		CONFIRM = { r = 0.2, g = 0.6, b = 0.2, a = 0.7 },
		CANCEL = { r = 0.6, g = 0.2, b = 0.2, a = 0.7 },
		DISABLED = { r = 0.4, g = 0.4, b = 0.4, a = 0.5 },
	},
}

-- Create a new contribution interface
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param directive table The directive to contribute to
---@param playerObj IsoPlayer Player object
---@return ContributionInterface
function ContributionInterface:new(x, y, width, height, directive, playerObj)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.directive = directive
	o.playerObj = playerObj
	o.playerNum = playerObj:getPlayerNum()
	o.playerInventory = playerObj:getInventory()
	o.playerId = playerObj:getUsername() or tostring(playerObj:getPlayerNum())

	o.backgroundColor = ContributionInterface.COLORS.BACKGROUND
	o.borderColor = ContributionInterface.COLORS.BORDER

	o.selectedItem = -1
	o.itemsToContribute = {}
	o.totalContribution = 0
	o.validItems = {}

	o.moveWithMouse = true
	o.anchorLeft = true
	o.anchorRight = true
	o.anchorTop = true
	o.anchorBottom = true

	return o
end

function ContributionInterface:initialise()
	ISPanel.initialise(self)

	self:createUI()
	self:findValidItems()
end

function ContributionInterface:createUI()
	local padding = 10
	local buttonHeight = 25
	local buttonWidth = 100

	self.titleLabel = ISLabel:new(
		padding,
		padding,
		buttonHeight,
		"Contribute to: " .. self.directive.title,
		1,
		1,
		1,
		1,
		UIFont.Medium,
		true
	)
	self:addChild(self.titleLabel)

	self.inventoryList = ISScrollingListBox:new(
		padding,
		padding + 65,
		self.width / 2 - padding - 5,
		self.height - padding * 3 - buttonHeight - 65
	)
	self.inventoryList:initialise()
	self.inventoryList:setAnchorRight(false)
	self.inventoryList:setAnchorBottom(true)
	self.inventoryList.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
	self.inventoryList.drawBorder = true
	self.inventoryList:setOnMouseDownFunction(self, self.onInventoryItemSelected)
	self:addChild(self.inventoryList)

	self.selectedList = ISScrollingListBox:new(
		self.width / 2 + 5,
		padding + 65,
		self.width / 2 - padding - 5,
		self.height - padding * 3 - buttonHeight - 65
	)
	self.selectedList:initialise()
	self.selectedList:setAnchorRight(true)
	self.selectedList:setAnchorBottom(true)
	self.selectedList.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
	self.selectedList.drawBorder = true
	self.selectedList:setOnMouseDownFunction(self, self.onSelectedItemClicked)
	self:addChild(self.selectedList)

	self.inventoryLabel =
		ISLabel:new(padding, padding + 65 - 15, 15, "Available Items:", 1, 1, 1, 1, UIFont.Small, false)
	self:addChild(self.inventoryLabel)

	self.selectedLabel = ISLabel:new(
		self.width / 2 + 5,
		padding + 65 - 15,
		15,
		"Selected to Contribute:",
		1,
		1,
		1,
		1,
		UIFont.Small,
		false
	)
	self:addChild(self.selectedLabel)

	self.addButton = ISButton:new(
		self.width / 2 - buttonWidth / 2,
		self.height - buttonHeight - padding,
		buttonWidth,
		buttonHeight,
		"Add",
		self,
		ContributionInterface.onAddClick
	)
	self.addButton:initialise()
	self.addButton.backgroundColor = ContributionInterface.COLORS.BUTTON.NORMAL
	self.addButton.borderColor = ContributionInterface.COLORS.BORDER
	self.addButton.enable = false
	self:addChild(self.addButton)

	self.contributeButton = ISButton:new(
		self.width - buttonWidth - padding,
		self.height - buttonHeight - padding,
		buttonWidth,
		buttonHeight,
		"Contribute",
		self,
		ContributionInterface.onContributeClick
	)
	self.contributeButton:initialise()
	self.contributeButton.backgroundColor = ContributionInterface.COLORS.BUTTON.CONFIRM
	self.contributeButton.borderColor = ContributionInterface.COLORS.BORDER
	self.contributeButton.enable = false
	self:addChild(self.contributeButton)

	self.cancelButton = ISButton:new(
		padding,
		self.height - buttonHeight - padding,
		buttonWidth,
		buttonHeight,
		"Cancel",
		self,
		ContributionInterface.onCancelClick
	)
	self.cancelButton:initialise()
	self.cancelButton.backgroundColor = ContributionInterface.COLORS.BUTTON.CANCEL
	self.cancelButton.borderColor = ContributionInterface.COLORS.BORDER
	self:addChild(self.cancelButton)
end

function ContributionInterface:findValidItems()
	self.validItems = {}
	self.inventoryList:clear()

	local items = self.playerInventory:getItems()
	for i = 0, items:size() - 1 do
		local item = items:get(i)

		if self:isItemValidForDirective(item) then
			table.insert(self.validItems, item)

			local condition = item.getCondition and item:getCondition() or nil
			local conditionStr = ""

			if condition then
				conditionStr = tostring(condition)
			end

			local uses = nil
			if instanceof(item, "DrainableComboItem") then
				uses = item:getDrainableUsesInt()
				conditionStr = string.format(" (%d uses)", uses)
			end

			local displayName = item:getDisplayName() .. conditionStr
			self.inventoryList:addItem(displayName, item)
		end
	end

	self.addButton.enable = false
	self.contributeButton.enable = #self.itemsToContribute > 0
end

---Check if an item is valid for this directive
---@param item InventoryItem The item to check
---@return boolean valid Whether the item is valid
function ContributionInterface:isItemValidForDirective(item)
	if not item or not self.directive or not self.directive.acceptedItems then
		return false
	end

	local itemType = item:getFullType()
	local condition = item.getCondition and item:getCondition() or nil
	local uses = nil

	if instanceof(item, "DrainableComboItem") then
		uses = item:getDrainableUsesInt()
	end

	for _, acceptedItem in ipairs(self.directive.acceptedItems) do
		if acceptedItem.item == itemType then
			if acceptedItem.minCondition and condition and condition < acceptedItem.minCondition then
				return false
			end

			if acceptedItem.minUses and uses and uses < acceptedItem.minUses then
				return false
			end

			return true
		end
	end

	return false
end

function ContributionInterface:onInventoryItemSelected(item)
	if item then
		self.selectedItem = item.index
		self.addButton.enable = true
	else
		self.selectedItem = -1
		self.addButton.enable = false
	end
end

function ContributionInterface:onSelectedItemClicked(item)
	if item then
		self:removeItemFromContribution(item.index)
	end
end

function ContributionInterface:onAddClick()
	if self.selectedItem < 0 or not self.inventoryList.items[self.selectedItem + 1] then
		return
	end

	local item = self.inventoryList.items[self.selectedItem + 1].item
	if not item then
		return
	end

	table.insert(self.itemsToContribute, item)

	self.inventoryList:removeItem(self.selectedItem)
	self.selectedItem = -1

	local conditionStr = ""
	if item.getCondition and item:getCondition() > 0 then
		conditionStr = string.format(" (%.0f%%)", (item:getCondition() / item:getConditionMax()) * 100)
	end

	local uses = nil
	if instanceof(item, "DrainableComboItem") then
		uses = item:getDrainableUsesInt()
		conditionStr = string.format(" (%d uses)", uses)
	end

	local displayName = item:getDisplayName() .. conditionStr
	self.selectedList:addItem(displayName, item)

	self.addButton.enable = false
	self.contributeButton.enable = #self.itemsToContribute > 0

	TerminalSounds.playUISound("sfx_knoxnet_key_2")
end

function ContributionInterface:removeItemFromContribution(index)
	if not self.selectedList.items[index + 1] then
		return
	end

	local item = self.selectedList.items[index + 1].item
	if not item then
		return
	end

	for i, contribItem in ipairs(self.itemsToContribute) do
		if contribItem == item then
			table.remove(self.itemsToContribute, i)
			break
		end
	end

	self.selectedList:removeItem(index)

	if self:isItemValidForDirective(item) then
		local conditionStr = ""
		if item.getCondition and item:getCondition() > 0 then
			conditionStr = string.format(" (%.0f%%)", (item:getCondition() / item:getConditionMax()) * 100)
		end

		local uses = nil
		if instanceof(item, "DrainableComboItem") then
			uses = item:getDrainableUsesInt()
			conditionStr = string.format(" (%d uses)", uses)
		end

		local displayName = item:getDisplayName() .. conditionStr
		self.inventoryList:addItem(displayName, item)
	end

	self.contributeButton.enable = #self.itemsToContribute > 0

	TerminalSounds.playUISound("sfx_knoxnet_key_3")
end

function ContributionInterface:onContributeClick()
	if #self.itemsToContribute == 0 then
		return
	end

	local contributedItems = {}
	local totalContributed = 0

	for i, item in ipairs(self.itemsToContribute) do
		if DirectiveManager.contributeToDirective(self.directive.id, self.playerId, item) then
			table.insert(contributedItems, item)
			totalContributed = totalContributed + 1
			self.playerInventory:RemoveItem(item)
		end
	end

	if totalContributed > 0 then
		TerminalSounds.playUISound("sfx_knoxnet_key_4")

		local modal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			string.format(
				"Successfully contributed %d item%s to the directive.",
				totalContributed,
				totalContributed == 1 and "" or "s"
			),
			true,
			nil,
			nil
		)
		modal:setX(self:getX() + (self.width / 2) - 175)
		modal:setY(self:getY() + (self.height / 2) - 75)
		modal:initialise()
		modal:addToUIManager()

		self:close()
	else
		local modal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			"No items could be contributed. Please try again.",
			true,
			nil,
			nil
		)
		modal:setX(self:getX() + (self.width / 2) - 175)
		modal:setY(self:getY() + (self.height / 2) - 75)
		modal:initialise()
		modal:addToUIManager()
	end
end

function ContributionInterface:onCancelClick()
	TerminalSounds.playUISound("sfx_knoxnet_key_3")
	self:close()
end

function ContributionInterface:close()
	self:setVisible(false)
	self:removeFromUIManager()
	ContributionInterface.instance = nil
end

function ContributionInterface:render()
	ISPanel.render(self)
	self:drawTextCentered(
		"Items needed for: " .. self.directive.title,
		self.width / 2,
		3 + 10,
		1,
		1,
		1,
		1,
		UIFont.Small
	)

	if #self.validItems == 0 then
		self:drawTextCentered(
			"No valid items in inventory",
			self.width / 4,
			self.height / 2,
			0.7,
			0.7,
			0.7,
			1,
			UIFont.Small
		)
	end

	if #self.itemsToContribute == 0 then
		self:drawTextCentered(
			"Select items to contribute",
			self.width * 3 / 4,
			self.height / 2,
			0.7,
			0.7,
			0.7,
			1,
			UIFont.Small
		)
	end
end

function ContributionInterface:drawTextCentered(text, centerX, y, r, g, b, a, font)
	local width = getTextManager():MeasureStringX(font, text)
	self:drawText(text, centerX - width / 2, y, r, g, b, a, font)
end

---Handle keyboard input
---@param key number The key code
---@return boolean handled True if the key was handled
function ContributionInterface:onKeyPress(key)
	if key == Keyboard.KEY_ESCAPE then
		self:onCancelClick()
		return true
	elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
		if self.addButton.enable then
			self:onAddClick()
			return true
		elseif self.contributeButton.enable then
			self:onContributeClick()
			return true
		end
	end

	return false
end

-- Open the contribution interface
---@param directive table The directive to contribute to
---@param playerObj IsoPlayer Player object
function ContributionInterface.openPanel(directive, playerObj)
	if ContributionInterface.instance then
		ContributionInterface.instance:close()
	end

	local width = 700
	local height = 500
	local x = getCore():getScreenWidth() / 2 - width / 2
	local y = getCore():getScreenHeight() / 2 - height / 2

	local panel = ContributionInterface:new(x, y, width, height, directive, playerObj)
	panel:initialise()
	panel:addToUIManager()
	panel:bringToTop()

	ContributionInterface.instance = panel
	return panel
end

return ContributionInterface
