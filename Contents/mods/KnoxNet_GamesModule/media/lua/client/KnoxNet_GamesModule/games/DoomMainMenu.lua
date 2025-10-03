local Constants = require("KnoxNet_GamesModule/core/Constants")
local GameMainMenu = require("KnoxNet_GamesModule/core/GameMainMenu")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local DoomMainMenu = GameMainMenu:new()

local DOOM_DIFFICULTIES = {
	{ id = "easy", name = "I'm Too Young to Die", enemyHealth = 0.7, enemyDamage = 0.7, enemySpeed = 0.8 },
	{ id = "normal", name = "Hurt Me Plenty", enemyHealth = 1.0, enemyDamage = 1.0, enemySpeed = 1.0 },
	{ id = "hard", name = "Ultra-Violence", enemyHealth = 1.3, enemyDamage = 1.3, enemySpeed = 1.2 },
	{ id = "nightmare", name = "Nightmare!", enemyHealth = 1.5, enemyDamage = 1.5, enemySpeed = 1.4 },
}

function DoomMainMenu:addGameSpecificOptions()
	self:addMenuOption({
		id = "difficulty",
		type = "button",
		text = "Difficulty: Hurt Me Plenty",
		action = function(self, gamesModule)
			self:cycleDifficulty()
		end,
		enabled = true,
	})

	self:addMenuOption({
		id = "high_scores",
		type = "button",
		text = "High Scores",
		action = function(self, gamesModule)
			self:showHighScores(gamesModule)
		end,
		enabled = true,
	})

	self:addMenuOption({
		id = "credits",
		type = "button",
		text = "Credits",
		action = function(self, gamesModule)
			self:showCredits(gamesModule)
		end,
		enabled = true,
	})
end

function DoomMainMenu:initializeSettings()
	self.settings = {
		difficulty = "normal",
	}

	self:updateDifficultyText()
end

function DoomMainMenu:updateDifficultyText()
	for i, option in ipairs(self.menuOptions) do
		if option.id == "difficulty" then
			option.text = "Difficulty: " .. self:getDifficultyName()
			break
		end
	end
end

function DoomMainMenu:getDifficultyName()
	for _, diff in ipairs(DOOM_DIFFICULTIES) do
		if diff.id == self.settings.difficulty then
			return diff.name
		end
	end
	return "Hurt Me Plenty"
end

function DoomMainMenu:cycleDifficulty()
	local currentIndex = 1
	for i, diff in ipairs(DOOM_DIFFICULTIES) do
		if diff.id == self.settings.difficulty then
			currentIndex = i
			break
		end
	end

	local nextIndex = currentIndex % #DOOM_DIFFICULTIES + 1
	self.settings.difficulty = DOOM_DIFFICULTIES[nextIndex].id
	self:updateDifficultyText()

	TerminalSounds.playUISound("sfx_knoxnet_key_2")
end

function DoomMainMenu:startNewGame(gamesModule)
	if self.gameInstance and self.gameInstance.setDifficulty then
		self.gameInstance:setDifficulty(self.settings.difficulty)
	end

	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
	gamesModule:startGame(self.gameInstance)
end

function DoomMainMenu:showHighScores(gamesModule)
	self.menuState = "high_scores"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function DoomMainMenu:showCredits(gamesModule)
	self.menuState = "credits"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function DoomMainMenu:render()
	if self.menuState == "main" then
		self:renderMainMenu()
	elseif self.menuState == "high_scores" then
		self:renderHighScores()
	elseif self.menuState == "credits" then
		self:renderCredits()
	end
end

function DoomMainMenu:renderHighScores()
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

	local centerX = self.terminal.displayX + self.terminal.displayWidth / 2
	local startY = self.terminal.contentAreaY
	local lineHeight = 30

	local title = "DOOM HIGH SCORES"
	local titleWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, title)
	self.terminal:drawText(
		title,
		centerX - titleWidth / 2,
		startY,
		termColors.TEXT.NORMAL.r,
		termColors.TEXT.NORMAL.g,
		termColors.TEXT.NORMAL.b,
		termColors.TEXT.NORMAL.a,
		Constants.UI_CONST.FONT.LARGE
	)

	local scores = {
		{ name = "DOOMGUY", score = 15000, level = 5 },
		{ name = "MARINE", score = 12000, level = 4 },
		{ name = "SOLDIER", score = 9000, level = 3 },
		{ name = "NEWBIE", score = 6000, level = 2 },
		{ name = "NOOB", score = 3000, level = 1 },
	}

	for i, scoreData in ipairs(scores) do
		local scoreText = string.format("%d. %s - %d (Level %d)", i, scoreData.name, scoreData.score, scoreData.level)
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, scoreText)
		local textY = startY + 80 + (i - 1) * lineHeight

		self.terminal:drawText(
			scoreText,
			centerX - textWidth / 2,
			textY,
			termColors.TEXT.NORMAL.r,
			termColors.TEXT.NORMAL.g,
			termColors.TEXT.NORMAL.b,
			termColors.TEXT.NORMAL.a,
			Constants.UI_CONST.FONT.MEDIUM
		)
	end

	self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU")
end

function DoomMainMenu:renderCredits()
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

	local centerX = self.terminal.displayX + self.terminal.displayWidth / 2
	local startY = self.terminal.contentAreaY
	local lineHeight = 30

	local title = "CREDITS"
	local titleWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, title)
	self.terminal:drawText(
		title,
		centerX - titleWidth / 2,
		startY,
		termColors.TEXT.NORMAL.r,
		termColors.TEXT.NORMAL.g,
		termColors.TEXT.NORMAL.b,
		termColors.TEXT.NORMAL.a,
		Constants.UI_CONST.FONT.LARGE
	)

	local credits = {
		"Game Design: Elyon",
		"Programming: Elyon",
		"Graphics: Retro Style",
		"Sound Effects: Classic DOOM",
		"Special Thanks: id Software",
		"Inspired by: DOOM (1993)",
	}

	for i, credit in ipairs(credits) do
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, credit)
		local textY = startY + 80 + (i - 1) * lineHeight

		self.terminal:drawText(
			credit,
			centerX - textWidth / 2,
			textY,
			termColors.TEXT.NORMAL.r,
			termColors.TEXT.NORMAL.g,
			termColors.TEXT.NORMAL.b,
			termColors.TEXT.NORMAL.a,
			Constants.UI_CONST.FONT.MEDIUM
		)
	end

	self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU")
end

function DoomMainMenu:onKeyPress(key)
	if self.menuState == "high_scores" or self.menuState == "credits" then
		if key == Keyboard.KEY_BACK then
			self.menuState = "main"
			TerminalSounds.playUISound("sfx_knoxnet_key_3")
			return true
		end
		return false
	end

	return GameMainMenu.onKeyPress(self, key)
end

return DoomMainMenu
