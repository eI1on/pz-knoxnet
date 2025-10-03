local ColorUtils = require("ElyonLib/ColorUtils/ColorUtils")
local TerminalConstants = require("KnoxNet/core/TerminalConstants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local AudioManager = require("KnoxNet/core/AudioManager")
local ScrollManager = require("KnoxNet/ui/ScrollManager")
local TextWrapper = require("KnoxNet/ui/TextWrapper")
local LoreManager = require("KnoxNet_LoreModule/core/LoreManager")

local LoreModule = {

	moduleSounds = {},

	currentView = "categories", -- categories, entries, details
	selectedCategory = 1,
	selectedEntry = 1,
	categoryScroll = 0,
	entryScroll = 0,
	detailScroll = 0,
	categories = {},
	visibleEntries = {},
	currentlyViewingEntry = nil,

	isPlayingAudio = false,
	currentAudioId = nil,

	scrollManagers = {},

	theme = {
		HEADER_HEIGHT = 40,
		FOOTER_HEIGHT = 40,
		ENTRY_HEIGHT = 80,
		ENTRY_PADDING = 10,
		CATEGORY_HEIGHT = 40,
		CATEGORY_PADDING = 10,
		FONT = {
			TITLE = UIFont.Medium,
			SUBTITLE = UIFont.Small,
			BODY = UIFont.Code,
			LABEL = UIFont.Small,
		},
		CASSETTE = {
			WIDTH = 150,
			HEIGHT = 80,
		},
		AUDIO_CONTROLS = {
			HEIGHT = 40,
			BUTTON_SIZE = 30,
			PROGRESS_HEIGHT = 15,
		},
	},

	cassetteAnim = {
		isAnimating = false,
		progress = 0,
		startTime = 0,
		duration = 1500, -- ms
		direction = "in", -- "in" or "out"
	},

	audioVisualizer = {
		bars = 16,
		maxHeight = 40,
		values = {},
		lastUpdateTime = 0,
		updateRate = 100, -- ms
	},
}

function LoreModule:onActivate()
	self.terminal:setTitle("KNOXNET LORE DATABASE")

	self.scrollManagers = {
		categories = ScrollManager:new(0, self.terminal.contentAreaHeight),
		entries = ScrollManager:new(0, self.terminal.contentAreaHeight),
		details = ScrollManager:new(0, self.terminal.contentAreaHeight),
	}

	for i = 1, self.audioVisualizer.bars do
		self.audioVisualizer.values[i] = ZombRandFloat(0, 1) * 0.3
	end

	self:loadLoreData()

	local ambientSound = TerminalSounds.playLoopedSound("amb_knoxnet_terminal_lore")
	if ambientSound then
		table.insert(self.moduleSounds, ambientSound)
	end

	TerminalSounds.playUISound("sfx_knoxnet_lore_activate")
end

function LoreModule:onDeactivate()
	self:stopAudio()

	for _, soundId in pairs(self.moduleSounds) do
		TerminalSounds.stopSound(soundId)
	end
	self.moduleSounds = {}
end

function LoreModule:onClose()
	self:onDeactivate()
end

function LoreModule:loadLoreData()
	self.categories = LoreManager.getCategories()

	if #self.categories == 0 then
		table.insert(self.categories, {
			id = "general",
			name = "General Information",
			description = "General information about Knox County and the outbreak.",
			entries = {},
		})
	end

	self:updateVisibleEntries()

	self:updateScrollContentHeights()
end

function LoreModule:updateVisibleEntries()
	self.visibleEntries = {}

	if self.selectedCategory <= 0 or self.selectedCategory > #self.categories then
		return
	end

	local category = self.categories[self.selectedCategory]
	if not category.entries then
		return
	end

	local playerObj = getSpecificPlayer(0)
	local playerInv = playerObj:getInventory()

	for i, entry in ipairs(category.entries) do
		local isVisible = true

		if entry.requiresCassette then
			local cassetteName = entry.cassetteName or ("Lore Cassette: " .. entry.title)

			local items = playerInv:getItemsFromType("KnoxNet.LoreCassette")
			local hasCassette = false

			for j = 0, items:size() - 1 do
				local item = items:get(j)
				if item:getDisplayName() == cassetteName then
					hasCassette = true
					break
				end
			end

			if not hasCassette then
				isVisible = false
			end
		end

		if isVisible then
			table.insert(self.visibleEntries, {
				index = i,
				entry = entry,
			})
		end
	end

	if self.selectedEntry > #self.visibleEntries then
		self.selectedEntry = math.max(1, #self.visibleEntries)
	end

	self:updateScrollContentHeights()
end

function LoreModule:updateScrollContentHeights()
	local categoryHeight = self.theme.CATEGORY_HEIGHT + self.theme.CATEGORY_PADDING
	local categoriesHeight = #self.categories * categoryHeight
	self.scrollManagers.categories:updateContentHeight(categoriesHeight)
	self.scrollManagers.categories:updateVisibleHeight(
		self.terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT
	)

	local entryHeight = self.theme.ENTRY_HEIGHT + self.theme.ENTRY_PADDING
	local entriesHeight = #self.visibleEntries * entryHeight
	self.scrollManagers.entries:updateContentHeight(entriesHeight)
	self.scrollManagers.entries:updateVisibleHeight(
		self.terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT
	)

	if self.currentlyViewingEntry then
		local entry = self.currentlyViewingEntry
		local detailsHeight = self.theme.HEADER_HEIGHT * 2

		if entry.content and entry.content ~= "" then
			local contentLines = TextWrapper.wrap(entry.content, self.terminal.displayWidth - 100, self.theme.FONT.BODY)
			detailsHeight = detailsHeight + (#contentLines * 20) + 40
		end

		if entry.audioFile and entry.audioFile ~= "" then
			detailsHeight = detailsHeight
				+ self.theme.CASSETTE.HEIGHT
				+ 40
				+ self.theme.AUDIO_CONTROLS.HEIGHT
				+ self.audioVisualizer.maxHeight
				+ 20
		end

		detailsHeight = detailsHeight + 60

		self.scrollManagers.details:updateContentHeight(detailsHeight)
		self.scrollManagers.details:updateVisibleHeight(
			self.terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT
		)
	end
end

function LoreModule:update()
	local currentTime = getTimeInMillis()

	for _, manager in pairs(self.scrollManagers) do
		manager:update(currentTime - (self.lastUpdateTime or currentTime))
	end

	self.lastUpdateTime = currentTime

	if self.cassetteAnim.isAnimating then
		local elapsed = currentTime - self.cassetteAnim.startTime
		local progress = elapsed / self.cassetteAnim.duration

		if self.cassetteAnim.direction == "in" then
			self.cassetteAnim.progress = math.min(1.0, progress)
			if progress >= 1.0 then
				self.cassetteAnim.isAnimating = false
				self.cassetteAnim.progress = 1.0

				if self.currentlyViewingEntry and self.currentlyViewingEntry.audioFile then
					self:playAudio(self.currentlyViewingEntry.audioFile)
				end
			end
		else
			self.cassetteAnim.progress = math.max(0.0, 1.0 - progress)
			if progress >= 1.0 then
				self.cassetteAnim.isAnimating = false
				self.cassetteAnim.progress = 0.0

				self:stopAudio()
			end
		end
	end

	if self.isPlayingAudio and currentTime - self.audioVisualizer.lastUpdateTime > self.audioVisualizer.updateRate then
		self:updateAudioVisualizer()
		self.audioVisualizer.lastUpdateTime = currentTime
	end
end

function LoreModule:updateAudioVisualizer()
	if not self.isPlayingAudio then
		for i = 1, self.audioVisualizer.bars do
			self.audioVisualizer.values[i] = self.audioVisualizer.values[i] * 0.9
			if self.audioVisualizer.values[i] < 0.05 then
				self.audioVisualizer.values[i] = 0
			end
		end
		return
	end

	for i = 1, self.audioVisualizer.bars do
		local prevValue = self.audioVisualizer.values[i] or 0.5
		local targetValue = math.random() * 0.8 + 0.2

		local centerDist = math.abs(i - (self.audioVisualizer.bars / 2 + 0.5)) / (self.audioVisualizer.bars / 2)
		targetValue = targetValue * (1 - centerDist * 0.5)

		self.audioVisualizer.values[i] = prevValue + (targetValue - prevValue) * 0.3
	end
end

function LoreModule:onKeyPress(key)
	self.terminal:playRandomKeySound()

	if self.currentView == "categories" then
		return self:handleCategoryViewKeyPress(key)
	elseif self.currentView == "entries" then
		return self:handleEntryViewKeyPress(key)
	elseif self.currentView == "details" then
		return self:handleDetailViewKeyPress(key)
	end

	return false
end

function LoreModule:handleCategoryViewKeyPress(key)
	if key == Keyboard.KEY_UP then
		self.selectedCategory = math.max(1, self.selectedCategory - 1)
		self:ensureCategoryVisible()
		return true
	elseif key == Keyboard.KEY_DOWN then
		self.selectedCategory = math.min(#self.categories, self.selectedCategory + 1)
		self:ensureCategoryVisible()
		return true
	elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
		self.currentView = "entries"
		self:updateVisibleEntries()
		return true
	end

	return false
end

function LoreModule:handleEntryViewKeyPress(key)
	if key == Keyboard.KEY_UP then
		self.selectedEntry = math.max(1, self.selectedEntry - 1)
		self:ensureEntryVisible()
		return true
	elseif key == Keyboard.KEY_DOWN then
		self.selectedEntry = math.min(#self.visibleEntries, self.selectedEntry + 1)
		self:ensureEntryVisible()
		return true
	elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
		if #self.visibleEntries > 0 and self.selectedEntry <= #self.visibleEntries then
			local entryInfo = self.visibleEntries[self.selectedEntry]
			if entryInfo and entryInfo.entry then
				self.currentlyViewingEntry = entryInfo.entry
				self.currentView = "details"
				self.scrollManagers.details:scrollTo(0, false)
				self:updateScrollContentHeights()

				if self.currentlyViewingEntry.requiresCassette and self.currentlyViewingEntry.audioFile then
					self:startCassetteAnimation("in")
					TerminalSounds.playUISound("sfx_knoxnet_lore_cassette_insert")
				end

				return true
			end
		end
	elseif key == Keyboard.KEY_BACK then
		self.currentView = "categories"
		return true
	end

	return false
end

function LoreModule:handleDetailViewKeyPress(key)
	if key == Keyboard.KEY_UP then
		self.scrollManagers.details:scrollUp(20)
		return true
	elseif key == Keyboard.KEY_DOWN then
		self.scrollManagers.details:scrollDown(20)
		return true
	elseif key == Keyboard.KEY_SPACE then
		if self.currentlyViewingEntry and self.currentlyViewingEntry.audioFile then
			if self.isPlayingAudio then
				self:pauseAudio()
			else
				self:playAudio(self.currentlyViewingEntry.audioFile)
			end
			return true
		end
	elseif key == Keyboard.KEY_BACK then
		if self.isPlayingAudio or self.cassetteAnim.isAnimating then
			self:stopAudio()

			if self.cassetteAnim.progress > 0 then
				self:startCassetteAnimation("out")
				TerminalSounds.playUISound("sfx_knoxnet_lore_cassette_eject")
			else
				self.currentView = "entries"
				self.currentlyViewingEntry = nil
			end
		else
			self.currentView = "entries"
			self.currentlyViewingEntry = nil
		end
		return true
	end

	return false
end

function LoreModule:ensureCategoryVisible()
	local categoryHeight = self.theme.CATEGORY_HEIGHT + self.theme.CATEGORY_PADDING
	local categoryY = (self.selectedCategory - 1) * categoryHeight

	local visibleHeight = self.terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT
	local currentScroll = self.scrollManagers.categories:getScrollOffset()

	if categoryY < currentScroll then
		self.scrollManagers.categories:scrollTo(categoryY, true)
	elseif categoryY + categoryHeight > currentScroll + visibleHeight then
		self.scrollManagers.categories:scrollTo(categoryY - visibleHeight + categoryHeight, true)
	end
end

function LoreModule:ensureEntryVisible()
	local entryHeight = self.theme.ENTRY_HEIGHT + self.theme.ENTRY_PADDING
	local entryY = (self.selectedEntry - 1) * entryHeight

	local visibleHeight = self.terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT
	local currentScroll = self.scrollManagers.entries:getScrollOffset()

	if entryY < currentScroll then
		self.scrollManagers.entries:scrollTo(entryY, true)
	elseif entryY + entryHeight > currentScroll + visibleHeight then
		self.scrollManagers.entries:scrollTo(entryY - visibleHeight + entryHeight, true)
	end
end

function LoreModule:startCassetteAnimation(direction)
	self.cassetteAnim.isAnimating = true
	self.cassetteAnim.startTime = getTimeInMillis()
	self.cassetteAnim.direction = direction

	if direction == "in" then
		self.cassetteAnim.progress = 0.0
	else
		self.cassetteAnim.progress = 1.0
	end
end

function LoreModule:playAudio(audioFile)
	self:stopAudio()

	self.currentAudioId = AudioManager.playSound(audioFile)
	self.isPlayingAudio = true

	for i = 1, self.audioVisualizer.bars do
		self.audioVisualizer.values[i] = math.random() * 0.5
	end
end

function LoreModule:pauseAudio()
	if self.currentAudioId then
		AudioManager.setPitch(self.currentAudioId, 0) -- Pause by setting pitch to 0
	end
	self.isPlayingAudio = false
end

function LoreModule:stopAudio()
	if self.currentAudioId then
		AudioManager.stopSound(self.currentAudioId)
		self.currentAudioId = nil
	end
	self.isPlayingAudio = false
end

function LoreModule:onMouseWheel(delta)
	local scrollManager

	if self.currentView == "categories" then
		scrollManager = self.scrollManagers.categories
	elseif self.currentView == "entries" then
		scrollManager = self.scrollManagers.entries
	elseif self.currentView == "details" then
		scrollManager = self.scrollManagers.details
	end

	if scrollManager then
		local scrollAmount = math.abs(delta) * 3 * 20 -- 3x sensitivity
		if delta > 0 then
			scrollManager:scrollUp(scrollAmount)
		else
			scrollManager:scrollDown(scrollAmount)
		end
		return true
	end

	return false
end

function LoreModule:render()
	self.terminal:renderTitle("KNOX COUNTY LORE DATABASE")

	if self.currentView == "categories" then
		self:renderCategoriesView()
	elseif self.currentView == "entries" then
		self:renderEntriesView()
	elseif self.currentView == "details" then
		self:renderDetailView()
	end

	self:renderFooter()
end

function LoreModule:renderCategoriesView()
	local terminal = self.terminal
	local displayX = terminal.displayX
	local contentY = terminal.contentAreaY

	self:renderSectionHeader("Select Category", contentY)

	local scrollY = contentY + self.theme.HEADER_HEIGHT
	local scrollHeight = terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT

	terminal:clearStencilRect()
	terminal:setStencilRect(displayX, scrollY, terminal.displayWidth, scrollHeight)

	local categoryHeight = self.theme.CATEGORY_HEIGHT + self.theme.CATEGORY_PADDING
	local scrollOffset = self.scrollManagers.categories:getScrollOffset()
	local startIndex = math.floor(scrollOffset / categoryHeight) + 1
	local visibleCount = math.ceil(scrollHeight / categoryHeight) + 1
	local endIndex = math.min(startIndex + visibleCount, #self.categories)

	for i = startIndex, endIndex do
		local category = self.categories[i]
		local isSelected = (i == self.selectedCategory)

		local itemY = scrollY + (i - startIndex) * categoryHeight - (scrollOffset % categoryHeight)
		self:renderCategoryItem(category, itemY, isSelected)
	end

	terminal:clearStencilRect()

	if #self.categories > 0 then
		local scrollbarX = displayX
			+ terminal.displayWidth
			- TerminalConstants.LAYOUT.SCROLLBAR.WIDTH
			- TerminalConstants.LAYOUT.SCROLLBAR.PADDING
		self.scrollManagers.categories:renderScrollbar(terminal, scrollbarX, scrollY, scrollHeight)
	end
end

function LoreModule:renderEntriesView()
	local terminal = self.terminal
	local displayX = terminal.displayX
	local contentY = terminal.contentAreaY

	local category = self.categories[self.selectedCategory]
	if not category then
		return
	end

	self:renderSectionHeader(category.name, contentY)

	local scrollY = contentY + self.theme.HEADER_HEIGHT
	local scrollHeight = terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT

	terminal:clearStencilRect()
	terminal:setStencilRect(displayX, scrollY, terminal.displayWidth, scrollHeight)

	local entryHeight = self.theme.ENTRY_HEIGHT + self.theme.ENTRY_PADDING
	local scrollOffset = self.scrollManagers.entries:getScrollOffset()
	local startIndex = math.floor(scrollOffset / entryHeight) + 1
	local visibleCount = math.ceil(scrollHeight / entryHeight) + 1
	local endIndex = math.min(startIndex + visibleCount, #self.visibleEntries)

	if #self.visibleEntries == 0 then
		local noEntriesY = scrollY + scrollHeight / 2 - 10
		local noEntriesText = "No accessible entries found in this category."
		local noEntriesWidth = getTextManager():MeasureStringX(self.theme.FONT.BODY, noEntriesText)

		terminal:drawText(
			noEntriesText,
			displayX + (terminal.displayWidth - noEntriesWidth) / 2,
			noEntriesY,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			self.theme.FONT.BODY
		)

		local helpText = "Some entries may require finding cassette tapes in the world."
		local helpWidth = getTextManager():MeasureStringX(self.theme.FONT.SMALL, helpText)

		terminal:drawText(
			helpText,
			displayX + (terminal.displayWidth - helpWidth) / 2,
			noEntriesY + 30,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a * 0.7,
			self.theme.FONT.SMALL
		)
	else
		for i = startIndex, endIndex do
			local entryInfo = self.visibleEntries[i]
			local isSelected = (i == self.selectedEntry)

			if entryInfo and entryInfo.entry then
				local itemY = scrollY + (i - startIndex) * entryHeight - (scrollOffset % entryHeight)
				self:renderEntryItem(entryInfo.entry, itemY, isSelected)
			end
		end
	end

	terminal:clearStencilRect()

	if #self.visibleEntries > 0 then
		local scrollbarX = displayX
			+ terminal.displayWidth
			- TerminalConstants.LAYOUT.SCROLLBAR.WIDTH
			- TerminalConstants.LAYOUT.SCROLLBAR.PADDING
		self.scrollManagers.entries:renderScrollbar(terminal, scrollbarX, scrollY, scrollHeight)
	end
end

function LoreModule:renderDetailView()
	local terminal = self.terminal
	local displayX = terminal.displayX
	local contentY = terminal.contentAreaY

	if not self.currentlyViewingEntry then
		return
	end
	local entry = self.currentlyViewingEntry

	self:renderSectionHeader(entry.title, contentY)

	local scrollY = contentY + self.theme.HEADER_HEIGHT
	local scrollHeight = terminal.contentAreaHeight - self.theme.HEADER_HEIGHT - self.theme.FOOTER_HEIGHT

	terminal:clearStencilRect()
	terminal:setStencilRect(
		displayX,
		scrollY,
		terminal.displayWidth - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10,
		scrollHeight
	)

	local scrollOffset = self.scrollManagers.details:getScrollOffset()
	local currentY = scrollY - scrollOffset

	local padding = 20
	local contentX = displayX + padding
	local contentWidth = terminal.displayWidth - (padding * 2) - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10

	if entry.date and entry.date ~= "" then
		terminal:drawText(
			"Date: " .. entry.date,
			contentX,
			currentY + 10,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			self.theme.FONT.SUBTITLE
		)
		currentY = currentY + 30
	end

	if entry.audioFile and entry.audioFile ~= "" then
		currentY = self:renderAudioSection(entry, contentX, currentY, contentWidth)
	end

	if entry.content and entry.content ~= "" then
		currentY = currentY + 20

		local contentLines = TextWrapper.wrap(entry.content, contentWidth, self.theme.FONT.BODY)

		for _, line in ipairs(contentLines) do
			terminal:drawText(
				line,
				contentX,
				currentY,
				TerminalConstants.COLORS.TEXT.NORMAL.r,
				TerminalConstants.COLORS.TEXT.NORMAL.g,
				TerminalConstants.COLORS.TEXT.NORMAL.b,
				TerminalConstants.COLORS.TEXT.NORMAL.a,
				self.theme.FONT.BODY
			)
			currentY = currentY + 20
		end
	end

	terminal:clearStencilRect()

	local totalContentHeight = self.scrollManagers.details.contentHeight
	if totalContentHeight > scrollHeight then
		local scrollbarX = displayX
			+ terminal.displayWidth
			- TerminalConstants.LAYOUT.SCROLLBAR.WIDTH
			- TerminalConstants.LAYOUT.SCROLLBAR.PADDING
		self.scrollManagers.details:renderScrollbar(terminal, scrollbarX, scrollY, scrollHeight)
	end
end

function LoreModule:renderAudioSection(entry, x, y, width)
	local terminal = self.terminal

	local cassetteY = y + 10
	self:renderCassetteAnimation(x + width / 2 - self.theme.CASSETTE.WIDTH / 2, cassetteY)

	local currentY = cassetteY + self.theme.CASSETTE.HEIGHT + 20

	if self.cassetteAnim.progress >= 1.0 then
		terminal:drawText(
			"AUDIO PLAYBACK SYSTEM",
			x + width / 2 - getTextManager():MeasureStringX(self.theme.FONT.SUBTITLE, "AUDIO PLAYBACK SYSTEM") / 2,
			currentY,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.r,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.g,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.b,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.a,
			self.theme.FONT.SUBTITLE
		)
		currentY = currentY + 25

		terminal:drawRect(x, currentY, width, self.theme.AUDIO_CONTROLS.HEIGHT, 0.5, 0.1, 0.1, 0.15)

		terminal:drawRectBorder(x, currentY, width, self.theme.AUDIO_CONTROLS.HEIGHT, 0.7, 0.2, 0.3, 0.4)

		local buttonSize = self.theme.AUDIO_CONTROLS.BUTTON_SIZE
		local buttonX = x + 10
		local buttonY = currentY + (self.theme.AUDIO_CONTROLS.HEIGHT - buttonSize) / 2

		local playSymbol = self.isPlayingAudio and "II" or "▶"
		local buttonColor = self.isPlayingAudio and TerminalConstants.COLORS.BUTTON.SELECTED
			or TerminalConstants.COLORS.BUTTON.NORMAL

		terminal:drawRect(
			buttonX,
			buttonY,
			buttonSize,
			buttonSize,
			buttonColor.a,
			buttonColor.r,
			buttonColor.g,
			buttonColor.b
		)

		terminal:drawRectBorder(
			buttonX,
			buttonY,
			buttonSize,
			buttonSize,
			TerminalConstants.COLORS.BUTTON.BORDER.a,
			TerminalConstants.COLORS.BUTTON.BORDER.r,
			TerminalConstants.COLORS.BUTTON.BORDER.g,
			TerminalConstants.COLORS.BUTTON.BORDER.b
		)

		terminal:drawText(
			playSymbol,
			buttonX + buttonSize / 2 - getTextManager():MeasureStringX(self.theme.FONT.BODY, playSymbol) / 2,
			buttonY + buttonSize / 2 - getTextManager():MeasureStringY(self.theme.FONT.BODY, playSymbol) / 2,
			TerminalConstants.COLORS.TEXT.NORMAL.r,
			TerminalConstants.COLORS.TEXT.NORMAL.g,
			TerminalConstants.COLORS.TEXT.NORMAL.b,
			TerminalConstants.COLORS.TEXT.NORMAL.a,
			self.theme.FONT.BODY
		)

		local progressX = buttonX + buttonSize + 10
		local progressY = buttonY + buttonSize / 2 - self.theme.AUDIO_CONTROLS.PROGRESS_HEIGHT / 2
		local progressWidth = width - (progressX - x) - 10

		terminal:drawRect(
			progressX,
			progressY,
			progressWidth,
			self.theme.AUDIO_CONTROLS.PROGRESS_HEIGHT,
			TerminalConstants.COLORS.PROGRESS.BACKGROUND.a,
			TerminalConstants.COLORS.PROGRESS.BACKGROUND.r,
			TerminalConstants.COLORS.PROGRESS.BACKGROUND.g,
			TerminalConstants.COLORS.PROGRESS.BACKGROUND.b
		)

		local fakeProgress = 0.5
		terminal:drawRect(
			progressX,
			progressY,
			progressWidth * fakeProgress,
			self.theme.AUDIO_CONTROLS.PROGRESS_HEIGHT,
			TerminalConstants.COLORS.PROGRESS.FILL.a,
			TerminalConstants.COLORS.PROGRESS.FILL.r,
			TerminalConstants.COLORS.PROGRESS.FILL.g,
			TerminalConstants.COLORS.PROGRESS.FILL.b
		)

		terminal:drawRectBorder(
			progressX,
			progressY,
			progressWidth,
			self.theme.AUDIO_CONTROLS.PROGRESS_HEIGHT,
			TerminalConstants.COLORS.PROGRESS.BORDER.a,
			TerminalConstants.COLORS.PROGRESS.BORDER.r,
			TerminalConstants.COLORS.PROGRESS.BORDER.g,
			TerminalConstants.COLORS.PROGRESS.BORDER.b
		)

		currentY = currentY + self.theme.AUDIO_CONTROLS.HEIGHT + 10

		self:renderAudioVisualizer(x, currentY, width)
		currentY = currentY + self.audioVisualizer.maxHeight + 10
	end

	return currentY
end

function LoreModule:renderAudioVisualizer(x, y, width)
	local terminal = self.terminal

	terminal:drawRect(x, y, width, self.audioVisualizer.maxHeight, 0.3, 0.05, 0.05, 0.1)

	terminal:drawRectBorder(x, y, width, self.audioVisualizer.maxHeight, 0.4, 0.15, 0.25, 0.35)

	local barCount = self.audioVisualizer.bars
	local barWidth = width / barCount
	local padding = barWidth * 0.1

	for i = 1, barCount do
		local value = self.audioVisualizer.values[i] or 0
		local barHeight = value * self.audioVisualizer.maxHeight

		if barHeight > 0 then
			local barX = x + (i - 1) * barWidth + padding / 2
			local barY = y + self.audioVisualizer.maxHeight - barHeight
			local finalBarWidth = barWidth - padding

			local r, g, b
			if self.rainbowMode then
				local hue = (self.rainbowHue + (i / barCount)) % 1.0
				r, g, b = ColorUtils.hslToRgb(hue, 0.8, 0.5)
			else
				local intensity = value
				g = 0.3 + 0.7 * (1 - intensity)
				r = 0.3 + 0.7 * intensity
				b = 0.3
			end

			terminal:drawRect(barX, barY, finalBarWidth, barHeight, 0.7, r, g, b)
		end
	end
end

function LoreModule:renderCassetteAnimation(x, y)
	local terminal = self.terminal
	local progress = self.cassetteAnim.progress

	local offsetX = 0
	if self.cassetteAnim.direction == "in" then
		offsetX = (1.0 - progress) * (terminal.displayWidth / 2)
	else
		offsetX = progress * (terminal.displayWidth / 2)
	end

	local cassetteX = x + offsetX
	local cassetteWidth = self.theme.CASSETTE.WIDTH
	local cassetteHeight = self.theme.CASSETTE.HEIGHT

	terminal:drawRect(cassetteX, y, cassetteWidth, cassetteHeight, 0.9, 0.2, 0.2, 0.2)

	terminal:drawRectBorder(cassetteX, y, cassetteWidth, cassetteHeight, 0.9, 0.4, 0.4, 0.4)

	local reelRadius = cassetteHeight * 0.25
	local reelY = y + cassetteHeight * 0.5
	local leftReelX = cassetteX + cassetteWidth * 0.25
	local rightReelX = cassetteX + cassetteWidth * 0.75

	terminal:drawRect(leftReelX - reelRadius, reelY - reelRadius, reelRadius * 2, reelRadius * 2, 0.8, 0.1, 0.1, 0.1)

	terminal:drawRect(
		leftReelX - reelRadius * 0.8,
		reelY - reelRadius * 0.8,
		reelRadius * 1.6,
		reelRadius * 1.6,
		0.8,
		0.3,
		0.3,
		0.3
	)

	terminal:drawRect(
		leftReelX - reelRadius * 0.2,
		reelY - reelRadius * 0.2,
		reelRadius * 0.4,
		reelRadius * 0.4,
		0.9,
		0.15,
		0.15,
		0.15
	)

	terminal:drawRect(rightReelX - reelRadius, reelY - reelRadius, reelRadius * 2, reelRadius * 2, 0.8, 0.1, 0.1, 0.1)

	terminal:drawRect(
		rightReelX - reelRadius * 0.6,
		reelY - reelRadius * 0.6,
		reelRadius * 1.2,
		reelRadius * 1.2,
		0.8,
		0.3,
		0.3,
		0.3
	)

	terminal:drawRect(
		rightReelX - reelRadius * 0.2,
		reelY - reelRadius * 0.2,
		reelRadius * 0.4,
		reelRadius * 0.4,
		0.9,
		0.15,
		0.15,
		0.15
	)

	terminal:drawRect(
		cassetteX + cassetteWidth * 0.15,
		y + cassetteHeight * 0.2,
		cassetteWidth * 0.7,
		cassetteHeight * 0.2,
		0.8,
		0.9,
		0.9,
		0.9
	)

	if self.currentlyViewingEntry and self.currentlyViewingEntry.title then
		local labelText = self.currentlyViewingEntry.title
		if #labelText > 15 then
			labelText = string.sub(labelText, 1, 13) .. ".."
		end

		terminal:drawText(
			labelText,
			cassetteX + cassetteWidth * 0.5 - getTextManager():MeasureStringX(self.theme.FONT.LABEL, labelText) / 2,
			y + cassetteHeight * 0.2 + 2,
			0.1,
			0.1,
			0.1,
			0.9,
			self.theme.FONT.LABEL
		)
	end
end

function LoreModule:renderSectionHeader(title, y)
	local terminal = self.terminal
	local displayX = terminal.displayX
	local displayWidth = terminal.displayWidth

	terminal:drawRect(
		displayX,
		y,
		displayWidth,
		self.theme.HEADER_HEIGHT,
		TerminalConstants.COLORS.HEADER.BACKGROUND.a,
		TerminalConstants.COLORS.HEADER.BACKGROUND.r,
		TerminalConstants.COLORS.HEADER.BACKGROUND.g,
		TerminalConstants.COLORS.HEADER.BACKGROUND.b
	)

	terminal:drawRect(
		displayX,
		y + self.theme.HEADER_HEIGHT - 1,
		displayWidth,
		1,
		TerminalConstants.COLORS.HEADER.BORDER.a,
		TerminalConstants.COLORS.HEADER.BORDER.r,
		TerminalConstants.COLORS.HEADER.BORDER.g,
		TerminalConstants.COLORS.HEADER.BORDER.b
	)

	local titleX = displayX + 20
	local titleY = y + (self.theme.HEADER_HEIGHT - getTextManager():MeasureStringY(self.theme.FONT.TITLE, title)) / 2

	terminal:drawText(
		title,
		titleX,
		titleY,
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		self.theme.FONT.TITLE
	)
end

function LoreModule:renderCategoryItem(category, y, isSelected)
	local terminal = self.terminal
	local displayX = terminal.displayX
	local displayWidth = terminal.displayWidth
	local padding = 20

	local bgColor = isSelected and TerminalConstants.COLORS.BUTTON.SELECTED
		or TerminalConstants.COLORS.BUTTON.BACKGROUND
	terminal:drawRect(
		displayX + padding,
		y,
		displayWidth - (padding * 2) - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10,
		self.theme.CATEGORY_HEIGHT,
		bgColor.a,
		bgColor.r,
		bgColor.g,
		bgColor.b
	)

	terminal:drawRectBorder(
		displayX + padding,
		y,
		displayWidth - (padding * 2) - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10,
		self.theme.CATEGORY_HEIGHT,
		TerminalConstants.COLORS.BUTTON.BORDER.a,
		TerminalConstants.COLORS.BUTTON.BORDER.r,
		TerminalConstants.COLORS.BUTTON.BORDER.g,
		TerminalConstants.COLORS.BUTTON.BORDER.b
	)

	local textX = displayX + padding + 10
	local textY = y
		+ (self.theme.CATEGORY_HEIGHT - getTextManager():MeasureStringY(self.theme.FONT.BODY, category.name)) / 2

	terminal:drawText(
		category.name,
		textX,
		textY,
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		self.theme.FONT.BODY
	)

	local entryCount = "Entries: " .. (category.entries and #category.entries or 0)
	local countWidth = getTextManager():MeasureStringX(self.theme.FONT.SUBTITLE, entryCount)

	terminal:drawText(
		entryCount,
		displayX + displayWidth - padding - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 20 - countWidth,
		textY,
		TerminalConstants.COLORS.TEXT.DIM.r,
		TerminalConstants.COLORS.TEXT.DIM.g,
		TerminalConstants.COLORS.TEXT.DIM.b,
		TerminalConstants.COLORS.TEXT.DIM.a,
		self.theme.FONT.SUBTITLE
	)
end

function LoreModule:renderEntryItem(entry, y, isSelected)
	local terminal = self.terminal
	local displayX = terminal.displayX
	local displayWidth = terminal.displayWidth
	local padding = 20

	local bgColor = isSelected and TerminalConstants.COLORS.BUTTON.SELECTED
		or TerminalConstants.COLORS.BUTTON.BACKGROUND
	terminal:drawRect(
		displayX + padding,
		y,
		displayWidth - (padding * 2) - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10,
		self.theme.ENTRY_HEIGHT,
		bgColor.a,
		bgColor.r,
		bgColor.g,
		bgColor.b
	)

	terminal:drawRectBorder(
		displayX + padding,
		y,
		displayWidth - (padding * 2) - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 10,
		self.theme.ENTRY_HEIGHT,
		TerminalConstants.COLORS.BUTTON.BORDER.a,
		TerminalConstants.COLORS.BUTTON.BORDER.r,
		TerminalConstants.COLORS.BUTTON.BORDER.g,
		TerminalConstants.COLORS.BUTTON.BORDER.b
	)

	local textX = displayX + padding + 10
	local textY = y + 10

	terminal:drawText(
		entry.title,
		textX,
		textY,
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		self.theme.FONT.BODY
	)

	if entry.date and entry.date ~= "" then
		terminal:drawText(
			"Date: " .. entry.date,
			textX,
			textY + 25,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			self.theme.FONT.SUBTITLE
		)
	end

	if entry.content and entry.content ~= "" then
		local previewText = entry.content
		if #previewText > 50 then
			previewText = string.sub(previewText, 1, 50) .. "..."
		end

		terminal:drawText(
			previewText,
			textX,
			textY + 45,
			TerminalConstants.COLORS.TEXT.DIM.r,
			TerminalConstants.COLORS.TEXT.DIM.g,
			TerminalConstants.COLORS.TEXT.DIM.b,
			TerminalConstants.COLORS.TEXT.DIM.a,
			self.theme.FONT.SUBTITLE
		)
	end

	if entry.audioFile and entry.audioFile ~= "" then
		local iconWidth = 30
		local iconHeight = 20
		local iconX = displayX + displayWidth - padding - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH - 20 - iconWidth
		local iconY = y + 10

		terminal:drawRect(iconX, iconY, iconWidth, iconHeight, 0.7, 0.2, 0.2, 0.2)

		terminal:drawRectBorder(iconX, iconY, iconWidth, iconHeight, 0.8, 0.4, 0.4, 0.4)

		local reelSize = 4
		terminal:drawRect(iconX + 7, iconY + 8, reelSize, reelSize, 0.7, 0.3, 0.3, 0.3)
		terminal:drawRect(iconX + 19, iconY + 8, reelSize, reelSize, 0.7, 0.3, 0.3, 0.3)

		terminal:drawText(
			"AUDIO",
			iconX - 40,
			iconY + 3,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.r,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.g,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.b,
			TerminalConstants.COLORS.TEXT.HIGHLIGHT.a,
			self.theme.FONT.LABEL
		)
	end
end

function LoreModule:renderFooter()
	local terminal = self.terminal
	local helpText = ""

	if self.currentView == "categories" then
		helpText = "UP/DOWN - Navigate | SPACE - Select Category | BACKSPACE - Exit"
	elseif self.currentView == "entries" then
		helpText = "UP/DOWN - Navigate | SPACE - View Entry | BACKSPACE - Back to Categories"
	elseif self.currentView == "details" then
		if self.currentlyViewingEntry and self.currentlyViewingEntry.audioFile then
			helpText = "UP/DOWN - Scroll | SPACE - Play/Pause Audio | BACKSPACE - Back to Entries"
		else
			helpText = "UP/DOWN - Scroll | BACKSPACE - Back to Entries"
		end
	end

	terminal:renderFooter(helpText)
end

function LoreModule:onMouseDown(x, y)
	return false
end
return LoreModule
