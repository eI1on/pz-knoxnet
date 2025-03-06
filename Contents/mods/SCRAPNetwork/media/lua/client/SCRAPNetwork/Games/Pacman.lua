local SCRAP_Terminal = require("SCRAPNetwork/ScrapOS_Terminal")
local TerminalSounds = require("SCRAPNetwork/ScrapOS_TerminalSoundsManager")

local Constants = require("SCRAPNetwork/Games/Constants")
local GamesModule = require("SCRAPNetwork/Games/Module")

local rand = newrandom()

table.insert(GamesModule.GAMES,
    {
        name = "Pacman",
        description = "Navigate the maze eating dots while avoiding ghosts.",
        activate = function(self) self:activatePacman() end,
        preview = function(self, x, y, width, height, terminal)
            local previewOffsetX = x + 5
            local previewOffsetY = y + 5
            local previewWidth = width - 10
            local previewHeight = height - 10

            terminal:drawRect(
                previewOffsetX, previewOffsetY,
                previewWidth, previewHeight,
                0.7, 0, 0, 0
            )

            local titleText = "PACMAN"
            local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, titleText)
            terminal:drawText(
                titleText,
                previewOffsetX + (previewWidth - textWidth) / 2,
                previewOffsetY + 5,
                1, 1, 1, 0,
                Constants.UI_CONST.FONT.MEDIUM
            )

            local pacmanTexture = getTexture("media/ui/Games/pacman/pacman_right.png")
            local ghostTexture = getTexture("media/ui/Games/pacman/blinky.png")
            local cherryTexture = getTexture("media/ui/Games/pacman/cherry.png")

            local iconSize = math.min(previewWidth / 8, previewHeight / 8)

            terminal:drawTextureScaled(
                pacmanTexture,
                previewOffsetX + previewWidth / 4 - iconSize / 2,
                previewOffsetY + previewHeight / 2 - iconSize / 2,
                iconSize, iconSize,
                1, 1, 1, 1
            )

            terminal:drawTextureScaled(
                ghostTexture,
                previewOffsetX + previewWidth * 2 / 3 - iconSize / 2,
                previewOffsetY + previewHeight / 2 - iconSize / 2,
                iconSize, iconSize,
                1, 1, 1, 1
            )

            terminal:drawTextureScaled(
                cherryTexture,
                previewOffsetX + previewWidth / 2 - iconSize / 2,
                previewOffsetY + previewHeight * 3 / 4 - iconSize / 2,
                iconSize * 0.8, iconSize * 0.8,
                1, 1, 1, 1
            )

            local dotSize = math.max(2, math.floor(iconSize / 6))
            for i = 1, 5 do
                terminal:drawRect(
                    previewOffsetX + previewWidth / 4 - iconSize / 2 - i * iconSize / 2,
                    previewOffsetY + previewHeight / 2,
                    dotSize, dotSize,
                    1, 1, 1, 1
                )
            end
        end
    }
)

local PACMAN_CONST = {
    GRID_WIDTH = 28,
    GRID_HEIGHT = 31,

    ENTITIES = {
        EMPTY = 0,
        WALL = 1,
        PELLET = 2,
        POWER_PELLET = 3,
        FRUIT = 4,
        PACMAN = 5,
        GHOST = 6,
        GHOST_HOME = 7
    },

    DIRECTIONS = {
        UP = { x = 0, y = -1 },
        DOWN = { x = 0, y = 1 },
        LEFT = { x = -1, y = 0 },
        RIGHT = { x = 1, y = 0 },
        NONE = { x = 0, y = 0 }
    },

    COLORS = {
        PACMAN = { r = 1, g = 1, b = 0, a = 1 },       -- yellow
        WALL = { r = 0, g = 0.3, b = 0.8, a = 1 },     -- blue
        PELLET = { r = 1, g = 1, b = 1, a = 1 },       -- white
        POWER_PELLET = { r = 1, g = 1, b = 1, a = 1 }, -- white
        FRUIT = { r = 1, g = 0, b = 0.5, a = 1 },      -- pink
        BACKGROUND = { r = 0, g = 0, b = 0, a = 1 },   -- black
        TEXT = { r = 1, g = 1, b = 1, a = 1 },         -- white
        SCORE = { r = 1, g = 0.8, b = 0, a = 1 },      -- gold

        -- ghost colors (for tinting)
        GHOST_FRIGHTENED = { r = 0, g = 0, b = 1, a = 1 },       -- blue
        GHOST_RETURNING = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 } -- translucent
    },

    GAME_TICK = 150,             -- base ms between game updates
    GHOST_TICK = 200,            -- ghost movement speed (ms)
    GHOST_FRIGHTENED_TICK = 300, -- slower frightened speed
    FRIGHTENED_TIME = 8000,      -- time ghosts remain frightened (ms)
    FRUIT_TIME = 10000,          -- time fruit remains visible (ms)
    GAME_OVER_DELAY = 3000,      -- delay after game over (ms)

    -- animation
    ANIMATION_FRAMES = 2,  -- number of animation frames
    ANIMATION_SPEED = 200, -- ms between animation frames

    -- points
    POINTS = {
        PELLET = 10,
        POWER_PELLET = 50,
        FRUIT = 100,
        GHOST = 200 -- multiplied by ghost combo (1-4)
    },

    TEXTURES = {
        PACMAN_RIGHT = "media/ui/Games/pacman/pacman_right.png",
        PACMAN_LEFT = "media/ui/Games/pacman/pacman_left.png",
        PACMAN_UP = "media/ui/Games/pacman/pacman_top.png",
        PACMAN_DOWN = "media/ui/Games/pacman/pacman_down.png",
        BLINKY = "media/ui/Games/pacman/blinky.png",
        PINKY = "media/ui/Games/pacman/pinky.png",
        INKY = "media/ui/Games/pacman/inky.png",
        CLYDE = "media/ui/Games/pacman/clyde.png",
        GHOST = "media/ui/Games/pacman/ghost.png",
        CHERRY = "media/ui/Games/pacman/cherry.png",
        STRAWBERRY = "media/ui/Games/pacman/strawberry.png"
    },

    -- initial level maze layout
    -- W = Wall, ' ' = Empty, . = Pellet, o = Power Pellet, H = Ghost home
    MAZE_LAYOUT = {
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "W............WW............W",
        "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
        "WoWWWW.WWWWW.WW.WWWWW.WWWWoW",
        "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
        "W..........................W",
        "W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
        "W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
        "W......WW....WW....WW......W",
        "WWWWWW.WWWWW WW WWWWW.WWWWWW",
        "WWWWWW.WWWWW WW WWWWW.WWWWWW",
        "WWWWWW.WW          WW.WWWWWW",
        "WWWWWW.WW WWWHHWWW WW.WWWWWW",
        "WWWWWW.WW W      W WW.WWWWWW",
        "      .   W      W   .      ",
        "WWWWWW.WW W      W WW.WWWWWW",
        "WWWWWW.WW WWWWWWWWW WW.WWWWWW",
        "WWWWWW.WW          WW.WWWWWW",
        "WWWWWW.WW WWWWWWWW WW.WWWWWW",
        "WWWWWW.WW WWWWWWWW WW.WWWWWW",
        "W............WW............W",
        "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
        "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
        "Wo..WW...............WW..oW",
        "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
        "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
        "W......WW....WW....WW......W",
        "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
        "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
        "W..........................W",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWW"
    }
}

local pacmanGame = {
    textures = {},

    animationFrame = 0,
    lastAnimationTime = 0,

    board = {},

    pacman = {
        x = 14,
        y = 23,
        direction = PACMAN_CONST.DIRECTIONS.LEFT,
        nextDirection = PACMAN_CONST.DIRECTIONS.LEFT,
        lives = 3,
        canMove = true
    },

    ghosts = {
        {
            name = "BLINKY", -- Red
            textureName = PACMAN_CONST.TEXTURES.BLINKY,
            x = 14,
            y = 11,
            direction = PACMAN_CONST.DIRECTIONS.LEFT,
            target = { x = 0, y = 0 },
            mode = "scatter", -- scatter, chase, frightened, returning, home
            homePosition = { x = 14, y = 13 },
            lastMoveTime = 0
        },
        {
            name = "PINKY", -- Pink
            textureName = PACMAN_CONST.TEXTURES.PINKY,
            x = 14,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.UP,
            target = { x = 0, y = 0 },
            mode = "home", -- scatter, chase, frightened, returning, home
            homePosition = { x = 12, y = 14 },
            lastMoveTime = 0,
            homeDelay = 1000
        },
        {
            name = "INKY", -- Cyan
            textureName = PACMAN_CONST.TEXTURES.INKY,
            x = 12,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.UP,
            target = { x = 0, y = 0 },
            mode = "home", -- scatter, chase, frightened, returning, home
            homePosition = { x = 16, y = 14 },
            lastMoveTime = 0,
            homeDelay = 3000
        },
        {
            name = "CLYDE", -- Orange
            textureName = PACMAN_CONST.TEXTURES.CLYDE,
            x = 16,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.LEFT,
            target = { x = 0, y = 0 },
            mode = "home", -- scatter, chase, frightened, returning, home
            homePosition = { x = 14, y = 14 },
            lastMoveTime = 0,
            homeDelay = 5000
        }
    },

    score = 0,
    level = 1,
    pelletCount = 0,
    totalPellets = 0,
    gameOver = false,
    gameWon = false,
    lastUpdateTime = 0,
    lastFruitTime = 0,
    ghostFrightenedEndTime = 0,
    ghostCombo = 0,
    gameOverTime = 0,
    currentFruit = PACMAN_CONST.TEXTURES.CHERRY,

    gridOffsetX = 0,
    gridOffsetY = 0
}

function GamesModule:activatePacman()
    self.inGame = true

    pacmanGame.textures = {}
    for _, texturePath in pairs(PACMAN_CONST.TEXTURES) do
        pacmanGame.textures[texturePath] = getTexture(texturePath)
    end

    local displayWidth = self.terminal.displayWidth
    local contentHeight = self.terminal.contentAreaHeight

    local maxHorizontalCellSize = (displayWidth - 20) / PACMAN_CONST.GRID_WIDTH
    local maxVerticalCellSize = (contentHeight - 40) / PACMAN_CONST.GRID_HEIGHT

    pacmanGame.cellSize = math.floor(math.min(maxHorizontalCellSize, maxVerticalCellSize))

    pacmanGame.cellSize = math.max(4, pacmanGame.cellSize)

    local boardWidth = PACMAN_CONST.GRID_WIDTH * pacmanGame.cellSize
    local boardHeight = PACMAN_CONST.GRID_HEIGHT * pacmanGame.cellSize

    pacmanGame.gridOffsetX = self.terminal.displayX + (displayWidth - boardWidth) / 2
    pacmanGame.gridOffsetY = self.terminal.contentAreaY + 10

    pacmanGame.board = {}
    pacmanGame.pelletCount = 0
    pacmanGame.totalPellets = 0

    for y = 1, PACMAN_CONST.GRID_HEIGHT do
        pacmanGame.board[y] = {}
        local row = PACMAN_CONST.MAZE_LAYOUT[y]

        for x = 1, PACMAN_CONST.GRID_WIDTH do
            local char = string.sub(row, x, x)
            local entity = PACMAN_CONST.ENTITIES.EMPTY

            if char == "W" then
                entity = PACMAN_CONST.ENTITIES.WALL
            elseif char == "." then
                entity = PACMAN_CONST.ENTITIES.PELLET
                pacmanGame.totalPellets = pacmanGame.totalPellets + 1
            elseif char == "o" then
                entity = PACMAN_CONST.ENTITIES.POWER_PELLET
                pacmanGame.totalPellets = pacmanGame.totalPellets + 1
            elseif char == "H" then
                entity = PACMAN_CONST.ENTITIES.GHOST_HOME
            end

            pacmanGame.board[y][x] = entity
        end
    end

    pacmanGame.pacman = {
        x = 14,
        y = 23,
        direction = PACMAN_CONST.DIRECTIONS.LEFT,
        nextDirection = PACMAN_CONST.DIRECTIONS.LEFT,
        lives = 3,
        canMove = true
    }

    pacmanGame.ghosts = {
        {
            name = "BLINKY", -- Red
            textureName = PACMAN_CONST.TEXTURES.BLINKY,
            x = 14,
            y = 11,
            direction = PACMAN_CONST.DIRECTIONS.LEFT,
            target = { x = 0, y = 0 },
            mode = "scatter", -- scatter, chase, frightened, returning, home
            homePosition = { x = 14, y = 13 },
            lastMoveTime = 0
        },
        {
            name = "PINKY", -- Pink
            textureName = PACMAN_CONST.TEXTURES.PINKY,
            x = 14,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.UP,
            target = { x = 0, y = 0 },
            mode = "home",
            homePosition = { x = 12, y = 14 },
            lastMoveTime = 0,
            homeDelay = 1000
        },
        {
            name = "INKY", -- Cyan
            textureName = PACMAN_CONST.TEXTURES.INKY,
            x = 12,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.UP,
            target = { x = 0, y = 0 },
            mode = "home",
            homePosition = { x = 16, y = 14 },
            lastMoveTime = 0,
            homeDelay = 3000
        },
        {
            name = "CLYDE", -- Orange
            textureName = PACMAN_CONST.TEXTURES.CLYDE,
            x = 16,
            y = 14,
            direction = PACMAN_CONST.DIRECTIONS.LEFT,
            target = { x = 0, y = 0 },
            mode = "home",
            homePosition = { x = 14, y = 14 },
            lastMoveTime = 0,
            homeDelay = 5000
        }
    }

    pacmanGame.score = 0
    pacmanGame.level = 1
    pacmanGame.gameOver = false
    pacmanGame.gameWon = false
    pacmanGame.lastUpdateTime = getTimeInMillis()
    pacmanGame.lastAnimationTime = getTimeInMillis()
    pacmanGame.animationFrame = 0
    pacmanGame.ghostFrightenedEndTime = 0
    pacmanGame.ghostCombo = 0
    pacmanGame.pelletCount = 0

    if pacmanGame.level == 1 then
        pacmanGame.currentFruit = PACMAN_CONST.TEXTURES.CHERRY
    else
        pacmanGame.currentFruit = PACMAN_CONST.TEXTURES.STRAWBERRY
    end

    pacmanGame.lastFruitTime = getTimeInMillis() + 10000

    self.terminal:playRandomKeySound()
    TerminalSounds.playUISound("scrap_terminal_pacman_start")
end

function GamesModule:isValidPacmanPosition(x, y)
    if x < 1 or x > PACMAN_CONST.GRID_WIDTH or
        y < 1 or y > PACMAN_CONST.GRID_HEIGHT then
        if y == 14 then
            if x < 1 then
                return true, PACMAN_CONST.GRID_WIDTH, y
            elseif x > PACMAN_CONST.GRID_WIDTH then
                return true, 1, y
            end
        end
        return false
    end

    if pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.WALL then
        return false
    end

    return true
end

function GamesModule:isValidGhostPosition(x, y, ghost)
    if x < 1 or x > PACMAN_CONST.GRID_WIDTH or
        y < 1 or y > PACMAN_CONST.GRID_HEIGHT then
        if y == 14 then
            if x < 1 then
                return true, PACMAN_CONST.GRID_WIDTH, y
            elseif x > PACMAN_CONST.GRID_WIDTH then
                return true, 1, y
            end
        end
        return false
    end

    if pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.WALL then
        return false
    end

    if ghost.mode == "frightened" or ghost.mode == "returning" then
        return true
    end

    local oppositeDir = self:getOppositeDirection(ghost.direction)
    local newDir = {
        x = x - ghost.x,
        y = y - ghost.y
    }

    if newDir.x == oppositeDir.x and newDir.y == oppositeDir.y then
        return false
    end

    return true
end

function GamesModule:getOppositeDirection(direction)
    if direction.x == PACMAN_CONST.DIRECTIONS.UP.x and
        direction.y == PACMAN_CONST.DIRECTIONS.UP.y then
        return PACMAN_CONST.DIRECTIONS.DOWN
    elseif direction.x == PACMAN_CONST.DIRECTIONS.DOWN.x and
        direction.y == PACMAN_CONST.DIRECTIONS.DOWN.y then
        return PACMAN_CONST.DIRECTIONS.UP
    elseif direction.x == PACMAN_CONST.DIRECTIONS.LEFT.x and
        direction.y == PACMAN_CONST.DIRECTIONS.LEFT.y then
        return PACMAN_CONST.DIRECTIONS.RIGHT
    elseif direction.x == PACMAN_CONST.DIRECTIONS.RIGHT.x and
        direction.y == PACMAN_CONST.DIRECTIONS.RIGHT.y then
        return PACMAN_CONST.DIRECTIONS.LEFT
    else
        return PACMAN_CONST.DIRECTIONS.NONE
    end
end

function GamesModule:calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

function GamesModule:getGhostTarget(ghost)
    local target = { x = 0, y = 0 }

    if ghost.mode == "returning" then
        target.x = ghost.homePosition.x
        target.y = ghost.homePosition.y
        return target
    end

    if ghost.mode == "frightened" then
        target.x = rand:random(1, PACMAN_CONST.GRID_WIDTH)
        target.y = rand:random(1, PACMAN_CONST.GRID_HEIGHT)
        return target
    end

    if ghost.mode == "scatter" then
        if ghost.name == "BLINKY" then
            target.x = PACMAN_CONST.GRID_WIDTH - 3
            target.y = 1
        elseif ghost.name == "PINKY" then
            target.x = 3
            target.y = 1
        elseif ghost.name == "INKY" then
            target.x = PACMAN_CONST.GRID_WIDTH - 1
            target.y = PACMAN_CONST.GRID_HEIGHT - 1
        elseif ghost.name == "CLYDE" then
            target.x = 1
            target.y = PACMAN_CONST.GRID_HEIGHT - 1
        end
        return target
    end

    if ghost.name == "BLINKY" then
        target.x = pacmanGame.pacman.x
        target.y = pacmanGame.pacman.y
    elseif ghost.name == "PINKY" then
        target.x = pacmanGame.pacman.x + 4 * pacmanGame.pacman.direction.x
        target.y = pacmanGame.pacman.y + 4 * pacmanGame.pacman.direction.y
    elseif ghost.name == "INKY" then
        local blinky = pacmanGame.ghosts[1]
        local tempX = pacmanGame.pacman.x + 2 * pacmanGame.pacman.direction.x
        local tempY = pacmanGame.pacman.y + 2 * pacmanGame.pacman.direction.y
        target.x = tempX + (tempX - blinky.x)
        target.y = tempY + (tempY - blinky.y)
    elseif ghost.name == "CLYDE" then
        local distance = self:calculateDistance(ghost.x, ghost.y, pacmanGame.pacman.x, pacmanGame.pacman.y)
        if distance > 8 then
            target.x = pacmanGame.pacman.x
            target.y = pacmanGame.pacman.y
        else
            target.x = 1
            target.y = PACMAN_CONST.GRID_HEIGHT - 1
        end
    end

    return target
end

function GamesModule:updateGhostMovement(ghost, currentTime)
    if ghost.mode == "home" and ghost.homeDelay and ghost.homeDelay > 0 then
        ghost.homeDelay = ghost.homeDelay - (currentTime - ghost.lastMoveTime)
        if ghost.homeDelay <= 0 then
            ghost.mode = "scatter"
        end
        ghost.lastMoveTime = currentTime
        return
    end

    local moveSpeed = PACMAN_CONST.GHOST_TICK
    if ghost.mode == "frightened" then
        moveSpeed = PACMAN_CONST.GHOST_FRIGHTENED_TICK
    end

    if currentTime - ghost.lastMoveTime < moveSpeed then
        return
    end

    ghost.target = self:getGhostTarget(ghost)

    local possibleDirections = {}
    local directions = {
        PACMAN_CONST.DIRECTIONS.UP,
        PACMAN_CONST.DIRECTIONS.LEFT,
        PACMAN_CONST.DIRECTIONS.DOWN,
        PACMAN_CONST.DIRECTIONS.RIGHT
    }

    for _, dir in ipairs(directions) do
        local newX = ghost.x + dir.x
        local newY = ghost.y + dir.y

        local valid, wrapX, wrapY = self:isValidGhostPosition(newX, newY, ghost)
        if valid then
            if wrapX and wrapY then
                newX, newY = wrapX, wrapY
            end

            local distance = self:calculateDistance(newX, newY, ghost.target.x, ghost.target.y)

            table.insert(possibleDirections, {
                direction = dir,
                x = newX,
                y = newY,
                distance = distance
            })
        end
    end

    if #possibleDirections == 0 then
        ghost.lastMoveTime = currentTime
        return
    end

    if ghost.mode == "frightened" then
        local randomIndex = rand:random(1, #possibleDirections)
        local chosen = possibleDirections[randomIndex]

        ghost.x = chosen.x
        ghost.y = chosen.y
        ghost.direction = chosen.direction
    else
        table.sort(possibleDirections, function(a, b)
            return a.distance < b.distance
        end)
        local chosen = possibleDirections[1]
        ghost.x = chosen.x
        ghost.y = chosen.y
        ghost.direction = chosen.direction
    end
    if ghost.mode == "returning" and
        ghost.x == ghost.homePosition.x and
        ghost.y == ghost.homePosition.y then
        ghost.mode = "scatter"
    end

    ghost.lastMoveTime = currentTime
end

function GamesModule:handlePacmanCollision()
    local x, y = pacmanGame.pacman.x, pacmanGame.pacman.y

    if pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.PELLET then
        pacmanGame.board[y][x] = PACMAN_CONST.ENTITIES.EMPTY
        pacmanGame.score = pacmanGame.score + PACMAN_CONST.POINTS.PELLET
        pacmanGame.pelletCount = pacmanGame.pelletCount + 1
        TerminalSounds.playUISound("scrap_terminal_pacman_eat_dot_0")
    elseif pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.POWER_PELLET then
        pacmanGame.board[y][x] = PACMAN_CONST.ENTITIES.EMPTY
        pacmanGame.score = pacmanGame.score + PACMAN_CONST.POINTS.POWER_PELLET
        pacmanGame.pelletCount = pacmanGame.pelletCount + 1

        pacmanGame.ghostFrightenedEndTime = getTimeInMillis() + PACMAN_CONST.FRIGHTENED_TIME
        pacmanGame.ghostCombo = 0

        for _, ghost in ipairs(pacmanGame.ghosts) do
            if ghost.mode ~= "returning" and ghost.mode ~= "home" then
                ghost.mode = "frightened"
                ghost.direction = self:getOppositeDirection(ghost.direction)
            end
        end

        TerminalSounds.playUISound("scrap_terminal_pacman_fright")
    elseif pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.FRUIT then
        pacmanGame.board[y][x] = PACMAN_CONST.ENTITIES.EMPTY
        pacmanGame.score = pacmanGame.score + PACMAN_CONST.POINTS.FRUIT
        TerminalSounds.playUISound("scrap_terminal_pacman_eat_fruit")
    end

    for _, ghost in ipairs(pacmanGame.ghosts) do
        if ghost.x == x and ghost.y == y then
            if ghost.mode == "frightened" then
                ghost.mode = "returning"

                pacmanGame.ghostCombo = pacmanGame.ghostCombo + 1
                pacmanGame.score = pacmanGame.score + PACMAN_CONST.POINTS.GHOST * pacmanGame.ghostCombo

                TerminalSounds.playUISound("scrap_terminal_pacman_eat_ghost")
            elseif ghost.mode ~= "returning" and ghost.mode ~= "home" then
                pacmanGame.pacman.lives = pacmanGame.pacman.lives - 1

                if pacmanGame.pacman.lives <= 0 then
                    pacmanGame.gameOver = true
                    pacmanGame.gameOverTime = getTimeInMillis()
                    TerminalSounds.playUISound("scrap_terminal_pacman_death_0")
                else
                    pacmanGame.pacman.x = 14
                    pacmanGame.pacman.y = 23
                    pacmanGame.pacman.direction = PACMAN_CONST.DIRECTIONS.LEFT
                    pacmanGame.pacman.nextDirection = PACMAN_CONST.DIRECTIONS.LEFT

                    pacmanGame.ghosts[1].x = 14
                    pacmanGame.ghosts[1].y = 11
                    pacmanGame.ghosts[1].mode = "scatter"

                    pacmanGame.ghosts[2].x = 14
                    pacmanGame.ghosts[2].y = 14
                    pacmanGame.ghosts[2].mode = "home"
                    pacmanGame.ghosts[2].homeDelay = 1000

                    pacmanGame.ghosts[3].x = 12
                    pacmanGame.ghosts[3].y = 14
                    pacmanGame.ghosts[3].mode = "home"
                    pacmanGame.ghosts[3].homeDelay = 3000

                    pacmanGame.ghosts[4].x = 16
                    pacmanGame.ghosts[4].y = 14
                    pacmanGame.ghosts[4].mode = "home"
                    pacmanGame.ghosts[4].homeDelay = 5000

                    TerminalSounds.playUISound("scrap_terminal_pacman_start")
                end
            end
        end
    end

    if pacmanGame.pelletCount >= pacmanGame.totalPellets then
        pacmanGame.gameWon = true
        pacmanGame.gameOver = true
        pacmanGame.gameOverTime = getTimeInMillis()
        TerminalSounds.playUISound("scrap_terminal_pacman_intermission")
    end
end

function GamesModule:updatePacman()
    local currentTime = getTimeInMillis()

    if pacmanGame.gameOver then
        if currentTime - pacmanGame.gameOverTime >= PACMAN_CONST.GAME_OVER_DELAY then
            self:onActivate()
        end
        return
    end

    if currentTime - pacmanGame.lastAnimationTime >= PACMAN_CONST.ANIMATION_SPEED then
        pacmanGame.animationFrame = (pacmanGame.animationFrame + 1) % PACMAN_CONST.ANIMATION_FRAMES
        pacmanGame.lastAnimationTime = currentTime
    end

    if currentTime - pacmanGame.lastFruitTime >= PACMAN_CONST.FRUIT_TIME then
        if pacmanGame.pelletCount > pacmanGame.totalPellets * 0.3 then
            local emptySpots = {}
            for y = 1, PACMAN_CONST.GRID_HEIGHT do
                for x = 1, PACMAN_CONST.GRID_WIDTH do
                    if pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.EMPTY then
                        table.insert(emptySpots, { x = x, y = y })
                    end
                end
            end

            if #emptySpots > 0 then
                local spot = emptySpots[rand:random(1, #emptySpots)]
                pacmanGame.board[spot.y][spot.x] = PACMAN_CONST.ENTITIES.FRUIT
            end
        end

        pacmanGame.lastFruitTime = currentTime + PACMAN_CONST.FRUIT_TIME
    end

    if pacmanGame.ghostFrightenedEndTime > 0 and currentTime >= pacmanGame.ghostFrightenedEndTime then
        pacmanGame.ghostFrightenedEndTime = 0
        for _, ghost in ipairs(pacmanGame.ghosts) do
            if ghost.mode == "frightened" then
                ghost.mode = "scatter"
            end
        end
    end

    local gameTick = math.max(50, PACMAN_CONST.GAME_TICK - ((pacmanGame.level - 1) * 10))

    if currentTime - pacmanGame.lastUpdateTime >= gameTick then
        local nextX = pacmanGame.pacman.x + pacmanGame.pacman.nextDirection.x
        local nextY = pacmanGame.pacman.y + pacmanGame.pacman.nextDirection.y

        local canChangeDirection, wrapX, wrapY = self:isValidPacmanPosition(nextX, nextY)

        if canChangeDirection then
            pacmanGame.pacman.direction = pacmanGame.pacman.nextDirection

            if wrapX and wrapY then
                pacmanGame.pacman.x, pacmanGame.pacman.y = wrapX, wrapY
            else
                pacmanGame.pacman.x = nextX
                pacmanGame.pacman.y = nextY
            end
        else
            nextX = pacmanGame.pacman.x + pacmanGame.pacman.direction.x
            nextY = pacmanGame.pacman.y + pacmanGame.pacman.direction.y

            local canContinue, wrapX, wrapY = self:isValidPacmanPosition(nextX, nextY)

            if canContinue then
                if wrapX and wrapY then
                    pacmanGame.pacman.x, pacmanGame.pacman.y = wrapX, wrapY
                else
                    pacmanGame.pacman.x = nextX
                    pacmanGame.pacman.y = nextY
                end
            end
        end
        self:handlePacmanCollision()

        pacmanGame.lastUpdateTime = currentTime
    end

    for _, ghost in ipairs(pacmanGame.ghosts) do
        self:updateGhostMovement(ghost, currentTime)
    end

    self:handlePacmanCollision()
end

function GamesModule:handlePacmanKeyPress(key)
    if pacmanGame.gameOver then
        if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
            self:onActivate()
            return true
        end
        return false
    end

    if key == Keyboard.KEY_UP then
        pacmanGame.pacman.nextDirection = PACMAN_CONST.DIRECTIONS.UP
        return true
    elseif key == Keyboard.KEY_DOWN then
        pacmanGame.pacman.nextDirection = PACMAN_CONST.DIRECTIONS.DOWN
        return true
    elseif key == Keyboard.KEY_LEFT then
        pacmanGame.pacman.nextDirection = PACMAN_CONST.DIRECTIONS.LEFT
        return true
    elseif key == Keyboard.KEY_RIGHT then
        pacmanGame.pacman.nextDirection = PACMAN_CONST.DIRECTIONS.RIGHT
        return true
    elseif key == Keyboard.KEY_BACK then
        self:onActivate()
        return true
    end

    return false
end

function GamesModule:renderPacman()
    self.terminal:renderTitle("PACMAN - SCORE: " .. pacmanGame.score .. " | LIVES: " .. pacmanGame.pacman.lives)

    self.terminal:drawRect(
        pacmanGame.gridOffsetX,
        pacmanGame.gridOffsetY,
        pacmanGame.cellSize * PACMAN_CONST.GRID_WIDTH,
        pacmanGame.cellSize * PACMAN_CONST.GRID_HEIGHT,
        PACMAN_CONST.COLORS.BACKGROUND.a,
        PACMAN_CONST.COLORS.BACKGROUND.r,
        PACMAN_CONST.COLORS.BACKGROUND.g,
        PACMAN_CONST.COLORS.BACKGROUND.b
    )

    for y = 1, PACMAN_CONST.GRID_HEIGHT do
        for x = 1, PACMAN_CONST.GRID_WIDTH do
            local cellX = pacmanGame.gridOffsetX + (x - 1) * pacmanGame.cellSize
            local cellY = pacmanGame.gridOffsetY + (y - 1) * pacmanGame.cellSize

            if pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.WALL then
                self.terminal:drawRect(
                    cellX, cellY,
                    pacmanGame.cellSize, pacmanGame.cellSize,
                    PACMAN_CONST.COLORS.WALL.a,
                    PACMAN_CONST.COLORS.WALL.r,
                    PACMAN_CONST.COLORS.WALL.g,
                    PACMAN_CONST.COLORS.WALL.b
                )
            elseif pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.PELLET then
                local dotSize = math.max(2, math.floor(pacmanGame.cellSize / 6))
                local dotX = cellX + (pacmanGame.cellSize - dotSize) / 2
                local dotY = cellY + (pacmanGame.cellSize - dotSize) / 2

                self.terminal:drawRect(
                    dotX, dotY, dotSize, dotSize,
                    PACMAN_CONST.COLORS.PELLET.a,
                    PACMAN_CONST.COLORS.PELLET.r,
                    PACMAN_CONST.COLORS.PELLET.g,
                    PACMAN_CONST.COLORS.PELLET.b
                )
            elseif pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.POWER_PELLET then
                local dotSize = math.max(3, math.floor(pacmanGame.cellSize / 3))
                local dotX = cellX + (pacmanGame.cellSize - dotSize) / 2
                local dotY = cellY + (pacmanGame.cellSize - dotSize) / 2

                self.terminal:drawRect(
                    dotX, dotY, dotSize, dotSize,
                    PACMAN_CONST.COLORS.POWER_PELLET.a,
                    PACMAN_CONST.COLORS.POWER_PELLET.r,
                    PACMAN_CONST.COLORS.POWER_PELLET.g,
                    PACMAN_CONST.COLORS.POWER_PELLET.b
                )
            elseif pacmanGame.board[y][x] == PACMAN_CONST.ENTITIES.FRUIT then
                local fruitTexture = pacmanGame.textures[pacmanGame.currentFruit]
                if fruitTexture then
                    self.terminal:drawTextureScaled(
                        fruitTexture,
                        cellX, cellY,
                        pacmanGame.cellSize, pacmanGame.cellSize,
                        1, 1, 1, 1
                    )
                end
            end
        end
    end

    local pacmanX = pacmanGame.gridOffsetX + (pacmanGame.pacman.x - 1) * pacmanGame.cellSize
    local pacmanY = pacmanGame.gridOffsetY + (pacmanGame.pacman.y - 1) * pacmanGame.cellSize

    local pacmanTexturePath = PACMAN_CONST.TEXTURES.PACMAN_RIGHT
    if pacmanGame.pacman.direction.x == PACMAN_CONST.DIRECTIONS.LEFT.x and
        pacmanGame.pacman.direction.y == PACMAN_CONST.DIRECTIONS.LEFT.y then
        pacmanTexturePath = PACMAN_CONST.TEXTURES.PACMAN_LEFT
    elseif pacmanGame.pacman.direction.x == PACMAN_CONST.DIRECTIONS.UP.x and
        pacmanGame.pacman.direction.y == PACMAN_CONST.DIRECTIONS.UP.y then
        pacmanTexturePath = PACMAN_CONST.TEXTURES.PACMAN_UP
    elseif pacmanGame.pacman.direction.x == PACMAN_CONST.DIRECTIONS.DOWN.x and
        pacmanGame.pacman.direction.y == PACMAN_CONST.DIRECTIONS.DOWN.y then
        pacmanTexturePath = PACMAN_CONST.TEXTURES.PACMAN_DOWN
    end

    local pacmanTexture = pacmanGame.textures[pacmanTexturePath]
    if pacmanTexture then
        local isMoving = false
        local nextX = pacmanGame.pacman.x + pacmanGame.pacman.direction.x
        local nextY = pacmanGame.pacman.y + pacmanGame.pacman.direction.y
        local _, _, _ = self:isValidPacmanPosition(nextX, nextY)
        isMoving = true

        -- for animation frame 0 (mouth open), draw normally
        -- for animation frame 1 (mouth closed), drawing rect or alternate texture, idk which yet
        if pacmanGame.animationFrame == 0 or not isMoving then
            self.terminal:drawTextureScaled(
                pacmanTexture,
                pacmanX, pacmanY,
                pacmanGame.cellSize, pacmanGame.cellSize,
                1, 1, 1, 1
            )
        else
            self.terminal:drawRect(
                pacmanX, pacmanY,
                pacmanGame.cellSize, pacmanGame.cellSize,
                1, 1, 1, 0
            )
        end
    end

    for _, ghost in ipairs(pacmanGame.ghosts) do
        local ghostX = pacmanGame.gridOffsetX + (ghost.x - 1) * pacmanGame.cellSize
        local ghostY = pacmanGame.gridOffsetY + (ghost.y - 1) * pacmanGame.cellSize

        local ghostTexture = nil
        local r, g, b, a = 1, 1, 1, 1

        if ghost.mode == "frightened" then
            ghostTexture = pacmanGame.textures[PACMAN_CONST.TEXTURES.GHOST]
            r, g, b = 0, 0, 1

            if pacmanGame.ghostFrightenedEndTime > 0 and
                (pacmanGame.ghostFrightenedEndTime - getTimeInMillis() < 2000) and
                (pacmanGame.animationFrame == 1) then
                r, g, b = 1, 1, 1
            end
        elseif ghost.mode == "returning" then
            ghostTexture = pacmanGame.textures[PACMAN_CONST.TEXTURES.GHOST]
            r, g, b, a = 1, 1, 1, 0.5
        else
            ghostTexture = pacmanGame.textures[ghost.textureName]
        end

        if ghostTexture then
            self.terminal:drawTextureScaled(
                ghostTexture,
                ghostX, ghostY,
                pacmanGame.cellSize, pacmanGame.cellSize,
                a, r, g, b
            )
        end
    end

    local livesIconSize = pacmanGame.cellSize * 0.8
    local livesSpacing = livesIconSize * 1.2
    local livesStartX = pacmanGame.gridOffsetX
    local livesY = pacmanGame.gridOffsetY + pacmanGame.cellSize * PACMAN_CONST.GRID_HEIGHT + 5

    local pacmanLifeTexture = pacmanGame.textures[PACMAN_CONST.TEXTURES.PACMAN_RIGHT]
    if pacmanLifeTexture then
        for i = 1, pacmanGame.pacman.lives - 1 do
            self.terminal:drawTextureScaled(
                pacmanLifeTexture,
                livesStartX + (i - 1) * livesSpacing, livesY,
                livesIconSize, livesIconSize,
                1, 1, 1, 1
            )
        end
    end

    if pacmanGame.gameOver then
        local gameOverText = pacmanGame.gameWon and "YOU WIN!" or "GAME OVER"
        local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
        local textX = pacmanGame.gridOffsetX + (pacmanGame.cellSize * PACMAN_CONST.GRID_WIDTH - textWidth) / 2
        local textY = pacmanGame.gridOffsetY + pacmanGame.cellSize * PACMAN_CONST.GRID_HEIGHT / 2

        self.terminal:drawRect(
            textX - 20, textY - 20,
            textWidth + 40, 60,
            0.8, 0, 0, 0
        )

        self.terminal:drawText(
            gameOverText, textX, textY,
            1, pacmanGame.gameWon and 0.3 or 1, pacmanGame.gameWon and 1 or 0.3, 0.3,
            Constants.UI_CONST.FONT.LARGE
        )

        self.terminal:renderFooter(gameOverText .. "! | PRESS SPACE OR BACKSPACE TO CONTINUE")
    else
        self.terminal:renderFooter("ARROWS - MOVE | BACKSPACE - QUIT")
    end
end
