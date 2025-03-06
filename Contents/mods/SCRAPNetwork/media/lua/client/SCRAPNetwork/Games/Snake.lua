local SCRAP_Terminal = require("SCRAPNetwork/ScrapOS_Terminal")
local TerminalSounds = require("SCRAPNetwork/ScrapOS_TerminalSoundsManager")

local Constants = require("SCRAPNetwork/Games/Constants")
local GamesModule = require("SCRAPNetwork/Games/Module")


table.insert(GamesModule.GAMES,
    {
        name = "Snake",
        description = "Navigate the snake to eat food and grow without hitting walls or yourself.",
        activate = function(self) self:activateSnake() end,
        preview = function(self, x, y, width, height, terminal)
            local previewOffsetX = x + 5
            local previewOffsetY = y + 5
            local previewWidth = width - 10
            local previewHeight = height - 10

            terminal:drawRect(
                previewOffsetX, previewOffsetY,
                previewWidth, previewHeight,
                Constants.SNAKE_CONST.COLORS.BACKGROUND.a,
                Constants.SNAKE_CONST.COLORS.BACKGROUND.r,
                Constants.SNAKE_CONST.COLORS.BACKGROUND.g,
                Constants.SNAKE_CONST.COLORS.BACKGROUND.b
            )

            local cellWidth = previewWidth / 15
            local cellHeight = previewHeight / 8

            local snakeSegments = {
                { x = 8, y = 4 },
                { x = 7, y = 4 },
                { x = 6, y = 4 },
                { x = 5, y = 4 },
                { x = 4, y = 4 }
            }

            for i, segment in ipairs(snakeSegments) do
                local segX = previewOffsetX + segment.x * cellWidth
                local segY = previewOffsetY + segment.y * cellHeight

                local r, g, b = Constants.SNAKE_CONST.COLORS.SNAKE.r, Constants.SNAKE_CONST.COLORS.SNAKE.g,
                    Constants.SNAKE_CONST.COLORS.SNAKE.b
                if i == 1 then
                    r = math.min(1, r + 0.2)
                    g = math.min(1, g + 0.2)
                    b = math.min(1, b + 0.2)
                end

                terminal:drawRect(
                    segX, segY,
                    cellWidth - 1, cellHeight - 1,
                    Constants.SNAKE_CONST.COLORS.SNAKE.a, r, g, b
                )
            end

            terminal:drawRect(
                previewOffsetX + 10 * cellWidth, previewOffsetY + 4 * cellHeight,
                cellWidth - 1, cellHeight - 1,
                Constants.SNAKE_CONST.COLORS.FOOD.a,
                Constants.SNAKE_CONST.COLORS.FOOD.r,
                Constants.SNAKE_CONST.COLORS.FOOD.g,
                Constants.SNAKE_CONST.COLORS.FOOD.b
            )
        end
    }
)


----------------------
-- SNAKE GAME CODE --
----------------------
local snakeGame = {
    snake = {},
    direction = Constants.SNAKE_CONST.DIRECTIONS.RIGHT,
    nextDirection = Constants.SNAKE_CONST.DIRECTIONS.RIGHT,
    food = { x = 0, y = 0 },
    score = 0,
    gameOver = false,
    lastUpdateTime = 0,
    gameOverTime = 0,
    gridOffsetX = 0,
    gridOffsetY = 0,
    cellWidth = 0,
    cellHeight = 0
}

function GamesModule:activateSnake()
    self.inGame = true

    local displayWidth = self.terminal.displayWidth
    local displayHeight = self.terminal.displayHeight

    local titleHeight = self.terminal.titleAreaHeight
    local footerHeight = self.terminal.footerAreaHeight
    local contentHeight = self.terminal.contentAreaHeight

    snakeGame.cellWidth = displayWidth / Constants.SNAKE_CONST.GRID_WIDTH
    snakeGame.cellHeight = contentHeight / Constants.SNAKE_CONST.GRID_HEIGHT

    snakeGame.gridOffsetX = self.terminal.displayX
    snakeGame.gridOffsetY = self.terminal.contentAreaY

    snakeGame.snake = {
        { x = 5, y = 7 },
        { x = 4, y = 7 },
        { x = 3, y = 7 }
    }

    snakeGame.direction = Constants.SNAKE_CONST.DIRECTIONS.RIGHT
    snakeGame.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.RIGHT
    snakeGame.score = 0
    snakeGame.gameOver = false
    snakeGame.lastUpdateTime = getTimeInMillis()

    self:placeFood()

    self.terminal:playRandomKeySound()
end

function GamesModule:placeFood()
    local grid = {}

    for _, segment in ipairs(snakeGame.snake) do
        local key = segment.x .. "," .. segment.y
        grid[key] = true
    end

    local availablePositions = {}
    for x = 0, Constants.SNAKE_CONST.GRID_WIDTH - 1 do
        for y = 0, Constants.SNAKE_CONST.GRID_HEIGHT - 1 do
            local key = x .. "," .. y
            if not grid[key] then
                table.insert(availablePositions, { x = x, y = y })
            end
        end
    end

    if #availablePositions > 0 then
        local position = availablePositions[ZombRand(1, #availablePositions + 1)]
        snakeGame.food = position
    end
end

function GamesModule:updateSnake()
    local currentTime = getTimeInMillis()

    if snakeGame.gameOver then
        if currentTime - snakeGame.gameOverTime >= Constants.SNAKE_CONST.GAME_OVER_DELAY then
            self:onActivate()
        end
        return
    end

    if currentTime - snakeGame.lastUpdateTime >= Constants.SNAKE_CONST.GAME_TICK then
        snakeGame.lastUpdateTime = currentTime

        snakeGame.direction = snakeGame.nextDirection

        local head = snakeGame.snake[1]

        local newHead = {
            x = head.x + snakeGame.direction.x,
            y = head.y + snakeGame.direction.y
        }

        if newHead.x < 0 or newHead.x >= Constants.SNAKE_CONST.GRID_WIDTH or
            newHead.y < 0 or newHead.y >= Constants.SNAKE_CONST.GRID_HEIGHT then
            self:snakeGameOver()
            return
        end

        for i = 1, #snakeGame.snake do
            if snakeGame.snake[i].x == newHead.x and snakeGame.snake[i].y == newHead.y then
                self:snakeGameOver()
                return
            end
        end

        table.insert(snakeGame.snake, 1, newHead)

        if newHead.x == snakeGame.food.x and newHead.y == snakeGame.food.y then
            snakeGame.score = snakeGame.score + 10

            TerminalSounds.playUISound("scrap_terminal_snake_eat_food")

            self:placeFood()
        else
            table.remove(snakeGame.snake)
        end
    end
end

function GamesModule:handleSnakeKeyPress(key)
    if snakeGame.gameOver then
        if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
            self:onActivate()
            return true
        end
        return false
    end

    if key == Keyboard.KEY_UP and snakeGame.direction.y == 0 then
        snakeGame.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.UP
        return true
    elseif key == Keyboard.KEY_DOWN and snakeGame.direction.y == 0 then
        snakeGame.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.DOWN
        return true
    elseif key == Keyboard.KEY_LEFT and snakeGame.direction.x == 0 then
        snakeGame.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.LEFT
        return true
    elseif key == Keyboard.KEY_RIGHT and snakeGame.direction.x == 0 then
        snakeGame.nextDirection = Constants.SNAKE_CONST.DIRECTIONS.RIGHT
        return true
    elseif key == Keyboard.KEY_BACK then
        self:onActivate()
        return true
    end

    return false
end

function GamesModule:renderSnake()
    self.terminal:renderTitle("SNAKE - SCORE: " .. snakeGame.score)

    self.terminal:drawRect(
        snakeGame.gridOffsetX,
        snakeGame.gridOffsetY,
        self.terminal.displayWidth,
        self.terminal.contentAreaHeight,
        Constants.SNAKE_CONST.COLORS.BACKGROUND.a,
        Constants.SNAKE_CONST.COLORS.BACKGROUND.r,
        Constants.SNAKE_CONST.COLORS.BACKGROUND.g,
        Constants.SNAKE_CONST.COLORS.BACKGROUND.b
    )

    for x = 0, Constants.SNAKE_CONST.GRID_WIDTH do
        local xPos = snakeGame.gridOffsetX + x * snakeGame.cellWidth
        self.terminal:drawRect(
            xPos,
            snakeGame.gridOffsetY,
            1,
            self.terminal.contentAreaHeight,
            Constants.SNAKE_CONST.COLORS.GRID.a,
            Constants.SNAKE_CONST.COLORS.GRID.r,
            Constants.SNAKE_CONST.COLORS.GRID.g,
            Constants.SNAKE_CONST.COLORS.GRID.b
        )
    end

    for y = 0, Constants.SNAKE_CONST.GRID_HEIGHT do
        local yPos = snakeGame.gridOffsetY + y * snakeGame.cellHeight
        self.terminal:drawRect(
            snakeGame.gridOffsetX,
            yPos,
            self.terminal.displayWidth,
            1,
            Constants.SNAKE_CONST.COLORS.GRID.a,
            Constants.SNAKE_CONST.COLORS.GRID.r,
            Constants.SNAKE_CONST.COLORS.GRID.g,
            Constants.SNAKE_CONST.COLORS.GRID.b
        )
    end

    local foodX = snakeGame.gridOffsetX + snakeGame.food.x * snakeGame.cellWidth
    local foodY = snakeGame.gridOffsetY + snakeGame.food.y * snakeGame.cellHeight
    self.terminal:drawRect(
        foodX,
        foodY,
        snakeGame.cellWidth,
        snakeGame.cellHeight,
        Constants.SNAKE_CONST.COLORS.FOOD.a,
        Constants.SNAKE_CONST.COLORS.FOOD.r,
        Constants.SNAKE_CONST.COLORS.FOOD.g,
        Constants.SNAKE_CONST.COLORS.FOOD.b
    )

    for i, segment in ipairs(snakeGame.snake) do
        local segmentX = snakeGame.gridOffsetX + segment.x * snakeGame.cellWidth
        local segmentY = snakeGame.gridOffsetY + segment.y * snakeGame.cellHeight

        local r, g, b, a = Constants.SNAKE_CONST.COLORS.SNAKE.r, Constants.SNAKE_CONST.COLORS.SNAKE.g,
            Constants.SNAKE_CONST.COLORS.SNAKE.b,
            Constants.SNAKE_CONST.COLORS.SNAKE.a
        if i == 1 then
            r = math.min(1, r + 0.2)
            g = math.min(1, g + 0.2)
            b = math.min(1, b + 0.2)
        end

        self.terminal:drawRect(
            segmentX,
            segmentY,
            snakeGame.cellWidth,
            snakeGame.cellHeight,
            a, r, g, b
        )
    end

    if snakeGame.gameOver then
        self.terminal:renderFooter("GAME OVER! SCORE: " .. snakeGame.score .. " | PRESS SPACE OR BACKSPACE TO CONTINUE")
    else
        self.terminal:renderFooter("ARROW KEYS - MOVE | BACKSPACE - QUIT GAME")
    end
end

function GamesModule:snakeGameOver()
    snakeGame.gameOver = true
    snakeGame.gameOverTime = getTimeInMillis()

    TerminalSounds.playUISound("scrap_terminal_snake_gameover")
end
