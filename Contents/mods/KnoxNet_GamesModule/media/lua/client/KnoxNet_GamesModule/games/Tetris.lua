local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local TetrisGame = {}

local GAME_INFO = {
	id = "tetris",
	name = "Tetris",
	description = "Stack blocks to create complete lines. Don't let the blocks reach the top!",
}

local rand = newrandom()

TetrisGame.gameState = {
	board = {},
	currentPiece = nil,
	nextPiece = nil,
	pieceX = 0,
	pieceY = 0,
	pieceRotation = 0,
	score = 0,
	level = 1,
	lines = 0,
	gameOver = false,
	lastDropTime = 0,
	gameOverTime = 0,
	gridOffsetX = 0,
	gridOffsetY = 0,
	cellWidth = 0,
	cellHeight = 0,
}

function TetrisGame:resetState()
	self.gameState = {
		board = {},
		currentPiece = nil,
		nextPiece = nil,
		pieceX = 0,
		pieceY = 0,
		pieceRotation = 0,
		score = 0,
		level = 1,
		lines = 0,
		gameOver = false,
		lastDropTime = getTimeInMillis(),
		gameOverTime = 0,
		gridOffsetX = 0,
		gridOffsetY = 0,
		cellWidth = 0,
		cellHeight = 0,
	}

	self.gameState.board = {}
	for y = 1, Constants.TETRIS_CONST.BOARD_HEIGHT do
		self.gameState.board[y] = {}
		for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
			self.gameState.board[y][x] = nil
		end
	end

	self.gameState.nextPiece = self:getRandomTetrisPiece()
	self:spawnTetrisPiece()
end

function TetrisGame:activate(gamesModule)
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	self:resetState()

	local displayWidth = self.terminal.displayWidth
	local contentHeight = self.terminal.contentAreaHeight

	local maxBoardWidth = displayWidth * 0.75
	local maxCellWidthSize = math.floor(maxBoardWidth / Constants.TETRIS_CONST.BOARD_WIDTH)
	local maxCellHeightSize = math.floor(contentHeight / Constants.TETRIS_CONST.BOARD_HEIGHT)

	local cellSize = math.min(maxCellWidthSize, maxCellHeightSize)

	self.gameState.cellWidth = cellSize
	self.gameState.cellHeight = cellSize

	local totalBoardWidth = cellSize * Constants.TETRIS_CONST.BOARD_WIDTH
	self.gameState.gridOffsetX = self.terminal.displayX + (displayWidth - totalBoardWidth - 150) / 2
	self.gameState.gridOffsetY = self.terminal.contentAreaY + 10

	TerminalSounds.playUISound("sfx_knoxnet_tetris")
end

function TetrisGame:onDeactivate() end

function TetrisGame:preview(x, y, width, height, terminal, gamesModule)
	local previewOffsetX = x + 5
	local previewOffsetY = y + 5
	local previewWidth = width - 10
	local previewHeight = height - 10

	terminal:drawRect(previewOffsetX, previewOffsetY, previewWidth, previewHeight, 0.7, 0, 0.1, 0.2)

	local cellSize = math.min(previewWidth / 6, previewHeight / 12)
	local gridWidth = 6 * cellSize
	local gridHeight = 10 * cellSize
	local gridX = previewOffsetX + (previewWidth - gridWidth) / 2
	local gridY = previewOffsetY + (previewHeight - gridHeight) / 2

	for i = 0, 6 do
		terminal:drawRect(gridX + i * cellSize, gridY, 1, gridHeight, 0.5, 0.3, 0.3, 0.3)
	end

	for i = 0, 10 do
		terminal:drawRect(gridX, gridY + i * cellSize, gridWidth, 1, 0.5, 0.3, 0.3, 0.3)
	end

	local pieces = {
		{ x = 1, y = 1, color = { r = 0.8, g = 0, b = 0.8, a = 1 } },
		{ x = 2, y = 1, color = { r = 0.8, g = 0, b = 0.8, a = 1 } },
		{ x = 3, y = 1, color = { r = 0.8, g = 0, b = 0.8, a = 1 } },
		{ x = 2, y = 2, color = { r = 0.8, g = 0, b = 0.8, a = 1 } },

		{ x = 1, y = 4, color = { r = 1, g = 0.5, b = 0, a = 1 } },
		{ x = 1, y = 5, color = { r = 1, g = 0.5, b = 0, a = 1 } },
		{ x = 1, y = 6, color = { r = 1, g = 0.5, b = 0, a = 1 } },
		{ x = 2, y = 6, color = { r = 1, g = 0.5, b = 0, a = 1 } },

		{ x = 4, y = 7, color = { r = 1, g = 1, b = 0, a = 1 } },
		{ x = 5, y = 7, color = { r = 1, g = 1, b = 0, a = 1 } },
		{ x = 4, y = 8, color = { r = 1, g = 1, b = 0, a = 1 } },
		{ x = 5, y = 8, color = { r = 1, g = 1, b = 0, a = 1 } },
	}

	for i = 1, #pieces do
		local piece = pieces[i]
		local cellX = gridX + (piece.x - 1) * cellSize
		local cellY = gridY + (piece.y - 1) * cellSize

		terminal:drawRect(cellX, cellY, cellSize, cellSize, piece.color.a, piece.color.r, piece.color.g, piece.color.b)

		terminal:drawRectBorder(cellX, cellY, cellSize, cellSize, 0.8, 1, 1, 1)
	end
end

function TetrisGame:onKeyPress(key, gamesModule)
	if self.gameState.gameOver then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			gamesModule:onActivate()
			return true
		end
		return false
	end

	if key == Keyboard.KEY_LEFT then
		TerminalSounds.playUISound("sfx_knoxnet_tetris_movebrick")
		self:moveTetrisPiece(-1)
		return true
	elseif key == Keyboard.KEY_RIGHT then
		TerminalSounds.playUISound("sfx_knoxnet_tetris_movebrick")
		self:moveTetrisPiece(1)
		return true
	elseif key == Keyboard.KEY_UP then
		TerminalSounds.playUISound("sfx_knoxnet_tetris_movebrick")
		self:rotateTetrisPiece()
		return true
	elseif key == Keyboard.KEY_DOWN then
		TerminalSounds.playUISound("sfx_knoxnet_tetris_movebrick")
		self:dropTetrisPiece()
		self.gameState.lastDropTime = getTimeInMillis()
		return true
	elseif key == Keyboard.KEY_SPACE then
		TerminalSounds.playUISound("sfx_knoxnet_tetris_groundkick")
		self:hardDropTetrisPiece()
		return true
	elseif key == Keyboard.KEY_BACK then
		gamesModule:onActivate()
		return true
	end
	return false
end

function TetrisGame:update(gamesModule)
	local currentTime = getTimeInMillis()

	if self.gameState.gameOver then
		if currentTime - self.gameState.gameOverTime >= Constants.TETRIS_CONST.GAME_OVER_DELAY then
			gamesModule:onActivate()
		end
		return
	end

	local dropInterval = math.max(100, Constants.TETRIS_CONST.DROP_INTERVAL - ((self.gameState.level - 1) * 50))

	if currentTime - self.gameState.lastDropTime >= dropInterval then
		if not self:dropTetrisPiece() then
			self:lockTetrisPiece()
		end
		self.gameState.lastDropTime = currentTime
	end
end

function TetrisGame:render(gamesModule)
	local terminal = gamesModule.terminal
	terminal:renderTitle("TETRIS - SCORE: " .. self.gameState.score .. " | LEVEL: " .. self.gameState.level)

	terminal:drawRect(
		self.gameState.gridOffsetX,
		self.gameState.gridOffsetY,
		self.gameState.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH,
		self.gameState.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT,
		Constants.TETRIS_CONST.COLORS.BACKGROUND.a,
		Constants.TETRIS_CONST.COLORS.BACKGROUND.r,
		Constants.TETRIS_CONST.COLORS.BACKGROUND.g,
		Constants.TETRIS_CONST.COLORS.BACKGROUND.b
	)

	for x = 0, Constants.TETRIS_CONST.BOARD_WIDTH do
		local xPos = self.gameState.gridOffsetX + x * self.gameState.cellWidth
		terminal:drawRect(
			xPos,
			self.gameState.gridOffsetY,
			1,
			self.gameState.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT,
			Constants.TETRIS_CONST.COLORS.GRID.a,
			Constants.TETRIS_CONST.COLORS.GRID.r,
			Constants.TETRIS_CONST.COLORS.GRID.g,
			Constants.TETRIS_CONST.COLORS.GRID.b
		)
	end

	for y = 0, Constants.TETRIS_CONST.BOARD_HEIGHT do
		local yPos = self.gameState.gridOffsetY + y * self.gameState.cellHeight
		terminal:drawRect(
			self.gameState.gridOffsetX,
			yPos,
			self.gameState.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH,
			1,
			Constants.TETRIS_CONST.COLORS.GRID.a,
			Constants.TETRIS_CONST.COLORS.GRID.r,
			Constants.TETRIS_CONST.COLORS.GRID.g,
			Constants.TETRIS_CONST.COLORS.GRID.b
		)
	end

	for y = 1, Constants.TETRIS_CONST.BOARD_HEIGHT do
		for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
			if self.gameState.board[y][x] then
				local cell = self.gameState.board[y][x]
				local cellX = self.gameState.gridOffsetX + (x - 1) * self.gameState.cellWidth
				local cellY = self.gameState.gridOffsetY + (y - 1) * self.gameState.cellHeight

				self:drawTetrisCell(cellX, cellY, cell.color, cell.char)
			end
		end
	end

	if not self.gameState.gameOver then
		local shape = self:getTetrisShape(self.gameState.currentPiece, self.gameState.pieceRotation)
		local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[self.gameState.currentPiece]

		for row = 1, #shape do
			for col = 1, #shape[1] do
				if shape[row][col] == 1 then
					local boardX = self.gameState.pieceX + col - 1
					local boardY = self.gameState.pieceY + row - 1

					if boardY >= 1 then
						local cellX = self.gameState.gridOffsetX + (boardX - 1) * self.gameState.cellWidth
						local cellY = self.gameState.gridOffsetY + (boardY - 1) * self.gameState.cellHeight

						self:drawTetrisCell(cellX, cellY, pieceData.color, pieceData.char)
					end
				end
			end
		end
	end

	self:drawNextPiecePreview()

	if self.gameState.gameOver then
		local gameOverText = "GAME OVER"
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
		local textX = self.gameState.gridOffsetX
			+ (self.gameState.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH - textWidth) / 2
		local textY = self.gameState.gridOffsetY + self.gameState.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT / 2

		terminal:drawText(gameOverText, textX, textY, 1, 1, 0.3, 0.3, Constants.UI_CONST.FONT.LARGE)

		terminal:renderFooter("GAME OVER! | PRESS SPACE OR BACKSPACE TO CONTINUE")
	else
		terminal:renderFooter("ARROWS - MOVE/ROTATE | SPACE - DROP | BACKSPACE - QUIT")
	end
end

function TetrisGame:getRandomTetrisPiece()
	local pieces = table.newarray() --[[@as table]]
	for type, _ in pairs(Constants.TETRIS_CONST.PIECE_TYPES) do
		table.insert(pieces, type)
	end

	local randomIndex = rand:random(1, #pieces)
	return pieces[randomIndex]
end

function TetrisGame:spawnTetrisPiece()
	self.gameState.currentPiece = self.gameState.nextPiece
	self.gameState.nextPiece = self:getRandomTetrisPiece()

	local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[self.gameState.currentPiece]
	local pieceWidth = #pieceData.shape[1]

	self.gameState.pieceX = math.floor((Constants.TETRIS_CONST.BOARD_WIDTH - pieceWidth) / 2) + 1
	self.gameState.pieceY = 1
	self.gameState.pieceRotation = 0

	if
		not self:isValidTetrisPosition(
			self.gameState.pieceX,
			self.gameState.pieceY,
			self.gameState.currentPiece,
			self.gameState.pieceRotation
		)
	then
		self.gameState.gameOver = true
		self.gameState.gameOverTime = getTimeInMillis()
		TerminalSounds.playUISound("sfx_knoxnet_tetris_gameover")
	end
end

function TetrisGame:rotateTetrisShape(shape)
	local size = #shape
	local rotated = {}

	for y = 1, size do
		rotated[y] = {}
		for x = 1, size do
			rotated[y][x] = shape[size - x + 1][y]
		end
	end

	return rotated
end

function TetrisGame:getTetrisShape(pieceType, rotation)
	local shape = Constants.TETRIS_CONST.PIECE_TYPES[pieceType].shape
	local rotated = shape

	for i = 1, rotation do
		rotated = self:rotateTetrisShape(rotated)
	end

	return rotated
end

function TetrisGame:isValidTetrisPosition(x, y, pieceType, rotation)
	local shape = self:getTetrisShape(pieceType, rotation)

	for row = 1, #shape do
		for col = 1, #shape[1] do
			if shape[row][col] == 1 then
				local boardX = x + col - 1
				local boardY = y + row - 1

				if
					boardX < 1
					or boardX > Constants.TETRIS_CONST.BOARD_WIDTH
					or boardY < 1
					or boardY > Constants.TETRIS_CONST.BOARD_HEIGHT
				then
					return false
				end

				if self.gameState.board[boardY] and self.gameState.board[boardY][boardX] then
					return false
				end
			end
		end
	end

	return true
end

function TetrisGame:lockTetrisPiece()
	local shape = self:getTetrisShape(self.gameState.currentPiece, self.gameState.pieceRotation)
	local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[self.gameState.currentPiece]

	for row = 1, #shape do
		for col = 1, #shape[1] do
			if shape[row][col] == 1 then
				local boardX = self.gameState.pieceX + col - 1
				local boardY = self.gameState.pieceY + row - 1

				if
					boardY >= 1
					and boardY <= Constants.TETRIS_CONST.BOARD_HEIGHT
					and boardX >= 1
					and boardX <= Constants.TETRIS_CONST.BOARD_WIDTH
				then
					self.gameState.board[boardY][boardX] = {
						type = self.gameState.currentPiece,
						color = pieceData.color,
						char = pieceData.char,
					}
				end
			end
		end
	end

	local linesCleared = self:clearTetrisLines()

	self:spawnTetrisPiece()
end

function TetrisGame:clearTetrisLines()
	local linesCleared = 0

	for y = Constants.TETRIS_CONST.BOARD_HEIGHT, 1, -1 do
		local lineComplete = true

		for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
			if not self.gameState.board[y][x] then
				lineComplete = false
				break
			end
		end

		if lineComplete then
			table.remove(self.gameState.board, y)
			local newLine = {}
			for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
				newLine[x] = nil
			end
			table.insert(self.gameState.board, 1, newLine)

			linesCleared = linesCleared + 1
		end
	end

	if linesCleared > 0 then
		local linePoints = { 40, 100, 300, 1200 } -- points for 1, 2, 3, and 4 lines
		self.gameState.score = self.gameState.score + (linePoints[linesCleared] or linePoints[1]) * self.gameState.level
		self.gameState.lines = self.gameState.lines + linesCleared
		self.gameState.level = math.floor(self.gameState.lines / 10) + 1
	end

	return linesCleared
end

function TetrisGame:moveTetrisPiece(dx)
	local newX = self.gameState.pieceX + dx

	if
		self:isValidTetrisPosition(
			newX,
			self.gameState.pieceY,
			self.gameState.currentPiece,
			self.gameState.pieceRotation
		)
	then
		self.gameState.pieceX = newX
		return true
	end

	return false
end

function TetrisGame:rotateTetrisPiece()
	local newRotation = (self.gameState.pieceRotation + 1) % 4

	if
		self:isValidTetrisPosition(
			self.gameState.pieceX,
			self.gameState.pieceY,
			self.gameState.currentPiece,
			newRotation
		)
	then
		self.gameState.pieceRotation = newRotation
		return true
	end

	return false
end

function TetrisGame:dropTetrisPiece()
	local newY = self.gameState.pieceY + 1

	if
		self:isValidTetrisPosition(
			self.gameState.pieceX,
			newY,
			self.gameState.currentPiece,
			self.gameState.pieceRotation
		)
	then
		self.gameState.pieceY = newY
		return true
	end

	return false
end

function TetrisGame:hardDropTetrisPiece()
	local dropCount = 0
	while self:dropTetrisPiece() do
		dropCount = dropCount + 1
	end

	if dropCount > 0 then
		self.gameState.score = self.gameState.score + dropCount
	end

	self:lockTetrisPiece()
end

function TetrisGame:drawTetrisCell(x, y, color, char)
	self.terminal:drawRect(
		x,
		y,
		self.gameState.cellWidth,
		self.gameState.cellHeight,
		color.a,
		color.r,
		color.g,
		color.b
	)

	self.terminal:drawRectBorder(x, y, self.gameState.cellWidth, self.gameState.cellHeight, 0.8, 1, 1, 1)

	self.terminal:drawRect(x, y, self.gameState.cellWidth, 2, 0.5, 1, 1, 1)

	self.terminal:drawRect(x, y, 2, self.gameState.cellHeight, 0.5, 1, 1, 1)

	self.terminal:drawRect(x + self.gameState.cellWidth - 2, y, 2, self.gameState.cellHeight, 0.5, 0, 0, 0)

	self.terminal:drawRect(x, y + self.gameState.cellHeight - 2, self.gameState.cellWidth, 2, 0.5, 0, 0, 0)

	local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, char)
	local textHeight = getTextManager():MeasureStringY(Constants.UI_CONST.FONT.MEDIUM, char)
	local textX = x + (self.gameState.cellWidth - textWidth) / 2
	local textY = y + (self.gameState.cellHeight - textHeight) / 2

	self.terminal:drawText(char, textX, textY, 1, 1, 1, 1, Constants.UI_CONST.FONT.MEDIUM)
end

function TetrisGame:drawNextPiecePreview()
	local nextPieceData = Constants.TETRIS_CONST.PIECE_TYPES[self.gameState.nextPiece]
	local nextPieceShape = nextPieceData.shape

	local previewX = self.gameState.gridOffsetX + self.gameState.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH + 20
	local previewY = self.gameState.gridOffsetY + 50

	self.terminal:drawText("NEXT", previewX, previewY - 30, 1, 1, 1, 1, Constants.UI_CONST.FONT.MEDIUM)

	local previewCellSize = math.floor(self.gameState.cellWidth * 0.75)
	local previewWidth = 5 * previewCellSize + 10
	local previewHeight = 5 * previewCellSize + 10

	self.terminal:drawRect(previewX, previewY, previewWidth, previewHeight, 0.5, 0.1, 0.1, 0.2)

	self.terminal:drawRectBorder(previewX, previewY, previewWidth, previewHeight, 0.8, 0.3, 0.3, 0.5)

	for row = 1, 5 do
		for col = 1, 5 do
			if row <= #nextPieceShape and col <= #nextPieceShape[1] and nextPieceShape[row][col] == 1 then
				local cellX = previewX + 5 + (col - 1) * previewCellSize
				local cellY = previewY + 5 + (row - 1) * previewCellSize

				self.terminal:drawRect(
					cellX,
					cellY,
					previewCellSize,
					previewCellSize,
					nextPieceData.color.a,
					nextPieceData.color.r,
					nextPieceData.color.g,
					nextPieceData.color.b
				)

				self.terminal:drawRectBorder(cellX, cellY, previewCellSize, previewCellSize, 0.8, 1, 1, 1)

				local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.SMALL, nextPieceData.char)
				local textHeight = getTextManager():MeasureStringY(Constants.UI_CONST.FONT.SMALL, nextPieceData.char)
				local textX = cellX + (previewCellSize - textWidth) / 2
				local textY = cellY + (previewCellSize - textHeight) / 2

				self.terminal:drawText(nextPieceData.char, textX, textY, 1, 1, 1, 1, Constants.UI_CONST.FONT.SMALL)
			end
		end
	end

	local infoY = previewY + previewHeight + 10

	self.terminal:drawText(
		"LEVEL: " .. self.gameState.level,
		previewX,
		infoY,
		1,
		1,
		1,
		0.8,
		Constants.UI_CONST.FONT.MEDIUM
	)

	self.terminal:drawText(
		"LINES: " .. self.gameState.lines,
		previewX,
		infoY + 20,
		1,
		1,
		1,
		0.8,
		Constants.UI_CONST.FONT.MEDIUM
	)

	local controlsY = infoY + 50

	self.terminal:drawText("CONTROLS:", previewX, controlsY, 1, 0.8, 1, 0.8, Constants.UI_CONST.FONT.SMALL)

	self.terminal:drawText("^: ROTATE", previewX, controlsY + 20, 1, 0.8, 1, 0.8, Constants.UI_CONST.FONT.SMALL)

	self.terminal:drawText("</>: MOVE", previewX, controlsY + 40, 1, 0.8, 1, 0.8, Constants.UI_CONST.FONT.SMALL)

	self.terminal:drawText("v: SOFT DROP", previewX, controlsY + 60, 1, 0.8, 1, 0.8, Constants.UI_CONST.FONT.SMALL)

	self.terminal:drawText("SPACE: HARD DROP", previewX, controlsY + 80, 1, 0.8, 1, 0.8, Constants.UI_CONST.FONT.SMALL)
end

local GamesModule = require("KnoxNet_GamesModule/core/Module")
GamesModule.registerGame(GAME_INFO, TetrisGame)

return TetrisGame
