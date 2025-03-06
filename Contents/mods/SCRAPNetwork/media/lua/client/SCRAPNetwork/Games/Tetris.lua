local SCRAP_Terminal = require("SCRAPNetwork/ScrapOS_Terminal")
local TerminalSounds = require("SCRAPNetwork/ScrapOS_TerminalSoundsManager")

local Constants = require("SCRAPNetwork/Games/Constants")
local GamesModule = require("SCRAPNetwork/Games/Module")


table.insert(GamesModule.GAMES,
    {
        name = "Tetris",
        description = "Stack blocks to create complete lines. Don't let the blocks reach the top!",
        activate = function(self) self:activateTetris() end,
        preview = function(self, x, y, width, height, terminal)
            local previewOffsetX = x + 5
            local previewOffsetY = y + 5
            local previewWidth = width - 10
            local previewHeight = height - 10

            terminal:drawRect(
                previewOffsetX, previewOffsetY,
                previewWidth, previewHeight,
                0.7, 0, 0.1, 0.2
            )

            local cellSize = math.min(previewWidth / 6, previewHeight / 12)
            local gridWidth = 6 * cellSize
            local gridHeight = 10 * cellSize
            local gridX = previewOffsetX + (previewWidth - gridWidth) / 2
            local gridY = previewOffsetY + (previewHeight - gridHeight) / 2

            for i = 0, 6 do
                terminal:drawRect(
                    gridX + i * cellSize, gridY,
                    1, gridHeight,
                    0.5, 0.3, 0.3, 0.3
                )
            end

            for i = 0, 10 do
                terminal:drawRect(
                    gridX, gridY + i * cellSize,
                    gridWidth, 1,
                    0.5, 0.3, 0.3, 0.3
                )
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
                local piece = pieces[i];
                local cellX = gridX + (piece.x - 1) * cellSize
                local cellY = gridY + (piece.y - 1) * cellSize

                terminal:drawRect(
                    cellX, cellY,
                    cellSize, cellSize,
                    piece.color.a, piece.color.r, piece.color.g, piece.color.b
                )

                terminal:drawRectBorder(
                    cellX, cellY,
                    cellSize, cellSize,
                    0.8, 1, 1, 1
                )
            end
        end
    }
)

----------------------
-- TETRIS GAME CODE --
----------------------
local tetrisGame = {
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
    cellHeight = 0
}

function GamesModule:activateTetris()
    self.inGame = true

    local displayWidth = self.terminal.displayWidth
    local contentHeight = self.terminal.contentAreaHeight

    local maxBoardWidth = displayWidth * 0.75
    local maxCellWidthSize = math.floor(maxBoardWidth / Constants.TETRIS_CONST.BOARD_WIDTH)
    local maxCellHeightSize = math.floor(contentHeight / Constants.TETRIS_CONST.BOARD_HEIGHT)

    local cellSize = math.min(maxCellWidthSize, maxCellHeightSize)

    tetrisGame.cellWidth = cellSize
    tetrisGame.cellHeight = cellSize

    local totalBoardWidth = cellSize * Constants.TETRIS_CONST.BOARD_WIDTH
    tetrisGame.gridOffsetX = self.terminal.displayX + (displayWidth - totalBoardWidth - 150) / 2
    tetrisGame.gridOffsetY = self.terminal.contentAreaY + 10

    tetrisGame.board = {}
    for y = 1, Constants.TETRIS_CONST.BOARD_HEIGHT do
        tetrisGame.board[y] = {}
        for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
            tetrisGame.board[y][x] = nil
        end
    end

    tetrisGame.score = 0
    tetrisGame.level = 1
    tetrisGame.lines = 0
    tetrisGame.gameOver = false
    tetrisGame.lastDropTime = getTimeInMillis()

    tetrisGame.nextPiece = self:getRandomTetrisPiece()
    self:spawnTetrisPiece()

    TerminalSounds.playUISound("scrap_terminal_tetris")
end

function GamesModule:getRandomTetrisPiece()
    local pieces = {}
    for type, _ in pairs(Constants.TETRIS_CONST.PIECE_TYPES) do
        table.insert(pieces, type)
    end

    local randomIndex = ZombRand(1, #pieces + 1)
    return pieces[randomIndex]
end

function GamesModule:spawnTetrisPiece()
    tetrisGame.currentPiece = tetrisGame.nextPiece
    tetrisGame.nextPiece = self:getRandomTetrisPiece()

    local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[tetrisGame.currentPiece]
    local pieceWidth = #pieceData.shape[1]

    tetrisGame.pieceX = math.floor((Constants.TETRIS_CONST.BOARD_WIDTH - pieceWidth) / 2) + 1
    tetrisGame.pieceY = 1
    tetrisGame.pieceRotation = 0

    if not self:isValidTetrisPosition(tetrisGame.pieceX, tetrisGame.pieceY, tetrisGame.currentPiece, tetrisGame.pieceRotation) then
        tetrisGame.gameOver = true
        tetrisGame.gameOverTime = getTimeInMillis()
    end
end

function GamesModule:rotateTetrisShape(shape)
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

function GamesModule:getTetrisShape(pieceType, rotation)
    local shape = Constants.TETRIS_CONST.PIECE_TYPES[pieceType].shape
    local rotated = shape

    for i = 1, rotation do
        rotated = self:rotateTetrisShape(rotated)
    end

    return rotated
end

function GamesModule:isValidTetrisPosition(x, y, pieceType, rotation)
    local shape = self:getTetrisShape(pieceType, rotation)

    for row = 1, #shape do
        for col = 1, #shape[1] do
            if shape[row][col] == 1 then
                local boardX = x + col - 1
                local boardY = y + row - 1

                if boardX < 1 or boardX > Constants.TETRIS_CONST.BOARD_WIDTH or
                    boardY < 1 or boardY > Constants.TETRIS_CONST.BOARD_HEIGHT then
                    return false
                end

                if tetrisGame.board[boardY] and tetrisGame.board[boardY][boardX] then
                    return false
                end
            end
        end
    end

    return true
end

function GamesModule:lockTetrisPiece()
    local shape = self:getTetrisShape(tetrisGame.currentPiece, tetrisGame.pieceRotation)
    local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[tetrisGame.currentPiece]

    for row = 1, #shape do
        for col = 1, #shape[1] do
            if shape[row][col] == 1 then
                local boardX = tetrisGame.pieceX + col - 1
                local boardY = tetrisGame.pieceY + row - 1

                if boardY >= 1 and boardY <= Constants.TETRIS_CONST.BOARD_HEIGHT and
                    boardX >= 1 and boardX <= Constants.TETRIS_CONST.BOARD_WIDTH then
                    tetrisGame.board[boardY][boardX] = {
                        type = tetrisGame.currentPiece,
                        color = pieceData.color,
                        char = pieceData.char
                    }
                end
            end
        end
    end

    local linesCleared = self:clearTetrisLines()

    self:spawnTetrisPiece()
end

function GamesModule:clearTetrisLines()
    local linesCleared = 0

    for y = Constants.TETRIS_CONST.BOARD_HEIGHT, 1, -1 do
        local lineComplete = true

        for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
            if not tetrisGame.board[y][x] then
                lineComplete = false
                break
            end
        end

        if lineComplete then
            table.remove(tetrisGame.board, y)
            local newLine = {}
            for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
                newLine[x] = nil
            end
            table.insert(tetrisGame.board, 1, newLine)

            linesCleared = linesCleared + 1
        end
    end

    if linesCleared > 0 then
        local linePoints = { 40, 100, 300, 1200 } -- points for 1, 2, 3, and 4 lines
        tetrisGame.score = tetrisGame.score + (linePoints[linesCleared] or linePoints[1]) * tetrisGame.level
        tetrisGame.lines = tetrisGame.lines + linesCleared
        tetrisGame.level = math.floor(tetrisGame.lines / 10) + 1
    end

    return linesCleared
end

function GamesModule:updateTetris()
    local currentTime = getTimeInMillis()

    if tetrisGame.gameOver then
        if currentTime - tetrisGame.gameOverTime >= Constants.TETRIS_CONST.GAME_OVER_DELAY then
            TerminalSounds.playUISound("scrap_terminal_tetris_gameover")
            self:onActivate()
        end
        return
    end

    local dropInterval = math.max(100, Constants.TETRIS_CONST.DROP_INTERVAL - ((tetrisGame.level - 1) * 50))

    if currentTime - tetrisGame.lastDropTime >= dropInterval then
        if not self:dropTetrisPiece() then
            self:lockTetrisPiece()
        end
        tetrisGame.lastDropTime = currentTime
    end
end

function GamesModule:moveTetrisPiece(dx)
    local newX = tetrisGame.pieceX + dx

    if self:isValidTetrisPosition(newX, tetrisGame.pieceY, tetrisGame.currentPiece, tetrisGame.pieceRotation) then
        tetrisGame.pieceX = newX
        return true
    end

    return false
end

function GamesModule:rotateTetrisPiece()
    local newRotation = (tetrisGame.pieceRotation + 1) % 4

    if self:isValidTetrisPosition(tetrisGame.pieceX, tetrisGame.pieceY, tetrisGame.currentPiece, newRotation) then
        tetrisGame.pieceRotation = newRotation
        return true
    end

    return false
end

function GamesModule:dropTetrisPiece()
    local newY = tetrisGame.pieceY + 1

    if self:isValidTetrisPosition(tetrisGame.pieceX, newY, tetrisGame.currentPiece, tetrisGame.pieceRotation) then
        tetrisGame.pieceY = newY
        return true
    end

    return false
end

function GamesModule:hardDropTetrisPiece()
    local dropCount = 0
    while self:dropTetrisPiece() do
        dropCount = dropCount + 1
    end

    if dropCount > 0 then
        tetrisGame.score = tetrisGame.score + dropCount
    end

    self:lockTetrisPiece()
end

function GamesModule:handleTetrisKeyPress(key)
    if tetrisGame.gameOver then
        if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
            self:onActivate()
            return true
        end
        return false
    end

    if key == Keyboard.KEY_LEFT then
        TerminalSounds.playUISound("scrap_terminal_tetris_movebrick")
        self:moveTetrisPiece(-1)
        return true
    elseif key == Keyboard.KEY_RIGHT then
        TerminalSounds.playUISound("scrap_terminal_tetris_movebrick")
        self:moveTetrisPiece(1)
        return true
    elseif key == Keyboard.KEY_UP then
        TerminalSounds.playUISound("scrap_terminal_tetris_movebrick")
        self:rotateTetrisPiece()
        return true
    elseif key == Keyboard.KEY_DOWN then
        TerminalSounds.playUISound("scrap_terminal_tetris_movebrick")
        self:dropTetrisPiece()
        tetrisGame.lastDropTime = getTimeInMillis()
        return true
    elseif key == Keyboard.KEY_SPACE then
        TerminalSounds.playUISound("scrap_terminal_tetris_groundkick")
        self:hardDropTetrisPiece()
        return true
    elseif key == Keyboard.KEY_BACK then
        self:onActivate()
        return true
    end
    return false
end

function GamesModule:renderTetris()
    self.terminal:renderTitle("TETRIS - SCORE: " .. tetrisGame.score .. " | LEVEL: " .. tetrisGame.level)

    self.terminal:drawRect(
        tetrisGame.gridOffsetX,
        tetrisGame.gridOffsetY,
        tetrisGame.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH,
        tetrisGame.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT,
        Constants.TETRIS_CONST.COLORS.BACKGROUND.a,
        Constants.TETRIS_CONST.COLORS.BACKGROUND.r,
        Constants.TETRIS_CONST.COLORS.BACKGROUND.g,
        Constants.TETRIS_CONST.COLORS.BACKGROUND.b
    )

    for x = 0, Constants.TETRIS_CONST.BOARD_WIDTH do
        local xPos = tetrisGame.gridOffsetX + x * tetrisGame.cellWidth
        self.terminal:drawRect(
            xPos,
            tetrisGame.gridOffsetY,
            1,
            tetrisGame.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT,
            Constants.TETRIS_CONST.COLORS.GRID.a,
            Constants.TETRIS_CONST.COLORS.GRID.r,
            Constants.TETRIS_CONST.COLORS.GRID.g,
            Constants.TETRIS_CONST.COLORS.GRID.b
        )
    end

    for y = 0, Constants.TETRIS_CONST.BOARD_HEIGHT do
        local yPos = tetrisGame.gridOffsetY + y * tetrisGame.cellHeight
        self.terminal:drawRect(
            tetrisGame.gridOffsetX,
            yPos,
            tetrisGame.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH,
            1,
            Constants.TETRIS_CONST.COLORS.GRID.a,
            Constants.TETRIS_CONST.COLORS.GRID.r,
            Constants.TETRIS_CONST.COLORS.GRID.g,
            Constants.TETRIS_CONST.COLORS.GRID.b
        )
    end

    for y = 1, Constants.TETRIS_CONST.BOARD_HEIGHT do
        for x = 1, Constants.TETRIS_CONST.BOARD_WIDTH do
            if tetrisGame.board[y][x] then
                local cell = tetrisGame.board[y][x]
                local cellX = tetrisGame.gridOffsetX + (x - 1) * tetrisGame.cellWidth
                local cellY = tetrisGame.gridOffsetY + (y - 1) * tetrisGame.cellHeight

                self:drawTetrisCell(cellX, cellY, cell.color, cell.char)
            end
        end
    end

    if not tetrisGame.gameOver then
        local shape = self:getTetrisShape(tetrisGame.currentPiece, tetrisGame.pieceRotation)
        local pieceData = Constants.TETRIS_CONST.PIECE_TYPES[tetrisGame.currentPiece]

        for row = 1, #shape do
            for col = 1, #shape[1] do
                if shape[row][col] == 1 then
                    local boardX = tetrisGame.pieceX + col - 1
                    local boardY = tetrisGame.pieceY + row - 1

                    if boardY >= 1 then
                        local cellX = tetrisGame.gridOffsetX + (boardX - 1) * tetrisGame.cellWidth
                        local cellY = tetrisGame.gridOffsetY + (boardY - 1) * tetrisGame.cellHeight

                        self:drawTetrisCell(cellX, cellY, pieceData.color, pieceData.char)
                    end
                end
            end
        end
    end

    self:drawNextPiecePreview()

    if tetrisGame.gameOver then
        local gameOverText = "GAME OVER"
        local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
        local textX = tetrisGame.gridOffsetX +
            (tetrisGame.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH - textWidth) / 2
        local textY = tetrisGame.gridOffsetY + tetrisGame.cellHeight * Constants.TETRIS_CONST.BOARD_HEIGHT / 2

        self.terminal:drawText(
            gameOverText, textX, textY,
            1, 1, 0.3, 0.3,
            Constants.UI_CONST.FONT.LARGE
        )

        self.terminal:renderFooter("GAME OVER! | PRESS SPACE OR BACKSPACE TO CONTINUE")
    else
        self.terminal:renderFooter("ARROWS - MOVE/ROTATE | SPACE - DROP | BACKSPACE - QUIT")
    end
end

function GamesModule:drawTetrisCell(x, y, color, char)
    self.terminal:drawRect(
        x, y,
        tetrisGame.cellWidth, tetrisGame.cellHeight,
        color.a, color.r, color.g, color.b
    )

    self.terminal:drawRectBorder(
        x, y,
        tetrisGame.cellWidth, tetrisGame.cellHeight,
        0.8, 1, 1, 1
    )

    self.terminal:drawRect(
        x, y,
        tetrisGame.cellWidth, 2,
        0.5, 1, 1, 1
    )

    self.terminal:drawRect(
        x, y,
        2, tetrisGame.cellHeight,
        0.5, 1, 1, 1
    )

    self.terminal:drawRect(
        x + tetrisGame.cellWidth - 2, y,
        2, tetrisGame.cellHeight,
        0.5, 0, 0, 0
    )

    self.terminal:drawRect(
        x, y + tetrisGame.cellHeight - 2,
        tetrisGame.cellWidth, 2,
        0.5, 0, 0, 0
    )

    local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, char)
    local textHeight = getTextManager():MeasureStringY(Constants.UI_CONST.FONT.MEDIUM, char)
    local textX = x + (tetrisGame.cellWidth - textWidth) / 2
    local textY = y + (tetrisGame.cellHeight - textHeight) / 2

    self.terminal:drawText(
        char, textX, textY,
        1, 1, 1, 1,
        Constants.UI_CONST.FONT.MEDIUM
    )
end

function GamesModule:drawNextPiecePreview()
    local nextPieceData = Constants.TETRIS_CONST.PIECE_TYPES[tetrisGame.nextPiece]
    local nextPieceShape = nextPieceData.shape

    local previewX = tetrisGame.gridOffsetX + tetrisGame.cellWidth * Constants.TETRIS_CONST.BOARD_WIDTH + 20
    local previewY = tetrisGame.gridOffsetY + 50

    self.terminal:drawText(
        "NEXT", previewX, previewY - 30,
        1, 1, 1, 1,
        Constants.UI_CONST.FONT.MEDIUM
    )

    local previewCellSize = math.floor(tetrisGame.cellWidth * 0.75)
    local previewWidth = 5 * previewCellSize + 10
    local previewHeight = 5 * previewCellSize + 10

    self.terminal:drawRect(
        previewX, previewY,
        previewWidth, previewHeight,
        0.5, 0.1, 0.1, 0.2
    )

    self.terminal:drawRectBorder(
        previewX, previewY,
        previewWidth, previewHeight,
        0.8, 0.3, 0.3, 0.5
    )

    for row = 1, 5 do
        for col = 1, 5 do
            if nextPieceShape[row][col] == 1 then
                local cellX = previewX + 5 + (col - 1) * previewCellSize
                local cellY = previewY + 5 + (row - 1) * previewCellSize

                self.terminal:drawRect(
                    cellX, cellY,
                    previewCellSize, previewCellSize,
                    nextPieceData.color.a, nextPieceData.color.r, nextPieceData.color.g, nextPieceData.color.b
                )

                self.terminal:drawRectBorder(
                    cellX, cellY,
                    previewCellSize, previewCellSize,
                    0.8, 1, 1, 1
                )

                local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.SMALL, nextPieceData.char)
                local textHeight = getTextManager():MeasureStringY(Constants.UI_CONST.FONT.SMALL, nextPieceData.char)
                local textX = cellX + (previewCellSize - textWidth) / 2
                local textY = cellY + (previewCellSize - textHeight) / 2

                self.terminal:drawText(
                    nextPieceData.char, textX, textY,
                    1, 1, 1, 1,
                    Constants.UI_CONST.FONT.SMALL
                )
            end
        end
    end

    local infoY = previewY + previewHeight + 10

    self.terminal:drawText(
        "LEVEL: " .. tetrisGame.level,
        previewX, infoY,
        1, 1, 1, 0.8,
        Constants.UI_CONST.FONT.MEDIUM
    )

    self.terminal:drawText(
        "LINES: " .. tetrisGame.lines,
        previewX, infoY + 20,
        1, 1, 1, 0.8,
        Constants.UI_CONST.FONT.MEDIUM
    )

    local controlsY = infoY + 50

    self.terminal:drawText(
        "CONTROLS:",
        previewX, controlsY,
        1, 0.8, 1, 0.8,
        Constants.UI_CONST.FONT.SMALL
    )

    self.terminal:drawText(
        "^: ROTATE",
        previewX, controlsY + 20,
        1, 0.8, 1, 0.8,
        Constants.UI_CONST.FONT.SMALL
    )

    self.terminal:drawText(
        "</>: MOVE",
        previewX, controlsY + 40,
        1, 0.8, 1, 0.8,
        Constants.UI_CONST.FONT.SMALL
    )

    self.terminal:drawText(
        "v: SOFT DROP",
        previewX, controlsY + 60,
        1, 0.8, 1, 0.8,
        Constants.UI_CONST.FONT.SMALL
    )

    self.terminal:drawText(
        "SPACE: HARD DROP",
        previewX, controlsY + 80,
        1, 0.8, 1, 0.8,
        Constants.UI_CONST.FONT.SMALL
    )
end
