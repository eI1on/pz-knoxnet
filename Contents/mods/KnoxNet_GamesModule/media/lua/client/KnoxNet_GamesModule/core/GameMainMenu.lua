local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local ScrollManager = require("KnoxNet/ui/ScrollManager")

local GameMainMenu = {}

local MENU_OPTION_TYPES = {
	BUTTON = "button",
	SEPARATOR = "separator",
}

local DEFAULT_MENU_OPTIONS = {
	{
		id = "new_game",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "New Game",
		action = function(self, gamesModule)
			self:startNewGame(gamesModule)
		end,
		enabled = true,
	},
	{
		id = "separator_1",
		type = MENU_OPTION_TYPES.SEPARATOR,
	},
	{
		id = "back_to_games",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "Back to Games",
		action = function(self, gamesModule)
			gamesModule:onActivate()
		end,
		enabled = true,
	},
	{
		id = "quit_to_terminal",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "Quit to Terminal",
		action = function(self, gamesModule)
			gamesModule.terminal:changeState("mainMenu")
		end,
		enabled = true,
	},
}

function GameMainMenu:new(gameInstance, gameInfo)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.gameInstance = gameInstance
	o.gameInfo = gameInfo
	o.menuOptions = table.newarray() --[[@as table]]
	o.selectedOption = 1
	o.menuState = "main" -- main, high_scores, credits, etc.
	o.terminal = nil
	o.gamesModule = nil

	o.scrollManager = nil
	o.optionHeight = 40
	o.optionSpacing = 10
	o.optionWidth = 300

	o:initializeDefaultOptions()

	return o
end

function GameMainMenu:initializeDefaultOptions()
	for i = 1, #DEFAULT_MENU_OPTIONS do
		local newOption = {}
		for k, v in pairs(DEFAULT_MENU_OPTIONS[i]) do
			newOption[k] = v
		end
		table.insert(self.menuOptions, newOption)
	end

	self:addGameSpecificOptions()
	self:initializeScrollManager()
end

function GameMainMenu:initializeScrollManager()
	local totalHeight = #self.menuOptions * (self.optionHeight + self.optionSpacing) - self.optionSpacing
	local visibleHeight = (self.terminal and self.terminal.contentAreaHeight) or 400

	self.scrollManager = ScrollManager:new(totalHeight, visibleHeight)
end

function GameMainMenu:addGameSpecificOptions() end

function GameMainMenu:addMenuOption(option)
	local separatorIndex = nil
	for i = 1, #self.menuOptions do
		if self.menuOptions[i].type == MENU_OPTION_TYPES.SEPARATOR then
			separatorIndex = i
			break
		end
	end

	if separatorIndex then
		table.insert(self.menuOptions, separatorIndex, option)
	else
		table.insert(self.menuOptions, option)
	end

	if self.scrollManager then
		local totalHeight = #self.menuOptions * (self.optionHeight + self.optionSpacing) - self.optionSpacing
		self.scrollManager:updateContentHeight(totalHeight)
	end
end

function GameMainMenu:activate(gamesModule)
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal
	self.selectedOption = 1
	self.menuState = "main"

	if self.scrollManager then
		local visibleHeight = self.terminal.contentAreaHeight
		self.scrollManager:updateVisibleHeight(visibleHeight)
	end

	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function GameMainMenu:onKeyPress(key)
	if self.menuState == "main" then
		return self:handleMainMenuKeyPress(key)
	elseif self.menuState == "high_scores" then
		return self:handleHighScoresKeyPress(key)
	elseif self.menuState == "credits" then
		return self:handleCreditsKeyPress(key)
	end
	return false
end

function GameMainMenu:handleMainMenuKeyPress(key)
	if key == Keyboard.KEY_UP then
		self:selectPreviousOption()
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_DOWN then
		self:selectNextOption()
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_ENTER then
		self:executeSelectedOption()
		return true
	elseif key == Keyboard.KEY_BACK then
		self.gamesModule:onActivate()
		TerminalSounds.playUISound("sfx_knoxnet_key_3")
		return true
	end
	return false
end

function GameMainMenu:handleHighScoresKeyPress(key)
	if key == Keyboard.KEY_BACK then
		self.menuState = "main"
		TerminalSounds.playUISound("sfx_knoxnet_key_3")
		return true
	end
	return false
end

function GameMainMenu:handleCreditsKeyPress(key)
	if key == Keyboard.KEY_BACK then
		self.menuState = "main"
		TerminalSounds.playUISound("sfx_knoxnet_key_3")
		return true
	end
	return false
end

function GameMainMenu:selectPreviousOption()
	local enabledOptions = self:getEnabledOptions()
	if #enabledOptions == 0 then
		return
	end

	local currentIndex = self:getCurrentOptionIndex()
	local newIndex = currentIndex - 1
	if newIndex < 1 then
		newIndex = #enabledOptions
	end

	self.selectedOption = enabledOptions[newIndex]
	self:ensureOptionVisible()
end

function GameMainMenu:selectNextOption()
	local enabledOptions = self:getEnabledOptions()
	if #enabledOptions == 0 then
		return
	end

	local currentIndex = self:getCurrentOptionIndex()
	local newIndex = currentIndex + 1
	if newIndex > #enabledOptions then
		newIndex = 1
	end

	self.selectedOption = enabledOptions[newIndex]
	self:ensureOptionVisible()
end

function GameMainMenu:ensureOptionVisible()
	if not self.scrollManager then
		return
	end

	local optionIndex = self.selectedOption
	local optionY = (optionIndex - 1) * (self.optionHeight + self.optionSpacing)
	local visibleHeight = self.scrollManager.visibleHeight

	if optionY < self.scrollManager.scrollOffset then
		self.scrollManager:scrollTo(optionY, true)
	elseif optionY + self.optionHeight > self.scrollManager.scrollOffset + visibleHeight then
		self.scrollManager:scrollTo(optionY + self.optionHeight - visibleHeight, true)
	end
end

function GameMainMenu:getEnabledOptions()
	local enabled = table.newarray() --[[@as table]]
	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		if option.type ~= MENU_OPTION_TYPES.SEPARATOR and option.enabled then
			table.insert(enabled, i)
		end
	end
	return enabled
end

function GameMainMenu:getCurrentOptionIndex()
	local enabledOptions = self:getEnabledOptions()
	for i = 1, #enabledOptions do
		if enabledOptions[i] == self.selectedOption then
			return i
		end
	end
	return 1
end

function GameMainMenu:executeSelectedOption()
	local option = self.menuOptions[self.selectedOption]
	if option and option.action and option.enabled then
		option.action(self, self.gamesModule)
	end
end

function GameMainMenu:onMouseUp(x, y)
	if self.menuState ~= "main" then
		return false
	end

	local menuX = self.terminal.displayX + 25
	local menuY = self.terminal.contentAreaY + 25

	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		if option.type ~= MENU_OPTION_TYPES.SEPARATOR and option.enabled then
			local optionY = menuY + (i - 1) * (self.optionHeight + self.optionSpacing)
			local adjustedY = optionY - (self.scrollManager and self.scrollManager.scrollOffset or 0)

			if
				x >= menuX
				and x <= menuX + self.optionWidth
				and y >= adjustedY
				and y <= adjustedY + self.optionHeight
			then
				self.selectedOption = i
				self:executeSelectedOption()
				return true
			end
		end
	end

	return false
end

function GameMainMenu:onMouseWheel(delta)
	if self.scrollManager then
		self.scrollManager:onMouseWheel(delta)
		return true
	end
	return false
end

function GameMainMenu:update()
	if self.scrollManager then
		self.scrollManager:update(16.67) -- Assume 60 FPS
	end
end

function GameMainMenu:render()
	if self.menuState == "main" then
		self:renderMainMenu()
	elseif self.menuState == "high_scores" then
		self:renderHighScores()
	elseif self.menuState == "credits" then
		self:renderCredits()
	end
end

function GameMainMenu:renderMainMenu()
	self.terminal:renderTitle(self.gameInfo.name .. " - Main Menu")

	local termColors = Constants.UI_CONST.COLORS
	self.terminal:drawRect(
		self.terminal.displayX,
		self.terminal.contentAreaY,
		self.terminal.displayWidth,
		self.terminal.contentAreaHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)

	local menuX = self.terminal.displayX + 25
	local menuY = self.terminal.contentAreaY + 25
	local scrollOffset = self.scrollManager and self.scrollManager.scrollOffset or 0

	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		local optionY = menuY + (i - 1) * (self.optionHeight + self.optionSpacing)
		local visibleY = optionY - scrollOffset

		if visibleY + self.optionHeight > menuY and visibleY < menuY + self.terminal.contentAreaHeight then
			if option.type == MENU_OPTION_TYPES.SEPARATOR then
				local separatorY = visibleY + self.optionHeight / 2
				self.terminal:drawRect(
					menuX,
					separatorY,
					self.optionWidth,
					2,
					termColors.BORDER.a,
					termColors.BORDER.r,
					termColors.BORDER.g,
					termColors.BORDER.b
				)
			else
				local isSelected = (i == self.selectedOption)
				local isEnabled = option.enabled

				local bgColor = isSelected and termColors.BUTTON.HOVER or termColors.BUTTON.COLOR
				local borderColor = isSelected and termColors.BUTTON.BORDER or termColors.BORDER
				local textColor = isEnabled and termColors.TEXT.NORMAL or termColors.TEXT.DIM

				if isEnabled then
					self.terminal:drawRect(
						menuX,
						visibleY,
						self.optionWidth,
						self.optionHeight,
						bgColor.a,
						bgColor.r,
						bgColor.g,
						bgColor.b
					)
				end

				self.terminal:drawRectBorder(
					menuX,
					visibleY,
					self.optionWidth,
					self.optionHeight,
					borderColor.a,
					borderColor.r,
					borderColor.g,
					borderColor.b
				)

				local textX = menuX + 15
				local textY = visibleY + (self.optionHeight - 15) / 2

				self.terminal:drawText(
					option.text,
					textX,
					textY,
					textColor.r,
					textColor.g,
					textColor.b,
					textColor.a,
					Constants.UI_CONST.FONT.CODE
				)
			end
		end
	end

	if self.scrollManager and self.scrollManager.contentHeight > self.scrollManager.visibleHeight then
		local scrollbarX = self.terminal.displayX + self.terminal.displayWidth - 20
		local scrollbarY = self.terminal.contentAreaY + 25
		local scrollbarHeight = self.terminal.contentAreaHeight

		self.scrollManager:renderScrollbar(self.terminal, scrollbarX, scrollbarY, scrollbarHeight)
	end

	self.terminal:renderFooter("ARROWS - NAVIGATE | SPACE/ENTER - SELECT | BACKSPACE - BACK")
end

function GameMainMenu:renderHighScores()
	self.terminal:renderTitle(self.gameInfo.name .. " - High Scores")

	local termColors = Constants.UI_CONST.COLORS
	self.terminal:drawRect(
		self.terminal.displayX,
		self.terminal.contentAreaY,
		self.terminal.displayWidth,
		self.terminal.contentAreaHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)

	local message = "High Scores not implemented for this game"
	local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, message)
	local textX = self.terminal.displayX + (self.terminal.displayWidth - textWidth) / 2
	local textY = self.terminal.contentAreaY + self.terminal.contentAreaHeight / 2

	self.terminal:drawText(
		message,
		textX,
		textY,
		termColors.TEXT.NORMAL.r,
		termColors.TEXT.NORMAL.g,
		termColors.TEXT.NORMAL.b,
		termColors.TEXT.NORMAL.a,
		Constants.UI_CONST.FONT.MEDIUM
	)

	self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU")
end

function GameMainMenu:renderCredits()
	self.terminal:renderTitle(self.gameInfo.name .. " - Credits")

	local termColors = Constants.UI_CONST.COLORS
	self.terminal:drawRect(
		self.terminal.displayX,
		self.terminal.contentAreaY,
		self.terminal.displayWidth,
		self.terminal.contentAreaHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)

	local message = "Credits not implemented for this game"
	local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, message)
	local textX = self.terminal.displayX + (self.terminal.displayWidth - textWidth) / 2
	local textY = self.terminal.contentAreaY + self.terminal.contentAreaHeight / 2

	self.terminal:drawText(
		message,
		textX,
		textY,
		termColors.TEXT.NORMAL.r,
		termColors.TEXT.NORMAL.g,
		termColors.TEXT.NORMAL.b,
		termColors.TEXT.NORMAL.a,
		Constants.UI_CONST.FONT.MEDIUM
	)

	self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU")
end

function GameMainMenu:startNewGame(gamesModule)
	if self.gameInstance and self.gameInstance.startNewGame then
		self.gameInstance:startNewGame(gamesModule)
	else
		gamesModule:startGame(self.gameInstance)
	end
end

return GameMainMenu
