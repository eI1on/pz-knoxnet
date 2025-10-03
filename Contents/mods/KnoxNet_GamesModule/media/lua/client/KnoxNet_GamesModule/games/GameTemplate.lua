local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local GameMainMenu = require("KnoxNet_GamesModule/core/GameMainMenu")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local GameTemplate = {}

local GameTemplateMainMenu = GameMainMenu:new()

function GameTemplateMainMenu:addGameSpecificOptions()
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
		id = "instructions",
		type = "button",
		text = "How to Play",
		action = function(self, gamesModule)
			self:showInstructions(gamesModule)
		end,
		enabled = true,
	})
end

function GameTemplateMainMenu:startNewGame(gamesModule)
	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
	gamesModule:startGame(self.gameInstance)
end

function GameTemplateMainMenu:render()
	if self.menuState == "main" then
		self:renderMainMenu()
	elseif self.menuState == "high_scores" then
		self:renderHighScores()
	elseif self.menuState == "instructions" then
		self:renderInstructions()
	end
end

function GameTemplateMainMenu:renderHighScores()
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
	local startY = self.terminal.contentAreaY + 100
	local lineHeight = 30

	local title = "HIGH SCORES"
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
		{ name = "PLAYER_1", score = 1000, level = 3 },
		{ name = "PLAYER_2", score = 800, level = 2 },
		{ name = "PLAYER_3", score = 600, level = 2 },
		{ name = "PLAYER_4", score = 400, level = 1 },
		{ name = "PLAYER_5", score = 200, level = 1 },
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

function GameTemplateMainMenu:renderInstructions()
	self.terminal:renderTitle(self.gameInfo.name .. " - How to Play")

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
	local startY = self.terminal.contentAreaY + 80
	local lineHeight = 25

	local title = "HOW TO PLAY"
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

	local instructions = {
		"OBJECTIVE:",
		"Complete the game objectives to win.",
		"",
		"CONTROLS:",
		"Arrow Keys - Move/Navigate",
		"Space - Action/Select",
		"Backspace - Quit/Back",
		"",
		"RULES:",
		"• Follow the game objectives",
		"• Avoid obstacles and enemies",
		"• Collect points and power-ups",
		"• Complete levels to progress",
		"",
		"HAVE FUN!",
	}

	for i, instruction in ipairs(instructions) do
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, instruction)
		local textY = startY + 60 + (i - 1) * lineHeight

		local textX
		if instruction:len() < 20 then
			textX = centerX - textWidth / 2
		else
			textX = centerX - 150
		end

		self.terminal:drawText(
			instruction,
			textX,
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

function GameTemplateMainMenu:showHighScores(gamesModule)
	self.menuState = "high_scores"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function GameTemplateMainMenu:showInstructions(gamesModule)
	self.menuState = "instructions"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

local GAME_INFO = {
	id = "game_template", -- unique identifier for the game
	name = "Game Template",
	description = "Description of your game. This text appears in the game selection menu.",
}

GameTemplate.gameState = {

	score = 0,
	level = 1,
	gameOver = false,
	lastUpdateTime = 0,
}

function GameTemplate:resetState()
	self.gameState = {
		score = 0,
		level = 1,
		gameOver = false,
		lastUpdateTime = getTimeInMillis(),
	}
end

function GameTemplate:activate(gamesModule)
	self:resetState()

	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
end

function GameTemplate:onDeactivate() end

function GameTemplate:preview(x, y, width, height, terminal, gamesModule)
	terminal:drawRect(x, y, width, height, 0.8, 0.2, 0.2, 0.3)

	terminal:drawText("PREVIEW", x + width / 2 - 30, y + height / 2 - 5, 1, 1, 1, 1, Constants.UI_CONST.FONT.SMALL)
end

function GameTemplate:onKeyPress(key, gamesModule)
	if self.gameState.gameOver then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			gamesModule:onActivate()
			return true
		end
		return false
	end

	if key == Keyboard.KEY_LEFT then
		return true
	elseif key == Keyboard.KEY_RIGHT then
		return true
	elseif key == Keyboard.KEY_UP then
		return true
	elseif key == Keyboard.KEY_DOWN then
		return true
	elseif key == Keyboard.KEY_SPACE then
		return true
	elseif key == Keyboard.KEY_BACK then
		gamesModule:onActivate()
		return true
	end

	return false
end

function GameTemplate:onMouseDown(x, y, gamesModule)
	return false
end

function GameTemplate:onMouseWheel(delta, gamesModule)
	return false
end

function GameTemplate:update(gamesModule)
	if self.gameState.gameOver then
		return
	end

	local currentTime = getTimeInMillis()
	local deltaTime = currentTime - self.gameState.lastUpdateTime

	self.gameState.lastUpdateTime = currentTime
end

function GameTemplate:render(gamesModule)
	local terminal = gamesModule.terminal

	terminal:renderTitle(GAME_INFO.name .. " - SCORE: " .. self.gameState.score .. " | LEVEL: " .. self.gameState.level)

	terminal:drawRect(
		terminal.displayX,
		terminal.contentAreaY,
		terminal.displayWidth,
		terminal.contentAreaHeight,
		Constants.UI_CONST.COLORS.BACKGROUND.a,
		Constants.UI_CONST.COLORS.BACKGROUND.r,
		Constants.UI_CONST.COLORS.BACKGROUND.g,
		Constants.UI_CONST.COLORS.BACKGROUND.b
	)

	if self.gameState.gameOver then
		local gameOverText = "GAME OVER"
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
		local textX = terminal.displayX + (terminal.displayWidth - textWidth) / 2
		local textY = terminal.contentAreaY + terminal.contentAreaHeight / 2

		terminal:drawText(gameOverText, textX, textY, 1, 1, 0.3, 0.3, Constants.UI_CONST.FONT.LARGE)

		terminal:renderFooter("GAME OVER! | PRESS SPACE OR BACKSPACE TO CONTINUE")
	else
		terminal:renderFooter("ARROWS - MOVE | SPACE - ACTION | BACKSPACE - QUIT")
	end
end

function GameTemplate:exampleHelperMethod() end

function GameTemplate:getMainMenu()
	return GameTemplateMainMenu:new(self, GAME_INFO)
end

function GameTemplateMainMenu:onKeyPress(key)
	if self.menuState == "high_scores" or self.menuState == "instructions" then
		if key == Keyboard.KEY_BACK then
			self.menuState = "main"
			TerminalSounds.playUISound("sfx_knoxnet_key_3")
			return true
		end
		return false
	end

	return GameMainMenu.onKeyPress(self, key)
end

return GameTemplate
