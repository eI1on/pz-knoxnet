local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local SnakeMainMenu = require("KnoxNet_GamesModule/games/SnakeMainMenu")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local SnakeGame = {}

local GAME_INFO = {
	id = "snake",
	name = "Snake",
	description = "Control the snake to eat food and grow longer, but don't hit yourself or the walls!",
}

local rand = newrandom()

SnakeGame.gameState = {
	snake = table.newarray(),
	direction = nil,
	nextDirection = nil,
	food = { x = 0, y = 0 },
	score = 0,
	level = 1,
	gameOver = false,
	lastMoveTime = 0,
	gameOverTime = 0,
	gridOffsetX = 0,
	gridOffsetY = 0,
	cellWidth = 0,
	cellHeight = 0,
	growing = false,
}

function SnakeGame:resetState()
	local snake = table.newarray() --[[@as table]]
	local startX = math.floor(Constants.SNAKE_CONST.GRID_WIDTH / 2)
	local startY = math.floor(Constants.SNAKE_CONST.GRID_HEIGHT / 2)

	for i = 1, Constants.SNAKE_CONST.INITIAL_LENGTH do
		table.insert(snake, { x = startX, y = startY + (i - 1) })
	end

	self.gameState = {
		snake = snake,
		direction = Constants.SNAKE_CONST.DIRECTIONS.UP,
		nextDirection = Constants.SNAKE_CONST.DIRECTIONS.UP,
		food = { x = 0, y = 0 },
		score = 0,
		level = 1,
		gameOver = false,
		lastMoveTime = getTimeInMillis(),
		gameOverTime = 0,
		gridOffsetX = 0,
		gridOffsetY = 0,
		cellWidth = 0,
		cellHeight = 0,
		growing = false,
	}

	self:generateFood()
end

function SnakeGame:activate(gamesModule)
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	self:resetState()

	local displayWidth = self.terminal.displayWidth
	local contentHeight = self.terminal.contentAreaHeight

	local maxGridWidth = displayWidth * 0.75
	local maxCellWidthSize = math.floor(maxGridWidth / Constants.SNAKE_CONST.GRID_WIDTH)
	local maxCellHeightSize = math.floor(contentHeight / Constants.SNAKE_CONST.GRID_HEIGHT)

	local cellSize = math.min(maxCellWidthSize, maxCellHeightSize)

	self.gameState.cellWidth = cellSize
	self.gameState.cellHeight = cellSize

	local totalGridWidth = cellSize * Constants.SNAKE_CONST.GRID_WIDTH
	local totalGridHeight = cellSize * Constants.SNAKE_CONST.GRID_HEIGHT

	self.gameState.gridOffsetX = self.terminal.displayX + (displayWidth - totalGridWidth) / 2
	self.gameState.gridOffsetY = self.terminal.contentAreaY + (contentHeight - totalGridHeight) / 2
end

function SnakeGame:onDeactivate() end

function SnakeGame:preview(x, y, width, height, terminal, gamesModule)
	local previewOffsetX = x + 5
	local previewOffsetY = y + 5
	local previewWidth = width - 10
	local previewHeight = height - 10

	terminal:drawRect(previewOffsetX, previewOffsetY, previewWidth, previewHeight, 0.7, 0, 0.1, 0.2)

	local gridWidth = 10
	local gridHeight = 8
	local cellSize = math.min(previewWidth / gridWidth, previewHeight / gridHeight)

	local gridX = previewOffsetX + (previewWidth - (gridWidth * cellSize)) / 2
	local gridY = previewOffsetY + (previewHeight - (gridHeight * cellSize)) / 2

	terminal:drawRect(
		gridX,
		gridY,
		gridWidth * cellSize,
		gridHeight * cellSize,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.a,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.r,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.g,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.b
	)

	terminal:drawRectBorder(
		gridX,
		gridY,
		gridWidth * cellSize,
		gridHeight * cellSize,
		Constants.SNAKE_CONST.COLORS.BORDER.a,
		Constants.SNAKE_CONST.COLORS.BORDER.r,
		Constants.SNAKE_CONST.COLORS.BORDER.g,
		Constants.SNAKE_CONST.COLORS.BORDER.b
	)

	local snakeSegments = {
		{ x = 5, y = 4 },
		{ x = 6, y = 4 },
		{ x = 7, y = 4 },
		{ x = 8, y = 4 },
		{ x = 8, y = 5 },
		{ x = 8, y = 6 },
	}

	for i, segment in ipairs(snakeSegments) do
		local color = (i == 1) and Constants.SNAKE_CONST.COLORS.SNAKE_HEAD or Constants.SNAKE_CONST.COLORS.SNAKE_BODY

		terminal:drawRect(
			gridX + (segment.x - 1) * cellSize,
			gridY + (segment.y - 1) * cellSize,
			cellSize,
			cellSize,
			color.a,
			color.r,
			color.g,
			color.b
		)
	end

	terminal:drawRect(
		gridX + 2 * cellSize,
		gridY + 2 * cellSize,
		cellSize,
		cellSize,
		Constants.SNAKE_CONST.COLORS.FOOD.a,
		Constants.SNAKE_CONST.COLORS.FOOD.r,
		Constants.SNAKE_CONST.COLORS.FOOD.g,
		Constants.SNAKE_CONST.COLORS.FOOD.b
	)
end

function SnakeGame:onKeyPress(key, gamesModule)
	if self.gameState.gameOver then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			gamesModule:onActivate()
			return true
		end
		return false
	end

	if key == Keyboard.KEY_UP and self.gameState.direction ~= Constants.SNAKE_CONST.DIRECTIONS.DOWN then
		self.gameState.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.UP
		TerminalSounds.playUISound("sfx_knoxnet_snake_move")
		return true
	elseif key == Keyboard.KEY_DOWN and self.gameState.direction ~= Constants.SNAKE_CONST.DIRECTIONS.UP then
		self.gameState.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.DOWN
		TerminalSounds.playUISound("sfx_knoxnet_snake_move")
		return true
	elseif key == Keyboard.KEY_LEFT and self.gameState.direction ~= Constants.SNAKE_CONST.DIRECTIONS.RIGHT then
		self.gameState.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.LEFT
		TerminalSounds.playUISound("sfx_knoxnet_snake_move")
		return true
	elseif key == Keyboard.KEY_RIGHT and self.gameState.direction ~= Constants.SNAKE_CONST.DIRECTIONS.LEFT then
		self.gameState.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.RIGHT
		TerminalSounds.playUISound("sfx_knoxnet_snake_move")
		return true
	elseif key == Keyboard.KEY_SPACE then
		self:moveSnake()
		self.gameState.lastMoveTime = getTimeInMillis()
		TerminalSounds.playUISound("sfx_knoxnet_snake_move")
		return true
	elseif key == Keyboard.KEY_BACK then
		gamesModule:onActivate()
		return true
	end
	return false
end

function SnakeGame:update(gamesModule)
	local currentTime = getTimeInMillis()

	if self.gameState.gameOver then
		if currentTime - self.gameState.gameOverTime >= Constants.SNAKE_CONST.GAME_OVER_DELAY then
			gamesModule:onActivate()
		end
		return
	end

	local moveDelay = math.max(50, Constants.SNAKE_CONST.MOVE_DELAY - ((self.gameState.level - 1) * 5))

	if currentTime - self.gameState.lastMoveTime >= moveDelay then
		self:moveSnake()
		self.gameState.lastMoveTime = currentTime
	end
end

function SnakeGame:render(gamesModule)
	local terminal = gamesModule.terminal
	terminal:renderTitle("SNAKE - SCORE: " .. self.gameState.score .. " | LEVEL: " .. self.gameState.level)

	terminal:drawRect(
		self.gameState.gridOffsetX,
		self.gameState.gridOffsetY,
		self.gameState.cellWidth * Constants.SNAKE_CONST.GRID_WIDTH,
		self.gameState.cellHeight * Constants.SNAKE_CONST.GRID_HEIGHT,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.a,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.r,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.g,
		Constants.SNAKE_CONST.COLORS.BACKGROUND.b
	)

	terminal:drawRectBorder(
		self.gameState.gridOffsetX,
		self.gameState.gridOffsetY,
		self.gameState.cellWidth * Constants.SNAKE_CONST.GRID_WIDTH,
		self.gameState.cellHeight * Constants.SNAKE_CONST.GRID_HEIGHT,
		Constants.SNAKE_CONST.COLORS.BORDER.a,
		Constants.SNAKE_CONST.COLORS.BORDER.r,
		Constants.SNAKE_CONST.COLORS.BORDER.g,
		Constants.SNAKE_CONST.COLORS.BORDER.b
	)

	for x = 0, Constants.SNAKE_CONST.GRID_WIDTH do
		local xPos = self.gameState.gridOffsetX + x * self.gameState.cellWidth
		terminal:drawRect(
			xPos,
			self.gameState.gridOffsetY,
			1,
			self.gameState.cellHeight * Constants.SNAKE_CONST.GRID_HEIGHT,
			Constants.SNAKE_CONST.COLORS.GRID.a,
			Constants.SNAKE_CONST.COLORS.GRID.r,
			Constants.SNAKE_CONST.COLORS.GRID.g,
			Constants.SNAKE_CONST.COLORS.GRID.b
		)
	end

	for y = 0, Constants.SNAKE_CONST.GRID_HEIGHT do
		local yPos = self.gameState.gridOffsetY + y * self.gameState.cellHeight
		terminal:drawRect(
			self.gameState.gridOffsetX,
			yPos,
			self.gameState.cellWidth * Constants.SNAKE_CONST.GRID_WIDTH,
			1,
			Constants.SNAKE_CONST.COLORS.GRID.a,
			Constants.SNAKE_CONST.COLORS.GRID.r,
			Constants.SNAKE_CONST.COLORS.GRID.g,
			Constants.SNAKE_CONST.COLORS.GRID.b
		)
	end

	for i = 1, #self.gameState.snake do
		local segment = self.gameState.snake[i]
		local color = (i == 1) and Constants.SNAKE_CONST.COLORS.SNAKE_HEAD or Constants.SNAKE_CONST.COLORS.SNAKE_BODY
		local segX = self.gameState.gridOffsetX + (segment.x - 1) * self.gameState.cellWidth
		local segY = self.gameState.gridOffsetY + (segment.y - 1) * self.gameState.cellHeight

		terminal:drawRect(
			segX,
			segY,
			self.gameState.cellWidth,
			self.gameState.cellHeight,
			color.a,
			color.r,
			color.g,
			color.b
		)

		if i == 1 then
			local eyeSize = math.max(2, math.floor(self.gameState.cellWidth / 5))
			local eyeOffset = math.floor(self.gameState.cellWidth / 4)

			terminal:drawRect(segX + eyeOffset, segY + eyeOffset, eyeSize, eyeSize, 1, 1, 1, 1)

			terminal:drawRect(
				segX + self.gameState.cellWidth - eyeOffset - eyeSize,
				segY + eyeOffset,
				eyeSize,
				eyeSize,
				1,
				1,
				1,
				1
			)
		end
	end

	local foodX = self.gameState.gridOffsetX + (self.gameState.food.x - 1) * self.gameState.cellWidth
	local foodY = self.gameState.gridOffsetY + (self.gameState.food.y - 1) * self.gameState.cellHeight

	terminal:drawRect(
		foodX,
		foodY,
		self.gameState.cellWidth,
		self.gameState.cellHeight,
		Constants.SNAKE_CONST.COLORS.FOOD.a,
		Constants.SNAKE_CONST.COLORS.FOOD.r,
		Constants.SNAKE_CONST.COLORS.FOOD.g,
		Constants.SNAKE_CONST.COLORS.FOOD.b
	)

	local circlePadding = math.floor(self.gameState.cellWidth / 6)
	local circleSize = self.gameState.cellWidth - (circlePadding * 2)

	terminal:drawRectBorder(foodX + circlePadding, foodY + circlePadding, circleSize, circleSize, 1, 1, 1, 1)

	if self.gameState.gameOver then
		local gameOverText = "GAME OVER"
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
		local textX = self.gameState.gridOffsetX
			+ (self.gameState.cellWidth * Constants.SNAKE_CONST.GRID_WIDTH - textWidth) / 2
		local textY = self.gameState.gridOffsetY + (self.gameState.cellHeight * Constants.SNAKE_CONST.GRID_HEIGHT / 2)

		terminal:drawText(gameOverText, textX, textY, 1, 1, 0.3, 0.3, Constants.UI_CONST.FONT.LARGE)

		terminal:renderFooter("GAME OVER! | PRESS SPACE OR BACKSPACE TO CONTINUE")
	else
		terminal:renderFooter("ARROWS - CHANGE DIRECTION | SPACE - BOOST | BACKSPACE - QUIT")
	end
end

function SnakeGame:moveSnake()
	if self.gameState.gameOver then
		return
	end

	self.gameState.direction = self.gameState.nextDirection

	local head = self.gameState.snake[1]
	local newHead = {
		x = head.x + self.gameState.direction.x,
		y = head.y + self.gameState.direction.y,
	}

	if
		newHead.x < 1
		or newHead.x > Constants.SNAKE_CONST.GRID_WIDTH
		or newHead.y < 1
		or newHead.y > Constants.SNAKE_CONST.GRID_HEIGHT
	then
		self:gameOver()
		return
	end

	for i = 1, #self.gameState.snake do
		local segment = self.gameState.snake[i]
		if newHead.x == segment.x and newHead.y == segment.y then
			self:gameOver()
			return
		end
	end

	if newHead.x == self.gameState.food.x and newHead.y == self.gameState.food.y then
		self.gameState.growing = true
		self.gameState.score = self.gameState.score + Constants.SNAKE_CONST.FOOD_POINTS * self.gameState.level
		self.gameState.level = math.floor(self.gameState.score / 100) + 1
		self:generateFood()
		TerminalSounds.playUISound("sfx_knoxnet_snake_eat_food")
	end

	table.insert(self.gameState.snake, 1, newHead)

	if not self.gameState.growing then
		table.remove(self.gameState.snake)
	else
		self.gameState.growing = false
	end
end

function SnakeGame:generateFood()
	local valid = false
	local newFood = { x = 0, y = 0 }

	while not valid do
		newFood.x = rand:random(1, Constants.SNAKE_CONST.GRID_WIDTH)
		newFood.y = rand:random(1, Constants.SNAKE_CONST.GRID_HEIGHT)

		valid = true
		for i = 1, #self.gameState.snake do
			local segment = self.gameState.snake[i]
			if newFood.x == segment.x and newFood.y == segment.y then
				valid = false
				break
			end
		end
	end

	self.gameState.food = newFood
end

function SnakeGame:gameOver()
	self.gameState.gameOver = true
	self.gameState.gameOverTime = getTimeInMillis()
	TerminalSounds.playUISound("sfx_knoxnet_snake_gameover")
end

function SnakeGame:getMainMenu()
	return SnakeMainMenu:new(self, GAME_INFO)
end

local GamesModule = require("KnoxNet_GamesModule/core/Module")
GamesModule.registerGame(GAME_INFO, SnakeGame)

return SnakeGame
