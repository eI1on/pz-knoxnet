local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

-- create a new game module
local GameTemplate = {}

-- game metadata
local GAME_INFO = {
	id = "game_template", -- unique identifier for the game
	name = "Game Template",
	description = "Description of your game. This text appears in the game selection menu.",
}

-- game state variables
GameTemplate.gameState = {
	-- put game-specific state variables here
	score = 0,
	level = 1,
	gameOver = false,
	lastUpdateTime = 0,
}

-- initialize or reset the game state
function GameTemplate:resetState()
	self.gameState = {
		score = 0,
		level = 1,
		gameOver = false,
		lastUpdateTime = getTimeInMillis(),
		-- reset other game-specific state
	}
end

-- called when the game is activated
function GameTemplate:activate(gamesModule)
	self:resetState()

	-- store references to needed objects
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	-- set up any initial game layout, variables, etc.
	-- example:
	-- self.gridOffsetX = self.terminal.displayX + 50
	-- self.gridOffsetY = self.terminal.contentAreaY + 20

	-- play game start sound if needed
	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
end

-- called when the game is deactivated
function GameTemplate:onDeactivate()
	-- clean up resources, stop sounds, etc.
end

-- draw the preview of the game in the game selection menu
function GameTemplate:preview(x, y, width, height, terminal, gamesModule)
	-- draw a representative preview of your game
	-- this appears in the game selection grid

	-- example:
	terminal:drawRect(x, y, width, height, 0.8, 0.2, 0.2, 0.3)

	terminal:drawText("PREVIEW", x + width / 2 - 30, y + height / 2 - 5, 1, 1, 1, 1, Constants.UI_CONST.FONT.SMALL)
end

-- handle keyboard input
function GameTemplate:onKeyPress(key, gamesModule)
	if self.gameState.gameOver then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			-- return to game selection
			gamesModule:onActivate()
			return true
		end
		return false
	end

	-- handle game-specific keys
	if key == Keyboard.KEY_LEFT then
		-- handle left key press
		-- example: self:moveLeft()
		return true
	elseif key == Keyboard.KEY_RIGHT then
		-- handle right key press
		-- example: self:moveRight()
		return true
	elseif key == Keyboard.KEY_UP then
		-- handle up key press
		return true
	elseif key == Keyboard.KEY_DOWN then
		-- handle down key press
		return true
	elseif key == Keyboard.KEY_SPACE then
		-- handle space key press
		return true
	elseif key == Keyboard.KEY_BACK then
		-- exit game
		gamesModule:onActivate()
		return true
	end

	return false
end

-- optional: handle mouse input
function GameTemplate:onMouseDown(x, y, gamesModule)
	-- handle mouse clicks
	return false
end

-- optional: handle mouse wheel
function GameTemplate:onMouseWheel(delta, gamesModule)
	-- handle mouse wheel movement
	return false
end

-- hame update logic - called every frame
function GameTemplate:update(gamesModule)
	if self.gameState.gameOver then
		-- handle game over state
		return
	end

	local currentTime = getTimeInMillis()
	local deltaTime = currentTime - self.gameState.lastUpdateTime

	-- update game logic here
	-- example: Move pieces, check collisions, etc.

	self.gameState.lastUpdateTime = currentTime
end

-- render the game
function GameTemplate:render(gamesModule)
	-- the terminal object for drawing
	local terminal = gamesModule.terminal

	-- render game title with score
	terminal:renderTitle(GAME_INFO.name .. " - SCORE: " .. self.gameState.score .. " | LEVEL: " .. self.gameState.level)

	-- draw game background
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

	-- draw game elements
	-- example: self:drawGameGrid()
	-- example: self:drawGamePieces()
	-- example: self:drawUI()

	-- if game is over, show game over message
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

-- additional game-specific helper methods
--[[
function GameTemplate:exampleHelperMethod()
    -- implement game-specific functionality
end
--]]

-- register the game with the Games Module
-- local GamesModule = require("KnoxNet_GamesModule/core/Module")
-- GamesModule.registerGame(GAME_INFO, GameTemplate)

return GameTemplate
