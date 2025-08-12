local DirectiveConstants = require("KnoxNet/modules/directives/base/DirectiveConstants")
local DirectiveManager = require("KnoxNet/modules/directives/base/DirectiveManager")
local TextWrapper = require("KnoxNet/modules/directives/ui/TextWrapper")

---@class DirectiveEditorPanel : ISPanel
DirectiveEditorPanel = ISPanel:derive("DirectiveEditorPanel")

DirectiveEditorPanel.UI = {
	BORDER_THICKNESS = 2,
	PANEL_PADDING = 10,
	FIELD_HEIGHT = 25,
	FIELD_PADDING = 7,
	SECTION_SPACING = 15,
	LABEL_WIDTH = 120,
	BUTTON_HEIGHT = 30,
	ITEM_LIST_HEIGHT = 200,
	PADDING = 10,
}

function DirectiveEditorPanel:createChildren()
	self.fontHgtSmall = getTextManager():getFontHeight(UIFont.Small)
	self.fontHgtMedium = getTextManager():getFontHeight(UIFont.Medium)

	self.minWidth = 600
	self.minHeight = 400

	self:calculateLayout()
	self:createLeftPanel()
	self:createRightPanel()
	self:loadDirectives()
end

function DirectiveEditorPanel:calculateLayout()
	local availableWidth = math.max(self.width, self.minWidth)
	local availableHeight = math.max(self.height, self.minHeight)

	self.leftPanelWidth = math.max(math.floor(availableWidth * 0.35), 200)
	self.rightPanelX = self.leftPanelWidth + 20
	self.rightPanelWidth = availableWidth - self.rightPanelX - 10

	self.headerHeight = self.fontHgtMedium + 8
	self.listY = self.headerHeight + self.fontHgtSmall + 30 + 10
	self.listHeight = availableHeight - self.listY - 60

	self.btnHeight = self.fontHgtSmall + 14
	self.btnY = availableHeight - self.btnHeight - 15
end

function DirectiveEditorPanel:createLeftPanel()
	local padX = self.UI.PANEL_PADDING
	local headerY = padX

	self.listHeader = ISLabel:new(
		padX,
		headerY,
		self.headerHeight,
		"AVAILABLE DIRECTIVES",
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(self.listHeader)

	local filterY = headerY + self.headerHeight + 5
	self.filterLabel = ISLabel:new(
		padX,
		filterY,
		self.fontHgtSmall,
		"Filter:",
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(self.filterLabel)

	local filterLabelWidth = getTextManager():MeasureStringX(UIFont.Small, "Filter:") + 5
	self.filterCombo = ISComboBox:new(
		padX + filterLabelWidth,
		filterY - 2,
		self.leftPanelWidth - filterLabelWidth - padX * 2,
		self.fontHgtSmall + 5
	)
	self.filterCombo:initialise()
	self.filterCombo:addOption("All Directives")
	self.filterCombo:addOption("Active Only")
	self.filterCombo:addOption("Completed Only")
	self.filterCombo.selected = 1
	self.filterCombo.target = self
	self.filterCombo.onChange = self.onFilterChange
	self:addChild(self.filterCombo)

	self.directivesList = ISScrollingListBox:new(padX, self.listY, self.leftPanelWidth - padX * 2, self.listHeight)
	self.directivesList:initialise()
	self.directivesList:setOnMouseDoubleClick(self, self.onDirectiveDoubleClick)
	self.directivesList.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.directivesList.borderColor = DirectiveConstants.COLORS.BORDER
	self.directivesList.drawBorder = true
	self:addChild(self.directivesList)

	local btnWidth = 80
	local spacing = 10
	local totalBtnWidth = (btnWidth * 3) + (spacing * 2)
	local startX = padX + math.max(0, (self.leftPanelWidth - padX * 2 - totalBtnWidth) / 2)

	self.addBtn =
		ISButton:new(startX, self.btnY, btnWidth, self.btnHeight, "New", self, self.showDirectiveTypeSelection)
	self.addBtn:initialise()
	self.addBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	self.addBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.addBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.addBtn)

	self.deleteBtn = ISButton:new(
		startX + btnWidth + spacing,
		self.btnY,
		btnWidth,
		self.btnHeight,
		"Delete",
		self,
		self.onDeleteDirective
	)
	self.deleteBtn:initialise()
	self.deleteBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.CLOSE
	self.deleteBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.deleteBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self.deleteBtn.enable = false
	self:addChild(self.deleteBtn)

	self.refreshBtn = ISButton:new(
		startX + (btnWidth * 2) + (spacing * 2),
		self.btnY,
		btnWidth,
		self.btnHeight,
		"Refresh",
		self,
		self.loadDirectives
	)
	self.refreshBtn:initialise()
	self.refreshBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	self.refreshBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.refreshBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.refreshBtn)
end

function DirectiveEditorPanel:createRightPanel()
	local placeholderText = "Select a directive to edit or click 'New' to create one"
	local wrapWidth = self.rightPanelWidth - 40

	local lines = TextWrapper.wrap(placeholderText, wrapWidth, UIFont.Medium)

	local lineHeight = getTextManager():getFontHeight(UIFont.Medium) + 5
	local totalHeight = #lines * lineHeight

	local startY = self.height / 2 - totalHeight / 2

	self.placeholderRightPanelLabels = {}
	for i, line in ipairs(lines) do
		local lineWidth = getTextManager():MeasureStringX(UIFont.Medium, line)
		local label = ISLabel:new(
			self.rightPanelX + (self.rightPanelWidth - lineWidth) / 2,
			startY + (i - 1) * lineHeight,
			lineHeight,
			line,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			UIFont.Medium,
			true
		)
		self:addChild(label)
		table.insert(self.placeholderRightPanelLabels, label)
	end
end

function DirectiveEditorPanel:onFilterChange()
	self:loadDirectives()
end

function DirectiveEditorPanel:showDirectiveTypeSelection()
	local modal = DirectiveTypeSelectionModal:new(
		getCore():getScreenWidth() / 2 - 200,
		getCore():getScreenHeight() / 2 - 150,
		400,
		300,
		self
	)
	modal:initialise()
	modal:addToUIManager()
end

-- Create directive editing form
---@param directiveType string The type of directive to create
function DirectiveEditorPanel:createDirectiveForm(directiveType)
	local formModal = DirectiveFormModal:new(
		getCore():getScreenWidth() / 2 - 300,
		getCore():getScreenHeight() / 2 - 350,
		600,
		700,
		directiveType,
		self,
		self.currentDirective
	)
	formModal:initialise()
	formModal:addToUIManager()
end

function DirectiveEditorPanel:loadDirectives()
	self.directivesList:clear()

	local activeDirectives = DirectiveManager.activeDirectives or {}
	local completedDirectives = DirectiveManager.completedDirectives or {}

	local filterMode = self.filterCombo.selected

	-- apply filter: All directives, Active only, or Completed only
	if filterMode == 1 or filterMode == 2 then
		for _, directive in ipairs(activeDirectives) do
			local item = {}
			item.text = directive.title
			item.directive = directive
			item.status = "ACTIVE"
			self.directivesList:addItem(item.text, item)
		end
	end

	if filterMode == 1 or filterMode == 3 then
		for _, directive in ipairs(completedDirectives) do
			local item = {}
			item.text = directive.title
			item.directive = directive
			item.status = "COMPLETED"
			self.directivesList:addItem(item.text, item)
		end
	end

	self.deleteBtn.enable = false
	if self.placeholderRightPanelLabels then
		for i = 1, #self.placeholderRightPanelLabels do
			local label = self.placeholderRightPanelLabels[i]
			label:setVisible(true)
		end
	end
end

-- Handle double-clicking a directive
---@param item table Selected list item
function DirectiveEditorPanel:onDirectiveDoubleClick(item)
	if not item or not item.directive then
		return
	end

	local directive = item.directive
	self.currentDirective = directive
	self.deleteBtn.enable = true

	if self.placeholderRightPanelLabels then
		for i = 1, #self.placeholderRightPanelLabels do
			local label = self.placeholderRightPanelLabels[i]
			label:setVisible(true)
		end
	end

	self:createDirectiveForm(directive.directiveType)
end

function DirectiveEditorPanel:onDeleteDirective()
	local selected = self.directivesList.selected
	if not selected then
		return
	end

	local modal = ISModalDialog:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		150,
		"Confirm Deletion",
		true,
		self,
		DirectiveEditorPanel.onConfirmDelete
	)
	modal:initialise()
	modal:addToUIManager()
	modal.directive = selected.item.directive
end

-- Handle deletion confirmation
---@param button ISButton The clicked button
---@param data table Data with directive to delete
function DirectiveEditorPanel:onConfirmDelete(button, data)
	if button.internal == "NO" then
		return
	end

	if not data or not data.directive then
		return
	end

	local success = DirectiveManager.deleteDirective(data.directive.id)

	if success then
		self:loadDirectives()

		self.currentDirective = nil
		self.deleteBtn.enable = false

		if self.placeholderRightPanelLabels then
			for i = 1, #self.placeholderRightPanelLabels do
				local label = self.placeholderRightPanelLabels[i]
				label:setVisible(true)
			end
		end

		local notificationModal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			"Success",
			false,
			nil,
			nil
		)
		notificationModal.text = "Directive successfully deleted."
		notificationModal:initialise()
		notificationModal:addToUIManager()
	end
end

-- Handle saving directive from form
---@param directive table The directive data to save
function DirectiveEditorPanel:onSaveDirective(directive)
	if not directive then
		return
	end

	local isNew = true
	if self.currentDirective and directive.id == self.currentDirective.id then
		isNew = false
	end

	directive:updateProgress()

	if isNew then
		if directive.isActive then
			table.insert(DirectiveManager.activeDirectives, directive)
		else
			directive.completed = true
			directive.completionDate = directive:getCurrentFormattedDate(directive.useRealDate)
			table.insert(DirectiveManager.completedDirectives, directive)
		end
	else
		if directive.isActive and directive.completed then
			DirectiveManager.deleteDirective(directive.id)
			directive.completed = false
			directive.completionDate = nil
			table.insert(DirectiveManager.activeDirectives, directive)
		elseif not directive.isActive and not directive.completed then
			DirectiveManager.deleteDirective(directive.id)
			directive.completed = true
			directive.completionDate = directive:getCurrentFormattedDate(directive.useRealDate)
			table.insert(DirectiveManager.completedDirectives, directive)
		end
	end

	DirectiveManager.saveDirectives()

	local notification = ISModalDialog:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		150,
		"Success",
		false,
		nil,
		nil
	)
	notification.text = "Directive saved successfully."
	notification:initialise()
	notification:addToUIManager()

	self:loadDirectives()
	self.currentDirective = nil
	self.deleteBtn.enable = false
	if self.placeholderRightPanelLabels then
		for i = 1, #self.placeholderRightPanelLabels do
			local label = self.placeholderRightPanelLabels[i]
			label:setVisible(true)
		end
	end
end

function DirectiveEditorPanel:render()
	ISPanel.render(self)

	self:drawRectStatic(self.leftPanelWidth + 9, 10, 2, self.height - 20, 0.8, 0.3, 0.3, 0.3)

	if #self.directivesList.items == 0 then
		local noItemsText = "No directives found. Click 'New' to create one."
		local textWidth = getTextManager():MeasureStringX(UIFont.Small, noItemsText)
		local listCenterX = self.UI.PANEL_PADDING + (self.leftPanelWidth - self.UI.PANEL_PADDING * 2) / 2
		local x = listCenterX - (textWidth / 2)
		self:drawText(
			noItemsText,
			x,
			self.height / 2,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			UIFont.Small
		)
	end
end

function DirectiveEditorPanel:prerender()
	ISPanel.prerender(self)

	local headerText = "COMMUNITY DIRECTIVES MANAGEMENT"
	local headerX = (self.width - getTextManager():MeasureStringX(UIFont.Medium, headerText)) / 2
	self:drawText(
		headerText,
		headerX,
		5,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)
end

-- Create a new DirectiveEditorPanel
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@return DirectiveEditorPanel
function DirectiveEditorPanel:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	o.borderColor = DirectiveConstants.COLORS.BORDER

	return o
end

---@class DirectiveTypeSelectionModal : ISPanel
DirectiveTypeSelectionModal = ISPanel:derive("DirectiveTypeSelectionModal")

function DirectiveTypeSelectionModal:createChildren()
	local titleY = 10
	local listY = titleY + getTextManager():getFontHeight(UIFont.Medium) + 15
	local listHeight = self.height - listY - 50

	self.typeList = ISScrollingListBox:new(15, listY, self.width - 30, listHeight)
	self.typeList:initialise()
	self.typeList:setOnMouseDoubleClick(self, self.onTypeSelect)
	self.typeList.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.typeList.borderColor = DirectiveConstants.COLORS.BORDER
	self.typeList.drawBorder = true
	self:addChild(self.typeList)

	self:addDirectiveTypes()

	local btnWidth = 100
	local btnHeight = 30
	local btnY = self.height - btnHeight - 10

	self.selectBtn = ISButton:new(
		self.width / 2 - btnWidth - 5,
		btnY,
		btnWidth,
		btnHeight,
		"Select",
		self,
		DirectiveTypeSelectionModal.onSelectType
	)
	self.selectBtn:initialise()
	self.selectBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	self.selectBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.selectBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.selectBtn)

	self.cancelBtn =
		ISButton:new(self.width / 2 + 5, btnY, btnWidth, btnHeight, "Cancel", self, DirectiveTypeSelectionModal.close)
	self.cancelBtn:initialise()
	self.cancelBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.CLOSE
	self.cancelBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.cancelBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.cancelBtn)
end

function DirectiveTypeSelectionModal:addDirectiveTypes()
	local types = {}

	if DirectiveManager.directiveTypes then
		for typeName, _ in pairs(DirectiveManager.directiveTypes) do
			table.insert(types, typeName)
		end
	end

	table.sort(types)

	for i = 1, #types do
		local typeName = types[i]
		local item = {}
		item.text = typeName
		self.typeList:addItem(typeName, item)
	end
end

function DirectiveTypeSelectionModal:onTypeSelect(item)
	if item and item.text then
		self.parentPanel:createDirectiveForm(item.text)
		self:close()
	end
end

function DirectiveTypeSelectionModal:onSelectType()
	local selected = self.typeList.items[self.typeList.selected].item
	if selected then
		self.parentPanel:createDirectiveForm(selected.text)
		self:close()
	end
end

function DirectiveTypeSelectionModal:close()
	self:setVisible(false)
	self:removeFromUIManager()
end

function DirectiveTypeSelectionModal:render()
	ISPanel.render(self)

	local titleText = "SELECT DIRECTIVE TYPE"
	local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, titleText)
	local titleY = 10
	self:drawText(
		titleText,
		(self.width - titleWidth) / 2,
		titleY,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)
end

function DirectiveTypeSelectionModal:new(x, y, width, height, parent)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	o.borderColor = DirectiveConstants.COLORS.BORDER
	o.parentPanel = parent
	o.moveWithMouse = true

	return o
end

---@class DirectiveFormModal : ISPanel
DirectiveFormModal = ISPanel:derive("DirectiveFormModal")

function DirectiveFormModal:initialise()
	ISPanel.initialise(self)
end

function DirectiveFormModal:createChildren()
	self.fontHgtSmall = getTextManager():getFontHeight(UIFont.Small)
	self.fontHgtMedium = getTextManager():getFontHeight(UIFont.Medium)

	local contentAreaY = self.fontHgtMedium + 20
	local contentAreaHeight = self.height - contentAreaY - 60

	self.scrollableContent = ISScrollablePanel:new(0, contentAreaY, self.width, contentAreaHeight)
	self.scrollableContent:initialise()
	self.scrollableContent.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	self:addChild(self.scrollableContent)

	self:createFormContent()

	self:createButtons()
end

function DirectiveFormModal:onMouseWheel(del)
	if self.scrollableContent:isMouseOver() then
		return self.scrollableContent:onMouseWheel(del)
	end
	return false
end

function DirectiveFormModal:createFormContent()
	local directive = self.directive
	if not directive then
		directive = DirectiveManager.createDirective(self.directiveType, {})
	end

	local fields = directive:getFormFields()

	self.formFields = {}
	local padX = DirectiveEditorPanel.UI.PANEL_PADDING
	local padY = DirectiveEditorPanel.UI.FIELD_PADDING
	local fieldHeight = DirectiveEditorPanel.UI.FIELD_HEIGHT
	local y = padY

	local formTitle = ISLabel:new(
		padX,
		y,
		fieldHeight,
		self.directive and "EDIT DIRECTIVE: " .. self.directive.title or "CREATE NEW DIRECTIVE",
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self.scrollableContent:addContent(formTitle)
	y = y + fieldHeight + padY

	local fieldGroups = {}
	local currentGroup = {}
	local currentSectionName = "DEFAULT"
	fieldGroups[currentSectionName] = currentGroup

	for i = 1, #fields do
		local field = fields[i]
		if field.type == "section" then
			if #currentGroup > 0 then
				currentSectionName = field.label
				currentGroup = {}
				fieldGroups[currentSectionName] = currentGroup
			end
		else
			table.insert(currentGroup, field)
		end
	end

	for sectionName, groupFields in pairs(fieldGroups) do
		if sectionName ~= "DEFAULT" then
			y = y + DirectiveEditorPanel.UI.SECTION_SPACING

			local sectionLabel = ISLabel:new(
				padX,
				y,
				fieldHeight,
				sectionName,
				DirectiveConstants.COLORS.TEXT.NORMAL.r,
				DirectiveConstants.COLORS.TEXT.NORMAL.g,
				DirectiveConstants.COLORS.TEXT.NORMAL.b,
				DirectiveConstants.COLORS.TEXT.NORMAL.a,
				UIFont.Small,
				true
			)
			self.scrollableContent:addContent(sectionLabel)
			y = y + fieldHeight + 5

			local separatorLine = ISPanel:new(padX, y, self.width - padX * 3 - 20, 1)
			separatorLine:initialise()
			separatorLine.backgroundColor = {
				a = 0.5,
				r = DirectiveConstants.COLORS.TEXT.DIM.r,
				g = DirectiveConstants.COLORS.TEXT.DIM.g,
				b = DirectiveConstants.COLORS.TEXT.DIM.b,
			}
			self.scrollableContent:addContent(separatorLine)
			y = y + 1 + padY
		end

		y = self:createSectionGroup(groupFields, padX, y, fieldHeight, padY)

		y = y + padY
	end

	self.scrollableContent:updateContentHeight()
end

function DirectiveFormModal:createSectionGroup(fields, padX, startY, fieldHeight, padY)
	local y = startY

	local maxLabelWidth = 0
	for i = 1, #fields do
		local field = fields[i]
		if field.visible ~= false and field.label then
			local labelText = field.label
			local labelWidth = getTextManager():MeasureStringX(UIFont.Small, labelText)
			maxLabelWidth = math.max(maxLabelWidth, labelWidth)
		end
	end

	local labelWidth = maxLabelWidth + DirectiveEditorPanel.UI.PADDING

	for i = 1, #fields do
		local field = fields[i]
		if field.visible ~= false then
			local fieldData = nil

			if field.type == "text" then
				fieldData = self:createTextField(field, padX, y, labelWidth, fieldHeight)
			elseif field.type == "number" then
				fieldData = self:createNumberField(field, padX, y, labelWidth, fieldHeight)
			elseif field.type == "boolean" then
				fieldData = self:createBooleanField(field, padX, y, labelWidth, fieldHeight)
			elseif field.type == "date" then
				fieldData = self:createDateField(field, padX, y, labelWidth, fieldHeight)
			elseif field.type == "list" then
				fieldData = self:createListField(field, padX, y, labelWidth, fieldHeight)
			elseif field.type == "button" then
				fieldData = self:createButtonField(field, padX, y, labelWidth, fieldHeight)
			end

			if fieldData then
				self.formFields[field.key] = fieldData

				for j = 1, #fieldData.elements do
					local element = fieldData.elements[j]
					self.scrollableContent:addContent(element)
				end

				local fieldActualHeight = fieldHeight
				if field.type == "text" and field.multiline then
					fieldActualHeight = fieldHeight * 3
				end

				y = y + fieldActualHeight + padY
			end
		end
	end

	return y
end

function DirectiveFormModal:createTextField(field, x, y, labelWidth, fieldHeight)
	local elements = {}

	local label = ISLabel:new(
		x,
		y,
		fieldHeight,
		field.label,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	table.insert(elements, label)

	local textWidth = self.width - x - labelWidth - 2 * DirectiveEditorPanel.UI.PADDING
	local textEntry = ISTextEntryBox:new(
		tostring(field.value or ""),
		x + labelWidth,
		y,
		textWidth,
		field.multiline and fieldHeight * 3 or fieldHeight
	)
	textEntry:initialise()
	textEntry:instantiate()
	textEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	textEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	textEntry:setMultipleLine(field.multiline or false)

	table.insert(elements, textEntry)

	return {
		type = field.type,
		key = field.key,
		elements = elements,
		getValue = function()
			return textEntry:getText()
		end,
	}
end

function DirectiveFormModal:createNumberField(field, x, y, labelWidth, fieldHeight)
	local elements = {}

	local label = ISLabel:new(
		x,
		y,
		fieldHeight,
		field.label,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	table.insert(elements, label)

	local numberEntry = ISTextEntryBox:new(tostring(field.value or 0), x + labelWidth, y, labelWidth, fieldHeight)
	numberEntry:initialise()
	numberEntry:instantiate()
	numberEntry:setOnlyNumbers(true)
	numberEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	numberEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER

	table.insert(elements, numberEntry)

	return {
		type = field.type,
		key = field.key,
		elements = elements,
		getValue = function()
			return tonumber(numberEntry:getText()) or 0
		end,
	}
end

function DirectiveFormModal:createBooleanField(field, x, y, labelWidth, fieldHeight)
	local elements = {}

	local label = ISLabel:new(
		x,
		y,
		fieldHeight,
		field.label,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	table.insert(elements, label)

	local checkbox = ISTickBox:new(x + labelWidth, y, labelWidth, fieldHeight, "", nil, nil)
	checkbox:initialise()
	checkbox:addOption("Yes")
	checkbox:setSelected(1, field.value or false)
	checkbox:setWidthToFit()

	table.insert(elements, checkbox)

	return {
		type = field.type,
		key = field.key,
		elements = elements,
		getValue = function()
			return checkbox:isSelected(1)
		end,
	}
end

function DirectiveFormModal:createDateField(field, x, y, labelWidth, fieldHeight)
	local elements = {}

	local label = ISLabel:new(
		x,
		y,
		fieldHeight,
		field.label,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	table.insert(elements, label)

	local dateStr = ""
	if type(field.value) == "table" then
		dateStr = string.format(
			"%02d:%02d %02d/%02d/%d",
			field.value.hour or 0,
			field.value.min or 0,
			field.value.month or 1,
			field.value.day or 1,
			field.value.year or 1993
		)
	end

	local dateLabel = ISLabel:new(
		x + labelWidth,
		y,
		fieldHeight,
		dateStr,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	dateLabel:initialise()
	dateLabel:instantiate()
	dateLabel.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	dateLabel.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	dateLabel.dateTable = field.value

	table.insert(elements, dateLabel)

	local dateDisplay = dateLabel
	local dateWidth = getTextManager():MeasureStringX(UIFont.Small, string.format("00:00 00/00/0000"))
	local pickerBtn = ISButton:new(
		x + labelWidth + dateWidth + DirectiveEditorPanel.UI.PADDING,
		y,
		30,
		fieldHeight,
		"",
		self,
		function()
			self:openDatePicker(dateDisplay, field.label)
		end
	)
	pickerBtn:initialise()
	pickerBtn:setImage(getTexture("media/ui/KnoxNet/computer/ui_knoxnet_directive_calendar.png"))
	pickerBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	pickerBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER

	table.insert(elements, pickerBtn)

	return {
		type = field.type,
		key = field.key,
		elements = elements,
		getValue = function()
			return dateLabel.dateTable
		end,
	}
end

function DirectiveFormModal:createButtonField(field, x, y, labelWidth, fieldHeight)
	local elements = {}

	local buttonX = x
	if field.label and field.label ~= field.value then
		local label = ISLabel:new(
			x,
			y,
			fieldHeight,
			field.label,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
		table.insert(elements, label)
		buttonX = x + labelWidth
	end

	local button = ISButton:new(buttonX, y, labelWidth + 50, fieldHeight, field.value or field.label, self, function()
		field.clicked = true
		if field.key == "addAcceptedItem" then
			local directive = self.directive
			if directive and directive.addAcceptedItem then
				directive:addAcceptedItem("", 0, 0, 0)
				self:refreshFormFields()
			end
		elseif field.key == "addIndividualItemReward" then
			local directive = self.directive
			if directive and directive.addIndividualItemReward then
				directive:addIndividualItemReward()
				self:refreshFormFields()
			end
		elseif field.key == "addIndividualSkillReward" then
			local directive = self.directive
			if directive and directive.addIndividualSkillReward then
				directive:addIndividualSkillReward()
				self:refreshFormFields()
			end
		end
	end)
	button:initialise()
	button.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	button.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	button.textColor = DirectiveConstants.COLORS.TEXT.NORMAL

	table.insert(elements, button)

	return {
		type = field.type,
		key = field.key,
		elements = elements,
		getValue = function()
			return field.clicked or false
		end,
	}
end

function DirectiveFormModal:refreshFormFields()
	for _, fieldData in pairs(self.formFields) do
		for j = 1, #fieldData.elements do
			local element = fieldData.elements[j]
			self.scrollableContent:removeChild(element)
		end
	end

	self:createFormContent()
end

function DirectiveFormModal:openDatePicker(dateField, fieldName)
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()

	local width = 300
	local height = 400
	local x = (screenWidth / 2) - (width / 2)
	local y = (screenHeight / 2) - (height / 2)

	local datePicker = DateTimeSelector:new(x, y, width, height, false, nil)
	datePicker.startOnMonday = true
	datePicker.showTime = true
	datePicker.showSeconds = false
	datePicker.use24HourFormat = true
	datePicker.fieldName = fieldName
	datePicker.targetField = dateField

	datePicker:setOnDateTimeSelected(self, self.onDateSelected)
	datePicker:initialise()
	datePicker:addToUIManager()
	datePicker:bringToTop()
end

function DirectiveFormModal:onDateSelected(dateTime, wasCancelled)
	if wasCancelled or not dateTime then
		return
	end

	local targetField = dateTime.target and dateTime.target.targetField
	if not targetField then
		return
	end

	local dateStr = string.format(
		"%02d:%02d %02d/%02d/%d",
		dateTime.hour,
		dateTime.min,
		dateTime.month,
		dateTime.day,
		dateTime.year
	)

	targetField:setName(dateStr)
	targetField.dateTable = {
		hour = dateTime.hour,
		min = dateTime.min,
		day = dateTime.day,
		month = dateTime.month,
		year = dateTime.year,
	}
end

function DirectiveFormModal:createButtons()
	local btnWidth = 100
	local btnHeight = DirectiveEditorPanel.UI.BUTTON_HEIGHT
	local btnY = self.height - btnHeight - 10

	self.saveBtn = ISButton:new(
		self.width / 2 - btnWidth - 5,
		btnY,
		btnWidth,
		btnHeight,
		"Save",
		self,
		DirectiveFormModal.onSaveDirective
	)
	self.saveBtn:initialise()
	self.saveBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	self.saveBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.saveBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.saveBtn)

	self.cancelBtn =
		ISButton:new(self.width / 2 + 5, btnY, btnWidth, btnHeight, "Cancel", self, DirectiveFormModal.close)
	self.cancelBtn:initialise()
	self.cancelBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.CLOSE
	self.cancelBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.cancelBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.cancelBtn)
end

function DirectiveFormModal:onSaveDirective()
	local formValues = {}
	for key, fieldData in pairs(self.formFields) do
		if fieldData.getValue then
			formValues[key] = fieldData.getValue()
		end
	end

	local directive = self.directive
	if not directive then
		directive = DirectiveManager.createDirective(self.directiveType, {})
	end

	local fields = directive:getFormFields()
	for _, field in ipairs(fields) do
		if formValues[field.key] ~= nil then
			field.value = formValues[field.key]
		end
	end

	directive:applyFormFields(fields)

	self.parentPanel:onSaveDirective(directive)
	self:close()
end

function DirectiveFormModal:close()
	self:setVisible(false)
	self:removeFromUIManager()
end

function DirectiveFormModal:prerender()
	ISPanel.prerender(self)

	local titleText = self.directive and "EDIT DIRECTIVE" or "CREATE NEW DIRECTIVE"
	local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, titleText)
	local titleY = 10
	self:drawText(
		titleText,
		(self.width - titleWidth) / 2,
		titleY,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)

	self:drawRectBorder(
		0,
		0,
		self.width,
		self.height,
		DirectiveConstants.COLORS.BORDER.a,
		DirectiveConstants.COLORS.BORDER.r,
		DirectiveConstants.COLORS.BORDER.g,
		DirectiveConstants.COLORS.BORDER.b
	)
end

function DirectiveFormModal:render()
	ISPanel.render(self)
end

function DirectiveFormModal:new(x, y, width, height, directiveType, parent, directive)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	o.borderColor = DirectiveConstants.COLORS.BORDER
	o.directiveType = directiveType
	o.parentPanel = parent
	o.directive = directive
	o.moveWithMouse = true

	return o
end

---@class ItemDialogModal : ISPanel
ItemDialogModal = ISPanel:derive("ItemDialogModal")

function ItemDialogModal:initialise()
	ISPanel.initialise(self)
end

function ItemDialogModal:createChildren()
	local titleText = self.item and "EDIT ITEM" or "ADD ITEM"
	local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, titleText)
	local titleY = 10
	self:drawText(
		titleText,
		(self.width - titleWidth) / 2,
		titleY,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)

	local padX = DirectiveEditorPanel.UI.PANEL_PADDING
	local padY = DirectiveEditorPanel.UI.FIELD_PADDING
	local fieldHeight = DirectiveEditorPanel.UI.FIELD_HEIGHT
	local labelWidth = 120

	local y = titleY + getTextManager():getFontHeight(UIFont.Medium) + 20

	self:addChild(
		ISLabel:new(
			padX,
			y,
			fieldHeight,
			"Item Type:",
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
	)
	self.itemTypeEntry = ISTextEntryBox:new(
		self.item and self.item.item or "",
		padX + labelWidth,
		y,
		self.width - labelWidth - (padX * 2),
		fieldHeight
	)
	self.itemTypeEntry:initialise()
	self.itemTypeEntry:instantiate()
	self.itemTypeEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.itemTypeEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	self:addChild(self.itemTypeEntry)

	self:drawText(
		"(Format: ModName.ItemName, e.g. Base.Axe)",
		padX,
		y + fieldHeight + 2,
		DirectiveConstants.COLORS.TEXT.DIM.r,
		DirectiveConstants.COLORS.TEXT.DIM.g,
		DirectiveConstants.COLORS.TEXT.DIM.b,
		DirectiveConstants.COLORS.TEXT.DIM.a,
		UIFont.Small
	)

	y = y + fieldHeight + 20

	self:addChild(
		ISLabel:new(
			padX,
			y,
			fieldHeight,
			"Count:",
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
	)
	self.countEntry =
		ISTextEntryBox:new(self.item and tostring(self.item.count) or "1", padX + labelWidth, y, 80, fieldHeight)
	self.countEntry:initialise()
	self.countEntry:instantiate()
	self.countEntry:setOnlyNumbers(true)
	self.countEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.countEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	self:addChild(self.countEntry)

	self:addChild(
		ISLabel:new(
			padX + labelWidth + 90,
			y + 3,
			fieldHeight,
			"(Total items needed)",
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			UIFont.Small,
			true
		)
	)

	y = y + fieldHeight + padY

	self:addChild(
		ISLabel:new(
			padX,
			y,
			fieldHeight,
			"Min Condition:",
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
	)
	self.minConditionEntry =
		ISTextEntryBox:new(self.item and tostring(self.item.minCondition) or "0", padX + labelWidth, y, 80, fieldHeight)
	self.minConditionEntry:initialise()
	self.minConditionEntry:instantiate()
	self.minConditionEntry:setOnlyNumbers(true)
	self.minConditionEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.minConditionEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	self:addChild(self.minConditionEntry)

	self:addChild(
		ISLabel:new(
			padX + labelWidth + 90,
			y + 3,
			fieldHeight,
			"% (0-100, 0 = any condition)",
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			UIFont.Small,
			true
		)
	)

	y = y + fieldHeight + padY

	self:addChild(
		ISLabel:new(
			padX,
			y,
			fieldHeight,
			"Min Uses:",
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
	)
	self.minUsesEntry =
		ISTextEntryBox:new(self.item and tostring(self.item.minUses or 0) or "0", padX + labelWidth, y, 80, fieldHeight)
	self.minUsesEntry:initialise()
	self.minUsesEntry:instantiate()
	self.minUsesEntry:setOnlyNumbers(true)
	self.minUsesEntry.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	self.minUsesEntry.borderColor = DirectiveConstants.COLORS.FIELD.BORDER
	self:addChild(self.minUsesEntry)

	self:addChild(
		ISLabel:new(
			padX + labelWidth + 90,
			y + 3,
			fieldHeight,
			"(For drainable items, 0 = any uses)",
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			UIFont.Small,
			true
		)
	)

	y = y + fieldHeight + padY

	local helpText = "TIP: Set condition/uses to 0 if not applicable for this item."
	self:drawText(
		helpText,
		padX,
		y,
		DirectiveConstants.COLORS.TEXT.DIM.r,
		DirectiveConstants.COLORS.TEXT.DIM.g,
		DirectiveConstants.COLORS.TEXT.DIM.b,
		DirectiveConstants.COLORS.TEXT.DIM.a,
		UIFont.Small
	)

	y = y + 25

	self.collectedCount = self.item and self.item.collected or 0

	local btnWidth = 100
	local btnHeight = DirectiveEditorPanel.UI.BUTTON_HEIGHT
	local btnY = self.height - btnHeight - 10

	self.saveBtn =
		ISButton:new(self.width / 2 - btnWidth - 5, btnY, btnWidth, btnHeight, "Save", self, ItemDialogModal.onSaveItem)
	self.saveBtn:initialise()
	self.saveBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	self.saveBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.saveBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.saveBtn)

	self.cancelBtn = ISButton:new(self.width / 2 + 5, btnY, btnWidth, btnHeight, "Cancel", self, ItemDialogModal.close)
	self.cancelBtn:initialise()
	self.cancelBtn.backgroundColor = DirectiveConstants.COLORS.BUTTON.CLOSE
	self.cancelBtn.borderColor = DirectiveConstants.COLORS.BUTTON.BORDER
	self.cancelBtn.textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	self:addChild(self.cancelBtn)
end

function ItemDialogModal:onSaveItem()
	if self.itemTypeEntry:getText() == "" then
		local modal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			"Error",
			false,
			nil,
			nil
		)
		modal.text = "Item type is required"
		modal:initialise()
		modal:addToUIManager()
		return
	end

	local count = tonumber(self.countEntry:getText()) or 0
	if count <= 0 then
		local modal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			"Error",
			false,
			nil,
			nil
		)
		modal.text = "Count must be greater than 0"
		modal:initialise()
		modal:addToUIManager()
		return
	end

	local minCondition = tonumber(self.minConditionEntry:getText()) or 0
	minCondition = math.max(0, math.min(100, minCondition))

	local minUses = tonumber(self.minUsesEntry:getText()) or 0
	minUses = math.max(0, minUses)

	local item = self.item or {}
	item.item = self.itemTypeEntry:getText()
	item.count = count
	item.minCondition = minCondition
	item.minUses = minUses
	item.collected = self.collectedCount or 0

	if self.item and self.parentForm.itemsList:isItemSelected(self.itemText) then
		self.parentForm.itemsList:removeItem(self.itemText)
	end

	local displayText = item.item

	local row = self.parentForm.itemsList:addItem(displayText, item)

	if row then
		local countText = tostring(item.count)
		local conditionText = "-"
		if item.minCondition and item.minCondition > 0 then
			conditionText = tostring(item.minCondition)
		end
		local usesText = "-"
		if item.minUses and item.minUses > 0 then
			usesText = tostring(item.minUses)
		end

		row.columns = {}
		row.columns[1] = displayText
		row.columns[2] = countText
		row.columns[3] = conditionText
		row.columns[4] = usesText
	end

	self.parentForm.itemsList:sort()

	self:close()
end

function ItemDialogModal:close()
	self:setVisible(false)
	self:removeFromUIManager()
end

function ItemDialogModal:render()
	ISPanel.render(self)
end

function ItemDialogModal:prerender()
	ISPanel.prerender(self)

	self:drawRectBorder(
		0,
		0,
		self.width,
		self.height,
		DirectiveConstants.COLORS.BORDER.a,
		DirectiveConstants.COLORS.BORDER.r,
		DirectiveConstants.COLORS.BORDER.g,
		DirectiveConstants.COLORS.BORDER.b
	)
end

function ItemDialogModal:new(x, y, width, height, parentForm, item, itemText)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = DirectiveConstants.COLORS.BACKGROUND
	o.borderColor = DirectiveConstants.COLORS.BORDER
	o.parentForm = parentForm
	o.item = item
	o.itemText = itemText or (item and item.text) or nil
	o.moveWithMouse = true

	return o
end

return DirectiveEditorPanel
