local AudioManager = require("KnoxNet/core/AudioManager")
local LoreManager = require("KnoxNet/modules/lore/LoreManager")
local TerminalConstants = require("KnoxNet/core/TerminalConstants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

---@class LoreManagerPanel : ISPanel
local LoreManagerPanel = ISPanel:derive("LoreManagerPanel")

LoreManagerPanel.UI = {
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

function LoreManagerPanel:createChildren()
	self.fontHgtSmall = getTextManager():getFontHeight(UIFont.Small)
	self.fontHgtMedium = getTextManager():getFontHeight(UIFont.Medium)

	self.minWidth = 600
	self.minHeight = 400

	self:calculateLayout()
	self:createLeftPanel()
	self:createRightPanel()
	self:loadData()
	self:setupInitialState()
end

function LoreManagerPanel:calculateLayout()
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

function LoreManagerPanel:createLeftPanel()
	local padX = self.UI.PANEL_PADDING
	local headerY = padX

	-- Headers
	self.categoriesHeader = ISLabel:new(
		padX,
		headerY,
		self.headerHeight,
		"LORE CATEGORIES",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(self.categoriesHeader)

	-- Categories list
	self.categoriesList =
		ISScrollingListBox:new(padX, self.listY, self.leftPanelWidth - padX * 2, self.listHeight / 2 - 10)
	self.categoriesList:initialise()
	self.categoriesList:setOnMouseDownFunction(self, self.onCategorySelected)
	self.categoriesList.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	self.categoriesList.borderColor = TerminalConstants.COLORS.BORDER
	self.categoriesList.drawBorder = true
	self:addChild(self.categoriesList)

	-- Entries header
	self.entriesHeader = ISLabel:new(
		padX,
		self.listY + self.listHeight / 2,
		self.headerHeight,
		"LORE ENTRIES",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(self.entriesHeader)

	-- Entries list
	self.entriesList = ISScrollingListBox:new(
		padX,
		self.listY + self.listHeight / 2 + 20,
		self.leftPanelWidth - padX * 2,
		self.listHeight / 2 - 20
	)
	self.entriesList:initialise()
	self.entriesList:setOnMouseDownFunction(self, self.onEntrySelected)
	self.entriesList.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	self.entriesList.borderColor = TerminalConstants.COLORS.BORDER
	self.entriesList.drawBorder = true
	self:addChild(self.entriesList)

	-- Action buttons
	local btnWidth = 60
	local spacing = 10
	local startX = padX

	-- Add category button
	self.addCategoryBtn =
		ISButton:new(startX, self.btnY, btnWidth, self.btnHeight, "Add Cat", self, self.showAddCategoryModal)
	self.addCategoryBtn:initialise()
	self.addCategoryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.addCategoryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.addCategoryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self:addChild(self.addCategoryBtn)

	-- Edit category button
	self.editCategoryBtn = ISButton:new(
		startX + btnWidth + spacing,
		self.btnY,
		btnWidth,
		self.btnHeight,
		"Edit Cat",
		self,
		self.showEditCategoryModal
	)
	self.editCategoryBtn:initialise()
	self.editCategoryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.editCategoryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.editCategoryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self.editCategoryBtn.enable = false
	self:addChild(self.editCategoryBtn)

	-- Delete category button
	self.deleteCategoryBtn = ISButton:new(
		startX + (btnWidth + spacing) * 2,
		self.btnY,
		btnWidth,
		self.btnHeight,
		"Del Cat",
		self,
		self.onDeleteCategory
	)
	self.deleteCategoryBtn:initialise()
	self.deleteCategoryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.CLOSE
	self.deleteCategoryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.deleteCategoryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self.deleteCategoryBtn.enable = false
	self:addChild(self.deleteCategoryBtn)
end

function LoreManagerPanel:createRightPanel()
	local padX = self.UI.PANEL_PADDING
	local headerY = padX
	local startX = self.rightPanelX + padX

	-- Header text
	self.formTitle = ISLabel:new(
		startX,
		headerY,
		self.headerHeight,
		"LORE ENTRY EDITOR",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium,
		true
	)
	self:addChild(self.formTitle)

	-- Form for entry editing
	local formY = headerY + self.headerHeight + 10
	local fieldHeight = self.UI.FIELD_HEIGHT
	local fieldPadding = self.UI.FIELD_PADDING
	local labelWidth = 120
	local currentY = formY

	-- Entry Title
	local titleLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Title:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(titleLabel)

	self.titleEntry =
		ISTextEntryBox:new("", startX + labelWidth, currentY, self.rightPanelWidth - labelWidth - padX * 2, fieldHeight)
	self.titleEntry:initialise()
	self.titleEntry:instantiate()
	self.titleEntry.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
	self.titleEntry.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.titleEntry)

	currentY = currentY + fieldHeight + fieldPadding

	-- Entry Date
	local dateLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Date:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(dateLabel)

	self.dateEntry = ISTextEntryBox:new("", startX + labelWidth, currentY, 150, fieldHeight)
	self.dateEntry:initialise()
	self.dateEntry:instantiate()
	self.dateEntry.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
	self.dateEntry.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.dateEntry)

	-- Date format hint
	local dateHint = ISLabel:new(
		startX + labelWidth + 160,
		currentY + 3,
		fieldHeight,
		"(e.g. 1993-07-08)",
		TerminalConstants.COLORS.TEXT.DIM.r,
		TerminalConstants.COLORS.TEXT.DIM.g,
		TerminalConstants.COLORS.TEXT.DIM.b,
		TerminalConstants.COLORS.TEXT.DIM.a,
		UIFont.Small,
		false
	)
	self:addChild(dateHint)

	currentY = currentY + fieldHeight + fieldPadding

	-- Category dropdown
	local categoryLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Category:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(categoryLabel)

	self.categoryCombo = ISComboBox:new(startX + labelWidth, currentY, 200, fieldHeight)
	self.categoryCombo:initialise()
	self.categoryCombo.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	self.categoryCombo.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.categoryCombo)

	currentY = currentY + fieldHeight + fieldPadding

	-- Content Text
	local contentLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Content Text:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(contentLabel)

	currentY = currentY + fieldHeight

	self.contentEntry = ISTextEntryBox:new("", startX, currentY, self.rightPanelWidth - padX * 2, 100)
	self.contentEntry:initialise()
	self.contentEntry:instantiate()
	self.contentEntry:setMultipleLine(true)
	self.contentEntry.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
	self.contentEntry.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.contentEntry)

	currentY = currentY + 100 + fieldPadding

	-- Audio File Path
	local audioLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Audio File:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(audioLabel)

	self.audioEntry =
		ISTextEntryBox:new("", startX + labelWidth, currentY, self.rightPanelWidth - labelWidth - padX * 2, fieldHeight)
	self.audioEntry:initialise()
	self.audioEntry:instantiate()
	self.audioEntry.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
	self.audioEntry.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.audioEntry)

	currentY = currentY + fieldHeight + 5

	-- Audio file hint
	local audioHint = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"(e.g. media/sound/knoxnet_recording.ogg)",
		TerminalConstants.COLORS.TEXT.DIM.r,
		TerminalConstants.COLORS.TEXT.DIM.g,
		TerminalConstants.COLORS.TEXT.DIM.b,
		TerminalConstants.COLORS.TEXT.DIM.a,
		UIFont.Small,
		false
	)
	self:addChild(audioHint)

	currentY = currentY + fieldHeight + fieldPadding

	-- Requires Cassette Checkbox
	self.requiresCassetteCheckbox = ISTickBox:new(startX, currentY, 100, fieldHeight, "", nil, nil)
	self.requiresCassetteCheckbox:initialise()
	self.requiresCassetteCheckbox:instantiate()
	self.requiresCassetteCheckbox:addOption("Requires Audio Cassette")
	self.requiresCassetteCheckbox.selected[1] = false
	self.requiresCassetteCheckbox:setWidthToFit()
	self:addChild(self.requiresCassetteCheckbox)

	currentY = currentY + fieldHeight + fieldPadding

	-- Cassette Name
	local cassetteNameLabel = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"Cassette Name:",
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Small,
		true
	)
	self:addChild(cassetteNameLabel)

	self.cassetteNameEntry =
		ISTextEntryBox:new("", startX + labelWidth, currentY, self.rightPanelWidth - labelWidth - padX * 2, fieldHeight)
	self.cassetteNameEntry:initialise()
	self.cassetteNameEntry:instantiate()
	self.cassetteNameEntry.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
	self.cassetteNameEntry.borderColor = TerminalConstants.COLORS.INPUT.BORDER
	self:addChild(self.cassetteNameEntry)

	currentY = currentY + fieldHeight + 5

	-- Cassette name hint
	local cassetteHint = ISLabel:new(
		startX,
		currentY,
		fieldHeight,
		"(Leave blank to use default: 'Lore Cassette: <title>')",
		TerminalConstants.COLORS.TEXT.DIM.r,
		TerminalConstants.COLORS.TEXT.DIM.g,
		TerminalConstants.COLORS.TEXT.DIM.b,
		TerminalConstants.COLORS.TEXT.DIM.a,
		UIFont.Small,
		false
	)
	self:addChild(cassetteHint)

	currentY = currentY + fieldHeight + fieldPadding

	-- Action buttons
	local btnWidth = 80
	local spacing = 10
	local buttonsY = self.btnY

	-- Save button
	self.saveEntryBtn =
		ISButton:new(startX, buttonsY, btnWidth, self.btnHeight, "Save", self, LoreManagerPanel.onSaveEntry)
	self.saveEntryBtn:initialise()
	self.saveEntryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.saveEntryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.saveEntryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self:addChild(self.saveEntryBtn)

	-- New entry button
	self.newEntryBtn = ISButton:new(
		startX + btnWidth + spacing,
		buttonsY,
		btnWidth,
		self.btnHeight,
		"New Entry",
		self,
		LoreManagerPanel.onNewEntry
	)
	self.newEntryBtn:initialise()
	self.newEntryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.newEntryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.newEntryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self:addChild(self.newEntryBtn)

	-- Delete button
	self.deleteEntryBtn = ISButton:new(
		startX + (btnWidth + spacing) * 2,
		buttonsY,
		btnWidth,
		self.btnHeight,
		"Delete",
		self,
		LoreManagerPanel.onDeleteEntry
	)
	self.deleteEntryBtn:initialise()
	self.deleteEntryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.CLOSE
	self.deleteEntryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.deleteEntryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self.deleteEntryBtn.enable = false
	self:addChild(self.deleteEntryBtn)

	-- Test button
	self.testEntryBtn = ISButton:new(
		startX + (btnWidth + spacing) * 3,
		buttonsY,
		btnWidth,
		self.btnHeight,
		"Test",
		self,
		LoreManagerPanel.onTestEntry
	)
	self.testEntryBtn:initialise()
	self.testEntryBtn.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.testEntryBtn.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.testEntryBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
	self.testEntryBtn.enable = false
	self:addChild(self.testEntryBtn)

	-- Set the default state
	self.currentEntryId = nil
	self.currentCategoryId = nil
	self:clearEntryForm()
	self:updateButtonStates()
end

function LoreManagerPanel:loadData()
	-- Load categories
	self:refreshCategoriesList()

	-- Load entries
	self:refreshEntriesList()

	-- Update category dropdown
	self:updateCategoryCombo()
end

function LoreManagerPanel:setupInitialState()
	-- Select first category if available
	if self.categoriesList.items and #self.categoriesList.items > 0 then
		self.categoriesList.selected = 1
		self:onCategorySelected(self.categoriesList.items[1])
	end
end

function LoreManagerPanel:refreshCategoriesList()
	self.categoriesList:clear()

	local categories = LoreManager.getCategories()
	for _, category in ipairs(categories) do
		local item = {}
		item.text = category.name
		item.category = category
		self.categoriesList:addItem(item.text, item)
	end
end

function LoreManagerPanel:refreshEntriesList()
	self.entriesList:clear()

	if not self.currentCategoryId then
		return
	end

	local categories = LoreManager.getCategories()
	for _, category in ipairs(categories) do
		if category.id == self.currentCategoryId then
			if category.entries then
				for _, entry in ipairs(category.entries) do
					local item = {}
					item.text = entry.title
					item.entry = entry
					self.entriesList:addItem(item.text, item)
				end
			end
			break
		end
	end
end

function LoreManagerPanel:updateCategoryCombo()
	self.categoryCombo:clear()

	local categories = LoreManager.getCategories()
	for _, category in ipairs(categories) do
		self.categoryCombo:addOption(category.name)
		self.categoryCombo.options[#self.categoryCombo.options].data = category.id
	end

	if self.currentCategoryId then
		for i = 1, #self.categoryCombo.options do
			if self.categoryCombo.options[i].data == self.currentCategoryId then
				self.categoryCombo.selected = i
				break
			end
		end
	else
		self.categoryCombo.selected = 1
	end
end

function LoreManagerPanel:updateButtonStates()
	self.editCategoryBtn.enable = (self.currentCategoryId ~= nil)
	self.deleteCategoryBtn.enable = (self.currentCategoryId ~= nil)
	self.deleteEntryBtn.enable = (self.currentEntryId ~= nil)
	self.testEntryBtn.enable = (self.currentEntryId ~= nil)
end

function LoreManagerPanel:clearEntryForm()
	self.titleEntry:setText("")
	self.dateEntry:setText("")
	self.contentEntry:setText("")
	self.audioEntry:setText("")
	self.requiresCassetteCheckbox.selected[1] = false
	self.cassetteNameEntry:setText("")

	self.currentEntryId = nil
	self:updateButtonStates()
end

function LoreManagerPanel:fillEntryForm(entry)
	if not entry then
		self:clearEntryForm()
		return
	end

	self.titleEntry:setText(entry.title or "")
	self.dateEntry:setText(entry.date or "")
	self.contentEntry:setText(entry.content or "")
	self.audioEntry:setText(entry.audioFile or "")
	self.requiresCassetteCheckbox.selected[1] = entry.requiresCassette or false
	self.cassetteNameEntry:setText(entry.cassetteName or "")

	self.currentEntryId = entry.id

	-- Set the category combo to the entry's category
	if entry.categoryId then
		for i = 1, #self.categoryCombo.options do
			if self.categoryCombo.options[i].data == entry.categoryId then
				self.categoryCombo.selected = i
				break
			end
		end
	end

	self:updateButtonStates()
end

function LoreManagerPanel:onCategorySelected(item)
	if not item or not item.item or not item.item.category then
		self.currentCategoryId = nil
		self:updateButtonStates()
		return
	end

	self.currentCategoryId = item.item.category.id
	self:refreshEntriesList()
	self:updateButtonStates()

	-- Select the first entry if available
	if self.entriesList.items and #self.entriesList.items > 0 then
		self.entriesList.selected = 1
		self:onEntrySelected(self.entriesList.items[1])
	else
		self:clearEntryForm()
	end
end

function LoreManagerPanel:onEntrySelected(item)
	if not item or not item.item or not item.item.entry then
		self.currentEntryId = nil
		self:updateButtonStates()
		return
	end

	-- Fill the form with the selected entry
	self:fillEntryForm(item.item.entry)
end

function LoreManagerPanel:onNewEntry()
	-- Clear the form for a new entry
	self:clearEntryForm()

	-- If a category is selected, set it in the dropdown
	if self.currentCategoryId then
		for i = 1, #self.categoryCombo.options do
			if self.categoryCombo.options[i].data == self.currentCategoryId then
				self.categoryCombo.selected = i
				break
			end
		end
	end
end

function LoreManagerPanel:onSaveEntry()
	-- Get form values
	local title = self.titleEntry:getText()
	local date = self.dateEntry:getText()
	local content = self.contentEntry:getText()
	local audioFile = self.audioEntry:getText()
	local requiresCassette = self.requiresCassetteCheckbox.selected[1]
	local cassetteName = self.cassetteNameEntry:getText()

	-- Get the selected category ID
	local categoryId = nil
	if self.categoryCombo.selected > 0 then
		categoryId = self.categoryCombo.options[self.categoryCombo.selected].data
	end

	-- Validate input
	if title == "" then
		self:showErrorModal("Error", "Title is required")
		return
	end

	if content == "" and (audioFile == "" or not audioFile) then
		self:showErrorModal("Error", "Either content text or audio file must be provided")
		return
	end

	if not categoryId then
		self:showErrorModal("Error", "Please select a category")
		return
	end

	-- Save the entry
	if self.currentEntryId then
		-- Update existing entry
		local success = LoreManager.updateEntry(
			self.currentEntryId,
			title,
			content,
			audioFile,
			requiresCassette,
			cassetteName,
			date,
			categoryId
		)

		if success then
			TerminalSounds.playUISound("sfx_knoxnet_key_4")
			self:refreshCategoriesList()
			self:refreshEntriesList()
			self:showSuccessModal("Success", "Entry updated successfully")
		else
			self:showErrorModal("Error", "Failed to update entry")
		end
	else
		-- Create new entry
		local entryId =
			LoreManager.addEntry(categoryId, title, content, audioFile, requiresCassette, cassetteName, date)

		if entryId then
			TerminalSounds.playUISound("sfx_knoxnet_key_4")
			self:refreshCategoriesList()
			self:refreshEntriesList()
			self.currentEntryId = entryId
			self:updateButtonStates()
			self:showSuccessModal("Success", "Entry created successfully")

			-- Select the new entry in the list
			for i = 1, #self.entriesList.items do
				local item = self.entriesList.items[i]
				if item.item and item.item.entry and item.item.entry.id == entryId then
					self.entriesList.selected = i
					break
				end
			end
		else
			self:showErrorModal("Error", "Failed to create entry")
		end
	end
end

function LoreManagerPanel:onDeleteEntry()
	if not self.currentEntryId then
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
		function(target, button, data)
			if button.internal == "YES" then
				local success = LoreManager.deleteEntry(data.entryId)
				if success then
					TerminalSounds.playUISound("sfx_knoxnet_key_4")
					target:refreshCategoriesList()
					target:refreshEntriesList()
					target:clearEntryForm()
					target:showSuccessModal("Success", "Entry deleted successfully")
				else
					target:showErrorModal("Error", "Failed to delete entry")
				end
			end
		end,
		nil,
		{ entryId = self.currentEntryId }
	)
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:onTestEntry()
	if not self.currentEntryId then
		return
	end

	local entry = LoreManager.getEntryById(self.currentEntryId)
	if not entry then
		self:showErrorModal("Error", "Entry not found")
		return
	end

	-- Create a test preview modal
	local previewModal = ISLorePreviewModal:new(
		getCore():getScreenWidth() / 2 - 300,
		getCore():getScreenHeight() / 2 - 200,
		600,
		400,
		entry
	)
	previewModal:initialise()
	previewModal:addToUIManager()
end

function LoreManagerPanel:showAddCategoryModal()
	local modal = ISTextEntryModal:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		180,
		"Add New Category",
		"",
		"",
		"Add",
		self,
		function(target, button, data)
			if button.internal == "OK" and data.nameText and data.nameText ~= "" then
				local categoryId = LoreManager.addCategory(data.nameText, data.descText or "")
				if categoryId then
					TerminalSounds.playUISound("sfx_knoxnet_key_4")
					target:refreshCategoriesList()
					target:updateCategoryCombo()

					-- Select the new category
					for i = 1, #target.categoriesList.items do
						local item = target.categoriesList.items[i]
						if item.item and item.item.category and item.item.category.id == categoryId then
							target.categoriesList.selected = i
							target:onCategorySelected(item)
							break
						end
					end
				else
					target:showErrorModal("Error", "Failed to create category")
				end
			end
		end
	)

	modal:addTextField("Category Name:", "nameText", "", 0)
	modal:addTextField("Description:", "descText", "", 1)
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:showEditCategoryModal()
	if not self.currentCategoryId then
		return
	end

	-- Find the current category
	local categories = LoreManager.getCategories()
	local currentCategory = nil

	for _, category in ipairs(categories) do
		if category.id == self.currentCategoryId then
			currentCategory = category
			break
		end
	end

	if not currentCategory then
		return
	end

	local modal = ISTextEntryModal:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		180,
		"Edit Category",
		currentCategory.name or "",
		currentCategory.description or "",
		"Update",
		self,
		function(target, button, data)
			if button.internal == "OK" and data.nameText and data.nameText ~= "" then
				local success = LoreManager.updateCategory(target.currentCategoryId, data.nameText, data.descText or "")
				if success then
					TerminalSounds.playUISound("sfx_knoxnet_key_4")
					target:refreshCategoriesList()
					target:updateCategoryCombo()
				else
					target:showErrorModal("Error", "Failed to update category")
				end
			end
		end
	)

	modal:addTextField("Category Name:", "nameText", currentCategory.name or "", 0)
	modal:addTextField("Description:", "descText", currentCategory.description or "", 1)
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:onDeleteCategory()
	if not self.currentCategoryId then
		return
	end

	local modal = ISModalDialog:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		150,
		"Confirm Category Deletion",
		true,
		self,
		function(target, button, data)
			if button.internal == "YES" then
				local success = LoreManager.deleteCategory(data.categoryId)
				if success then
					TerminalSounds.playUISound("sfx_knoxnet_key_4")
					target:refreshCategoriesList()
					target:refreshEntriesList()
					target:updateCategoryCombo()

					target.currentCategoryId = nil
					target:clearEntryForm()
					target:updateButtonStates()

					target:showSuccessModal("Success", "Category deleted successfully")
				else
					target:showErrorModal("Error", "Failed to delete category")
				end
			end
		end,
		nil,
		{ categoryId = self.currentCategoryId }
	)
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:showErrorModal(title, message)
	local modal = ISModalDialog:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		150,
		title,
		false,
		nil,
		nil
	)
	modal.text = message
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:showSuccessModal(title, message)
	local modal = ISModalDialog:new(
		getCore():getScreenWidth() / 2 - 175,
		getCore():getScreenHeight() / 2 - 75,
		350,
		150,
		title,
		false,
		nil,
		nil
	)
	modal.text = message
	modal:initialise()
	modal:addToUIManager()
end

function LoreManagerPanel:render()
	ISPanel.render(self)

	-- Draw separating line between panels
	self:drawRectStatic(self.leftPanelWidth + 9, 10, 2, self.height - 20, 0.8, 0.3, 0.3, 0.3)

	-- Draw empty state messages
	if self.categoriesList and #self.categoriesList.items == 0 then
		local noItemsText = "No categories defined. Click 'Add Cat' to create one."
		local textWidth = getTextManager():MeasureStringX(UIFont.Small, noItemsText)
		local listCenterX = self.UI.PANEL_PADDING + (self.leftPanelWidth - self.UI.PANEL_PADDING * 2) / 2
		local x = listCenterX - (textWidth / 2)

		self:drawText(
			noItemsText,
			x,
			self.listY + 40,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			UIFont.Small
		)
	end

	if self.entriesList and #self.entriesList.items == 0 and self.currentCategoryId then
		local noItemsText = "No entries in this category."
		local textWidth = getTextManager():MeasureStringX(UIFont.Small, noItemsText)
		local listCenterX = self.UI.PANEL_PADDING + (self.leftPanelWidth - self.UI.PANEL_PADDING * 2) / 2
		local x = listCenterX - (textWidth / 2)

		self:drawText(
			noItemsText,
			x,
			self.listY + self.listHeight / 2 + 60,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			UIFont.Small
		)
	end
end

function LoreManagerPanel:prerender()
	ISPanel.prerender(self)

	local headerText = "LORE DATABASE MANAGEMENT"
	local headerX = (self.width - getTextManager():MeasureStringX(UIFont.Medium, headerText)) / 2

	self:drawText(
		headerText,
		headerX,
		5,
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)
end

---@class ISTextEntryModal : ISPanel
ISTextEntryModal = ISPanel:derive("ISTextEntryModal")

function ISTextEntryModal:initialise()
	ISPanel.initialise(self)
	self.fields = self.fields or {}
end

function ISTextEntryModal:createChildren()
	self.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	self.borderColor = TerminalConstants.COLORS.BORDER

	-- Title
	self.titleLabel = ISLabel:new(0, 10, 20, self.title, 1, 1, 1, 1, UIFont.Medium, true)
	self.titleLabel:setX((self.width - self.titleLabel:getWidth()) / 2)
	self:addChild(self.titleLabel)

	-- Create all fields
	local currentY = 45
	for i, field in ipairs(self.fields) do
		local label = ISLabel:new(15, currentY, 25, field.label, 1, 1, 1, 1, UIFont.Small, false)
		self:addChild(label)

		local entryBox = ISTextEntryBox:new(field.initialValue or "", 15, currentY + 20, self.width - 30, 25)
		entryBox:initialise()
		entryBox:instantiate()
		entryBox.backgroundColor = TerminalConstants.COLORS.INPUT.BACKGROUND
		entryBox.borderColor = TerminalConstants.COLORS.INPUT.BORDER
		self:addChild(entryBox)

		field.entryBox = entryBox
		currentY = currentY + 55
	end

	-- Buttons
	local buttonWidth = 100
	local buttonHeight = 25
	local buttonY = self.height - buttonHeight - 10

	-- OK button
	self.okButton = ISButton:new(
		self.width / 2 - buttonWidth - 5,
		buttonY,
		buttonWidth,
		buttonHeight,
		self.actionBtnText or "OK",
		self,
		ISTextEntryModal.onButtonClick
	)
	self.okButton:initialise()
	self.okButton.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
	self.okButton.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.okButton.internal = "OK"
	self:addChild(self.okButton)

	-- Cancel button
	self.cancelButton = ISButton:new(
		self.width / 2 + 5,
		buttonY,
		buttonWidth,
		buttonHeight,
		"Cancel",
		self,
		ISTextEntryModal.onButtonClick
	)
	self.cancelButton:initialise()
	self.cancelButton.backgroundColor = TerminalConstants.COLORS.BUTTON.CLOSE
	self.cancelButton.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self.cancelButton.internal = "CANCEL"
	self:addChild(self.cancelButton)
end

function ISTextEntryModal:addTextField(label, key, initialValue, tabIndex)
	table.insert(self.fields, {
		label = label,
		key = key,
		initialValue = initialValue,
		tabIndex = tabIndex or 0,
	})
end

function ISTextEntryModal:onButtonClick(button)
	if button.internal == "OK" then
		local data = {}

		for _, field in ipairs(self.fields) do
			data[field.key] = field.entryBox:getText()
		end

		if self.target and self.callback then
			self.callback(self.target, button, data)
		end
	end

	self:close()
end

function ISTextEntryModal:close()
	self:setVisible(false)
	self:removeFromUIManager()
end

function ISTextEntryModal:new(x, y, width, height, title, field1Value, field2Value, actionBtnText, target, callback)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.title = title
	o.field1Value = field1Value
	o.field2Value = field2Value
	o.actionBtnText = actionBtnText
	o.target = target
	o.callback = callback
	o.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	o.borderColor = TerminalConstants.COLORS.BORDER
	o.fields = {}
	o.moveWithMouse = true

	return o
end

---@class ISLorePreviewModal : ISPanel
ISLorePreviewModal = ISPanel:derive("ISLorePreviewModal")

function ISLorePreviewModal:initialise()
	ISPanel.initialise(self)
	self.isPlaying = false
	self.audioId = nil
end

function ISLorePreviewModal:createChildren()
	self.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	self.borderColor = TerminalConstants.COLORS.BORDER

	-- Title
	local titleY = 10
	self.titleLabel = ISLabel:new(
		0,
		titleY,
		20,
		"PREVIEW: " .. (self.entry.title or "Entry Preview"),
		1,
		1,
		1,
		1,
		UIFont.Medium,
		true
	)
	self.titleLabel:setX((self.width - self.titleLabel:getWidth()) / 2)
	self:addChild(self.titleLabel)

	-- Date if available
	if self.entry.date and self.entry.date ~= "" then
		self.dateLabel = ISLabel:new(
			20,
			titleY + 30,
			20,
			"Date: " .. self.entry.date,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			UIFont.Small,
			false
		)
		self:addChild(self.dateLabel)
	end

	local contentY = titleY + 60

	-- Audio controls if available
	if self.entry.audioFile and self.entry.audioFile ~= "" then
		-- Cassette info
		local cassetteLabel = ISLabel:new(
			20,
			contentY,
			20,
			"Audio Available" .. (self.entry.requiresCassette and " (Requires Cassette)" or ""),
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.r,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.g,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.b,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.a,
			UIFont.Small,
			false
		)
		self:addChild(cassetteLabel)

		if self.entry.cassetteName and self.entry.cassetteName ~= "" then
			local cassetteNameLabel = ISLabel:new(
				20,
				contentY + 20,
				20,
				"Cassette Name: " .. self.entry.cassetteName,
				TerminalConstants.COLORS.TEXT.NORMAL.r,
				TerminalConstants.COLORS.TEXT.NORMAL.g,
				TerminalConstants.COLORS.TEXT.NORMAL.b,
				TerminalConstants.COLORS.TEXT.NORMAL.a,
				UIFont.Small,
				false
			)
			self:addChild(cassetteNameLabel)
		end

		-- Play button
		self.playButton = ISButton:new(20, contentY + 45, 120, 30, "Play Audio", self, ISLorePreviewModal.onPlayAudio)
		self.playButton:initialise()
		self.playButton.backgroundColor = TerminalConstants.COLORS.BUTTON.NORMAL
		self.playButton.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
		self:addChild(self.playButton)

		contentY = contentY + 90
	end

	-- Content text
	if self.entry.content and self.entry.content ~= "" then
		self.contentLabel = ISLabel:new(
			20,
			contentY,
			20,
			"Content:",
			TerminalConstants.COLORS.TEXT.NORMAL.r,
			TerminalConstants.COLORS.TEXT.NORMAL.g,
			TerminalConstants.COLORS.TEXT.NORMAL.b,
			TerminalConstants.COLORS.TEXT.NORMAL.a,
			UIFont.Small,
			true
		)
		self:addChild(self.contentLabel)

		local scrollViewHeight = self.height - contentY - 80
		self.contentView = ISScrollingListBox:new(20, contentY + 20, self.width - 40, scrollViewHeight)
		self.contentView:initialise()
		self.contentView.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
		self.contentView.borderColor = TerminalConstants.COLORS.BORDER
		self.contentView.itemheight = 20
		self.contentView.drawBorder = true
		self:addChild(self.contentView)

		-- Split content into lines and add to scrolling view
		local lineWidth = self.width - 60
		local contentLines = {}

		for line in string.gmatch(self.entry.content, "([^\n]+)") do
			-- Wrap long lines
			local wrappedLines = self:wrapText(line, lineWidth, UIFont.Small)
			for _, wrappedLine in ipairs(wrappedLines) do
				table.insert(contentLines, wrappedLine)
			end
		end

		for _, line in ipairs(contentLines) do
			self.contentView:addItem(line, nil)
		end
	end

	-- Close button
	self.closeButton =
		ISButton:new(self.width / 2 - 50, self.height - 40, 100, 30, "Close", self, ISLorePreviewModal.close)
	self.closeButton:initialise()
	self.closeButton.backgroundColor = TerminalConstants.COLORS.BUTTON.CLOSE
	self.closeButton.borderColor = TerminalConstants.COLORS.BUTTON.BORDER
	self:addChild(self.closeButton)
end

function ISLorePreviewModal:wrapText(text, maxWidth, font)
	local lines = {}
	local words = {}

	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end

	local currentLine = ""

	for i = 1, #words do
		local word = words[i]
		local testLine = currentLine ~= "" and (currentLine .. " " .. word) or word
		local lineWidth = getTextManager():MeasureStringX(font, testLine)

		if lineWidth <= maxWidth then
			currentLine = testLine
		else
			table.insert(lines, currentLine)
			currentLine = word
		end
	end

	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	return lines
end

function ISLorePreviewModal:onPlayAudio()
	if not self.entry.audioFile or self.entry.audioFile == "" then
		return
	end

	if self.isPlaying then
		-- Stop playback
		if self.audioId then
			AudioManager.stopSound(self.audioId)
			self.audioId = nil
		end
		self.isPlaying = false
		self.playButton:setTitle("Play Audio")
	else
		-- Start playback
		self.audioId = AudioManager.playSound(self.entry.audioFile)
		if self.audioId then
			self.isPlaying = true
			self.playButton:setTitle("Stop Audio")
		end
	end
end

function ISLorePreviewModal:close()
	-- Stop any playing audio
	if self.audioId then
		AudioManager.stopSound(self.audioId)
		self.audioId = nil
	end

	self:setVisible(false)
	self:removeFromUIManager()
end

function ISLorePreviewModal:new(x, y, width, height, entry)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.entry = entry
	o.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	o.borderColor = TerminalConstants.COLORS.BORDER
	o.moveWithMouse = true

	return o
end

function LoreManagerPanel:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	o.borderColor = TerminalConstants.COLORS.BORDER

	return o
end

return LoreManagerPanel
