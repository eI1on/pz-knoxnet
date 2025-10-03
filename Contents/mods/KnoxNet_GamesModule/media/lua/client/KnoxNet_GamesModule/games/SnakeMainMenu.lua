local Constants = require("KnoxNet_GamesModule/core/Constants")
local GameMainMenu = require("KnoxNet_GamesModule/core/GameMainMenu")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local SnakeMainMenu = GameMainMenu:new()

function SnakeMainMenu:addGameSpecificOptions()
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

function SnakeMainMenu:startNewGame(gamesModule)
	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
	gamesModule:startGame(self.gameInstance)
end

function SnakeMainMenu:showHighScores(gamesModule)
	self.menuState = "high_scores"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function SnakeMainMenu:showInstructions(gamesModule)
	self.menuState = "instructions"
	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function SnakeMainMenu:render()
	if self.menuState == "main" then
		self:renderMainMenu()
	elseif self.menuState == "high_scores" then
		self:renderHighScores()
	elseif self.menuState == "instructions" then
		self:renderInstructions()
	end
end

function SnakeMainMenu:renderHighScores()
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

	local title = "SNAKE HIGH SCORES"
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
		{ name = "SNAKE_MASTER", score = 500, length = 25 },
		{ name = "COIL_KING", score = 400, length = 22 },
		{ name = "SLITHER_PRO", score = 300, length = 20 },
		{ name = "WORM_LORD", score = 200, length = 18 },
		{ name = "BEGINNER", score = 100, length = 15 },
	}

	for i, scoreData in ipairs(scores) do
		local scoreText = string.format("%d. %s - %d (Length %d)", i, scoreData.name, scoreData.score, scoreData.length)
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

function SnakeMainMenu:renderInstructions()
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

	local title = "HOW TO PLAY SNAKE"
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
		"Guide the snake to eat food and grow longer.",
		"",
		"CONTROLS:",
		"Arrow Keys - Change direction",
		"Space - Boost (if available)",
		"Backspace - Quit game",
		"",
		"RULES:",
		"• Don't hit the walls",
		"• Don't hit yourself",
		"• Eat food to grow and score points",
		"• Longer snake = higher score",
		"",
		"GOOD LUCK!",
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

function SnakeMainMenu:onKeyPress(key)
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

return SnakeMainMenu
