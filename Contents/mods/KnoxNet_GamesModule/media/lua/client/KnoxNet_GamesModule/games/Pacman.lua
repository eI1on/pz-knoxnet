local getTexture = getTexture

local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local PacmanGame = {}

local GAME_INFO = {
	id = "pacman",
	name = "Pacman",
	description = "Navigate the maze eating dots while avoiding ghosts.",
}

local rand = newrandom()

local LEVELS = {
	{
		mazeLayout = {
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
			"W............WW............W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"WoWWWW.WWWWW.WW.WWWWW.WWWWoW",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"W..........................W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W......WW....WW....WW......W",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WW..........WW.WWWWWW",
			"WWWWWW.WW.WWWHHWWW.WW.WWWWWW",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"........W.        .W........",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW..........WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"W............WW............W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"Wo..WW................WW..oW",
			"WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
			"WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
			"W......WW....WW....WW......W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W..........................W",
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		},
		fruitValue = 100,
		ghostSpeed = Constants.PACMAN_CONST.GHOST_TICK,
		frightenedTime = Constants.PACMAN_CONST.FRIGHTENED_TIME,
	},
	{
		mazeLayout = {
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
			"W............WW............W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"WoWWWW.WWWWW.WW.WWWWW.WWWWoW",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"W..........................W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W......WW....WW....WW......W",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WW.WW.WW.WW.WW.WWWWWW",
			"WWWWWW.WW.WWWHHWWW.WW.WWWWWW",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"........W.        .W........",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW..........WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"W............WW............W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"Wo.WW..................WW.oW",
			"WW.WW.WW.WWWWWWWWWW.WW.WW.WW",
			"WW.WW.WW.WWWWWWWWWW.WW.WW.WW",
			"W.....WW.....WW.....WW.....W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W..........................W",
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		},
		fruitValue = 200,
		ghostSpeed = Constants.PACMAN_CONST.GHOST_TICK - 20,
		frightenedTime = Constants.PACMAN_CONST.FRIGHTENED_TIME - 1000,
	},
	{
		mazeLayout = {
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
			"W............WW............W",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"WoWWWW.WWWWW.WW.WWWWW.WWWWoW",
			"W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
			"W..........................W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
			"W......WW....WW....WW......W",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WW....WW....WW.WWWWWW",
			"WWWWWW.WW.WWWHHWWW.WW.WWWWWW",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"..........        ..........",
			"WWWWWW.WW.W      W.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW..........WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"WWWWWW.WW.WWWWWWWW.WW.WWWWWW",
			"W.....W......WW......W.....W",
			"W.WWW.W.WWWW.WW.WWWW.W.WWW.W",
			"W.WWW.W.WWWW.WW.WWWW.W.WWW.W",
			"Wo.W....................W.oW",
			"WW.W.WW.WWWWWWWWWWWW.WW.W.WW",
			"WW.W.WW.WWWWWWWWWWWW.WW.W.WW",
			"W............WW............W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
			"W..........................W",
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		},
		fruitValue = 300,
		ghostSpeed = Constants.PACMAN_CONST.GHOST_TICK - 40,
		frightenedTime = Constants.PACMAN_CONST.FRIGHTENED_TIME - 2000,
	},
	{
		mazeLayout = {
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
			"W.o......................o.W",
			"W.WWWWWWWW.WWWWWW.WWWWWWWW.W",
			"W.W......W.W....W.W......W.W",
			"W.W.WWWW.W.W.WW.W.W.WWWW.W.W",
			"W.W.W..W.W.W.WW.W.W.W..W.W.W",
			"W.W.W..W.W.W....W.W.W..W.W.W",
			"W.W.WWWW.W.WWWWWW.W.WWWW.W.W",
			"W.W......W........W......W.W",
			"W.WWWWWWWWWWWWWWWWWWWWWWWW.W",
			"W........................W.W",
			"WWWWWW.WWWWW.WW.WWWWW.WWWWWW",
			"WWWWWW.WWWWWWHHWWWWWW.WWWWWW",
			"WWWWWW.WWW        WWW.WWWWWW",
			"..........        ..........",
			"WWWWW.WW.W        W.WW.WWWWW",
			"WWWWW.WW.WWWWWWWWWW.WW.WWWWW",
			"WWWWW.WW............WW.WWWWW",
			"WWWWW.WW.WWWWWWWWWW.WW.WWWWW",
			"W..........................W",
			"W.WWWWWWWWWWWWWWWWWWWWWWWW.W",
			"W.W......W........W......W.W",
			"W.W.WWWW.W.WWWWWW.W.WWWW.W.W",
			"W.W.W..W.W.W....W.W.W..W.W.W",
			"W.W.W..W.W.W.WW.W.W.W..W.W.W",
			"W.W.WWWW.W.W.WW.W.W.WWWW.W.W",
			"W.W......W.W....W.W......W.W",
			"W.WWWWWWWW.WWWWWW.WWWWWWWW.W",
			"W...o....................o.W",
			"WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		},
		fruitValue = 500,
		ghostSpeed = Constants.PACMAN_CONST.GHOST_TICK - 60,
		frightenedTime = Constants.PACMAN_CONST.FRIGHTENED_TIME - 3000,
	},
}

PacmanGame.gameState = {
	textures = {},
	animationFrame = 0,
	lastAnimationTime = 0,
	board = {},
	pacman = {
		x = 14,
		y = 23,
		direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
		nextDirection = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
		lives = 3,
		canMove = true,
	},
	ghosts = table.newarray({
		name = "BLINKY", -- Red
		textureName = Constants.PACMAN_CONST.TEXTURES.BLINKY,
		x = 14,
		y = 11,
		direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
		target = { x = 0, y = 0 },
		mode = "scatter", -- scatter, chase, frightened, returning, home
		homePosition = { x = 14, y = 13 },
		lastMoveTime = 0,
	}, {
		name = "PINKY", -- Pink
		textureName = Constants.PACMAN_CONST.TEXTURES.PINKY,
		x = 14,
		y = 14,
		direction = Constants.PACMAN_CONST.DIRECTIONS.UP,
		target = { x = 0, y = 0 },
		mode = "home", -- scatter, chase, frightened, returning, home
		homePosition = { x = 12, y = 14 },
		lastMoveTime = 0,
		homeDelay = 1000,
	}, {
		name = "INKY", -- Cyan
		textureName = Constants.PACMAN_CONST.TEXTURES.INKY,
		x = 12,
		y = 14,
		direction = Constants.PACMAN_CONST.DIRECTIONS.UP,
		target = { x = 0, y = 0 },
		mode = "home", -- scatter, chase, frightened, returning, home
		homePosition = { x = 16, y = 14 },
		lastMoveTime = 0,
		homeDelay = 3000,
	}, {
		name = "CLYDE", -- Orange
		textureName = Constants.PACMAN_CONST.TEXTURES.CLYDE,
		x = 16,
		y = 14,
		direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
		target = { x = 0, y = 0 },
		mode = "home", -- scatter, chase, frightened, returning, home
		homePosition = { x = 14, y = 14 },
		lastMoveTime = 0,
		homeDelay = 5000,
	}),
	score = 0,
	level = 1,
	pelletCount = 0,
	totalPellets = 0,
	gameOver = false,
	gameWon = false,
	levelComplete = false,
	lastUpdateTime = 0,
	lastFruitTime = 0,
	ghostFrightenedEndTime = 0,
	ghostCombo = 0,
	gameOverTime = 0,
	levelCompleteTime = 0,
	currentFruit = Constants.PACMAN_CONST.TEXTURES.CHERRY,
	gridOffsetX = 0,
	gridOffsetY = 0,
	cellSize = 0,
}

function PacmanGame:resetState()
	self.gameState = {
		textures = self.gameState.textures or {},
		animationFrame = 0,
		lastAnimationTime = 0,
		board = {},
		pacman = {
			x = 14,
			y = 23,
			direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
			nextDirection = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
			lives = 3,
			canMove = true,
		},
		ghosts = table.newarray({
			name = "BLINKY", -- Red
			textureName = Constants.PACMAN_CONST.TEXTURES.BLINKY,
			x = 14,
			y = 11,
			direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
			target = { x = 0, y = 0 },
			mode = "scatter", -- scatter, chase, frightened, returning, home
			homePosition = { x = 14, y = 13 },
			lastMoveTime = 0,
		}, {
			name = "PINKY", -- Pink
			textureName = Constants.PACMAN_CONST.TEXTURES.PINKY,
			x = 14,
			y = 14,
			direction = Constants.PACMAN_CONST.DIRECTIONS.UP,
			target = { x = 0, y = 0 },
			mode = "home",
			homePosition = { x = 12, y = 14 },
			lastMoveTime = 0,
			homeDelay = 1000,
		}, {
			name = "INKY", -- Cyan
			textureName = Constants.PACMAN_CONST.TEXTURES.INKY,
			x = 12,
			y = 14,
			direction = Constants.PACMAN_CONST.DIRECTIONS.UP,
			target = { x = 0, y = 0 },
			mode = "home",
			homePosition = { x = 16, y = 14 },
			lastMoveTime = 0,
			homeDelay = 3000,
		}, {
			name = "CLYDE", -- Orange
			textureName = Constants.PACMAN_CONST.TEXTURES.CLYDE,
			x = 16,
			y = 14,
			direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT,
			target = { x = 0, y = 0 },
			mode = "home",
			homePosition = { x = 14, y = 14 },
			lastMoveTime = 0,
			homeDelay = 5000,
		}),
		score = self.gameState.score or 0,
		level = self.gameState.level or 1,
		pelletCount = 0,
		totalPellets = 0,
		gameOver = false,
		gameWon = false,
		levelComplete = false,
		lastUpdateTime = getTimeInMillis(),
		lastFruitTime = getTimeInMillis() + 10000,
		ghostFrightenedEndTime = 0,
		ghostCombo = 0,
		gameOverTime = 0,
		levelCompleteTime = 0,
		currentFruit = self:getFruitForLevel(self.gameState.level or 1),
		gridOffsetX = self.gameState.gridOffsetX or 0,
		gridOffsetY = self.gameState.gridOffsetY or 0,
		cellSize = self.gameState.cellSize or 0,
	}
end

function PacmanGame:getFruitForLevel(level)
	local fruitIndex = math.min(level, #Constants.PACMAN_CONST.FRUITS_BY_LEVEL)
	return Constants.PACMAN_CONST.FRUITS_BY_LEVEL[fruitIndex]
end

function PacmanGame:getCurrentLevelInfo()
	local levelIndex = math.min(self.gameState.level, #LEVELS)
	return LEVELS[levelIndex]
end

function PacmanGame:loadMaze()
	local levelInfo = self:getCurrentLevelInfo()
	local mazeLayout = levelInfo.mazeLayout

	self.gameState.board = {}
	self.gameState.pelletCount = 0
	self.gameState.totalPellets = 0

	for y = 1, Constants.PACMAN_CONST.GRID_HEIGHT do
		self.gameState.board[y] = {}
		local row = mazeLayout[y]

		for x = 1, Constants.PACMAN_CONST.GRID_WIDTH do
			local char = string.sub(row, x, x)
			local entity = Constants.PACMAN_CONST.ENTITIES.EMPTY

			if char == "W" then
				entity = Constants.PACMAN_CONST.ENTITIES.WALL
			elseif char == "." then
				entity = Constants.PACMAN_CONST.ENTITIES.PELLET
				self.gameState.totalPellets = self.gameState.totalPellets + 1
			elseif char == "o" then
				entity = Constants.PACMAN_CONST.ENTITIES.POWER_PELLET
				self.gameState.totalPellets = self.gameState.totalPellets + 1
			elseif char == "H" then
				entity = Constants.PACMAN_CONST.ENTITIES.GHOST_HOME
			end

			self.gameState.board[y][x] = entity
		end
	end
end

function PacmanGame:initializeNewLevel()
	self:loadMaze()

	self.gameState.pacman.x = 14
	self.gameState.pacman.y = 23
	self.gameState.pacman.direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT
	self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.LEFT

	self.gameState.ghosts[1].x = 14
	self.gameState.ghosts[1].y = 11
	self.gameState.ghosts[1].mode = "scatter"

	self.gameState.ghosts[2].x = 14
	self.gameState.ghosts[2].y = 14
	self.gameState.ghosts[2].mode = "home"
	self.gameState.ghosts[2].homeDelay = 1000

	self.gameState.ghosts[3].x = 12
	self.gameState.ghosts[3].y = 14
	self.gameState.ghosts[3].mode = "home"
	self.gameState.ghosts[3].homeDelay = 3000

	self.gameState.ghosts[4].x = 16
	self.gameState.ghosts[4].y = 14
	self.gameState.ghosts[4].mode = "home"
	self.gameState.ghosts[4].homeDelay = 5000

	self.gameState.gameOver = false
	self.gameState.gameWon = false
	self.gameState.levelComplete = false
	self.gameState.lastUpdateTime = getTimeInMillis()
	self.gameState.lastFruitTime = getTimeInMillis() + 10000
	self.gameState.ghostFrightenedEndTime = 0
	self.gameState.ghostCombo = 0
	self.gameState.pelletCount = 0

	self.gameState.currentFruit = self:getFruitForLevel(self.gameState.level)
end

function PacmanGame:activate(gamesModule)
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	self.gameState.textures = {}
	for _, texturePath in pairs(Constants.PACMAN_CONST.TEXTURES) do
		self.gameState.textures[texturePath] = getTexture(texturePath)
	end

	self:resetState()

	local displayWidth = self.terminal.displayWidth
	local contentHeight = self.terminal.contentAreaHeight

	local maxHorizontalCellSize = (displayWidth - 20) / Constants.PACMAN_CONST.GRID_WIDTH
	local maxVerticalCellSize = (contentHeight - 40) / Constants.PACMAN_CONST.GRID_HEIGHT

	self.gameState.cellSize = math.floor(math.min(maxHorizontalCellSize, maxVerticalCellSize))
	self.gameState.cellSize = math.max(4, self.gameState.cellSize)

	local boardWidth = Constants.PACMAN_CONST.GRID_WIDTH * self.gameState.cellSize
	local boardHeight = Constants.PACMAN_CONST.GRID_HEIGHT * self.gameState.cellSize

	self.gameState.gridOffsetX = self.terminal.displayX + (displayWidth - boardWidth) / 2
	self.gameState.gridOffsetY = self.terminal.contentAreaY + 10

	self:loadMaze()

	self.terminal:playRandomKeySound()
	TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
end

function PacmanGame:onDeactivate() end

function PacmanGame:preview(x, y, width, height, terminal, gamesModule)
	local previewOffsetX = x + 5
	local previewOffsetY = y + 5
	local previewWidth = width - 10
	local previewHeight = height - 10

	terminal:drawRect(previewOffsetX, previewOffsetY, previewWidth, previewHeight, 0.7, 0, 0, 0)

	local titleText = "PACMAN"
	local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, titleText)
	terminal:drawText(
		titleText,
		previewOffsetX + (previewWidth - textWidth) / 2,
		previewOffsetY + 5,
		1,
		1,
		1,
		0,
		Constants.UI_CONST.FONT.MEDIUM
	)

	local pacmanTexture = getTexture("media/ui/KnoxNet_GamesModule/pacman/ui_knoxnet_pacman_pacman_left.png")
	local ghostTexture = getTexture("media/ui/KnoxNet_GamesModule/pacman/ui_knoxnet_pacman_blinky.png")
	local cherryTexture = getTexture("media/ui/KnoxNet_GamesModule/pacman/ui_knoxnet_pacman_cherry.png")

	local iconSize = math.min(previewWidth / 8, previewHeight / 8)

	terminal:drawTextureScaled(
		pacmanTexture,
		previewOffsetX + previewWidth / 4 - iconSize / 2,
		previewOffsetY + previewHeight / 2 - iconSize / 2,
		iconSize,
		iconSize,
		1,
		1,
		1,
		1
	)

	terminal:drawTextureScaled(
		ghostTexture,
		previewOffsetX + previewWidth * 2 / 3 - iconSize / 2,
		previewOffsetY + previewHeight / 2 - iconSize / 2,
		iconSize,
		iconSize,
		1,
		1,
		1,
		1
	)

	terminal:drawTextureScaled(
		cherryTexture,
		previewOffsetX + previewWidth / 2 - iconSize / 2,
		previewOffsetY + previewHeight * 3 / 4 - iconSize / 2,
		iconSize * 0.8,
		iconSize * 0.8,
		1,
		1,
		1,
		1
	)

	local dotSize = math.max(2, math.floor(iconSize / 6))
	for i = 1, 5 do
		terminal:drawRect(
			previewOffsetX + previewWidth / 4 - iconSize / 2 - i * iconSize / 2,
			previewOffsetY + previewHeight / 2,
			dotSize,
			dotSize,
			1,
			1,
			1,
			1
		)
	end
end

function PacmanGame:onKeyPress(key, gamesModule)
	if self.gameState.gameOver or self.gameState.levelComplete then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			if self.gameState.levelComplete then
				self.gameState.level = self.gameState.level + 1
				self.gameState.levelComplete = false
				self:initializeNewLevel()
			else
				gamesModule:onActivate()
			end
			return true
		end
		return false
	end

	if key == Keyboard.KEY_UP then
		self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.UP
		return true
	elseif key == Keyboard.KEY_DOWN then
		self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.DOWN
		return true
	elseif key == Keyboard.KEY_LEFT then
		self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.LEFT
		return true
	elseif key == Keyboard.KEY_RIGHT then
		self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.RIGHT
		return true
	elseif key == Keyboard.KEY_BACK then
		gamesModule:onActivate()
		return true
	end

	return false
end

function PacmanGame:update(gamesModule)
	local currentTime = getTimeInMillis()

	if self.gameState.gameOver then
		if currentTime - self.gameState.gameOverTime >= Constants.PACMAN_CONST.GAME_OVER_DELAY then
			gamesModule:onActivate()
		end
		return
	end

	if self.gameState.levelComplete then
		if currentTime - self.gameState.levelCompleteTime >= Constants.PACMAN_CONST.LEVEL_COMPLETE_DELAY then
			self.gameState.level = self.gameState.level + 1
			self.gameState.levelComplete = false
			self:initializeNewLevel()
		end
		return
	end

	if currentTime - self.gameState.lastAnimationTime >= Constants.PACMAN_CONST.ANIMATION_SPEED then
		self.gameState.animationFrame = (self.gameState.animationFrame + 1) % Constants.PACMAN_CONST.ANIMATION_FRAMES
		self.gameState.lastAnimationTime = currentTime
	end

	if currentTime - self.gameState.lastFruitTime >= Constants.PACMAN_CONST.FRUIT_TIME then
		if self.gameState.pelletCount > self.gameState.totalPellets * 0.3 then
			local emptySpots = table.newarray() --[[@as table]]
			for y = 1, Constants.PACMAN_CONST.GRID_HEIGHT do
				for x = 1, Constants.PACMAN_CONST.GRID_WIDTH do
					if self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.EMPTY then
						table.insert(emptySpots, { x = x, y = y })
					end
				end
			end

			if #emptySpots > 0 then
				local spot = emptySpots[rand:random(1, #emptySpots)]
				self.gameState.board[spot.y][spot.x] = Constants.PACMAN_CONST.ENTITIES.FRUIT
			end
		end

		self.gameState.lastFruitTime = currentTime + Constants.PACMAN_CONST.FRUIT_TIME
	end

	local levelInfo = self:getCurrentLevelInfo()

	if self.gameState.ghostFrightenedEndTime > 0 and currentTime >= self.gameState.ghostFrightenedEndTime then
		self.gameState.ghostFrightenedEndTime = 0
		for i = 1, #self.gameState.ghosts do
			local ghost = self.gameState.ghosts[i]
			if ghost.mode == "frightened" then
				ghost.mode = "scatter"
			end
		end
	end

	local gameTick = math.max(50, Constants.PACMAN_CONST.GAME_TICK - ((self.gameState.level - 1) * 5))

	if currentTime - self.gameState.lastUpdateTime >= gameTick then
		local nextX = self.gameState.pacman.x + self.gameState.pacman.nextDirection.x
		local nextY = self.gameState.pacman.y + self.gameState.pacman.nextDirection.y

		local canChangeDirection, wrapX, wrapY = self:isValidPacmanPosition(nextX, nextY)

		if canChangeDirection then
			self.gameState.pacman.direction = self.gameState.pacman.nextDirection

			if wrapX and wrapY then
				self.gameState.pacman.x, self.gameState.pacman.y = wrapX, wrapY
			else
				self.gameState.pacman.x = nextX
				self.gameState.pacman.y = nextY
			end
		else
			nextX = self.gameState.pacman.x + self.gameState.pacman.direction.x
			nextY = self.gameState.pacman.y + self.gameState.pacman.direction.y

			local canContinue, wrapX, wrapY = self:isValidPacmanPosition(nextX, nextY)

			if canContinue then
				if wrapX and wrapY then
					self.gameState.pacman.x, self.gameState.pacman.y = wrapX, wrapY
				else
					self.gameState.pacman.x = nextX
					self.gameState.pacman.y = nextY
				end
			end
		end
		self:handlePacmanCollision()

		self.gameState.lastUpdateTime = currentTime
	end

	for i = 1, #self.gameState.ghosts do
		local ghost = self.gameState.ghosts[i]
		self:updateGhostMovement(ghost, currentTime)
	end

	self:handlePacmanCollision()
end

function PacmanGame:render(gamesModule)
	local terminal = gamesModule.terminal
	terminal:renderTitle(
		"PACMAN - LEVEL: "
			.. self.gameState.level
			.. " | SCORE: "
			.. self.gameState.score
			.. " | LIVES: "
			.. self.gameState.pacman.lives
	)

	terminal:drawRect(
		self.gameState.gridOffsetX,
		self.gameState.gridOffsetY,
		self.gameState.cellSize * Constants.PACMAN_CONST.GRID_WIDTH,
		self.gameState.cellSize * Constants.PACMAN_CONST.GRID_HEIGHT,
		Constants.PACMAN_CONST.COLORS.BACKGROUND.a,
		Constants.PACMAN_CONST.COLORS.BACKGROUND.r,
		Constants.PACMAN_CONST.COLORS.BACKGROUND.g,
		Constants.PACMAN_CONST.COLORS.BACKGROUND.b
	)

	for y = 1, Constants.PACMAN_CONST.GRID_HEIGHT do
		for x = 1, Constants.PACMAN_CONST.GRID_WIDTH do
			local cellX = self.gameState.gridOffsetX + (x - 1) * self.gameState.cellSize
			local cellY = self.gameState.gridOffsetY + (y - 1) * self.gameState.cellSize

			if self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.WALL then
				terminal:drawRect(
					cellX,
					cellY,
					self.gameState.cellSize,
					self.gameState.cellSize,
					Constants.PACMAN_CONST.COLORS.WALL.a,
					Constants.PACMAN_CONST.COLORS.WALL.r,
					Constants.PACMAN_CONST.COLORS.WALL.g,
					Constants.PACMAN_CONST.COLORS.WALL.b
				)
			elseif self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.PELLET then
				local dotSize = math.max(2, math.floor(self.gameState.cellSize / 6))
				local dotX = cellX + (self.gameState.cellSize - dotSize) / 2
				local dotY = cellY + (self.gameState.cellSize - dotSize) / 2

				terminal:drawRect(
					dotX,
					dotY,
					dotSize,
					dotSize,
					Constants.PACMAN_CONST.COLORS.PELLET.a,
					Constants.PACMAN_CONST.COLORS.PELLET.r,
					Constants.PACMAN_CONST.COLORS.PELLET.g,
					Constants.PACMAN_CONST.COLORS.PELLET.b
				)
			elseif self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.POWER_PELLET then
				local dotSize = math.max(3, math.floor(self.gameState.cellSize / 3))
				local dotX = cellX + (self.gameState.cellSize - dotSize) / 2
				local dotY = cellY + (self.gameState.cellSize - dotSize) / 2

				terminal:drawRect(
					dotX,
					dotY,
					dotSize,
					dotSize,
					Constants.PACMAN_CONST.COLORS.POWER_PELLET.a,
					Constants.PACMAN_CONST.COLORS.POWER_PELLET.r,
					Constants.PACMAN_CONST.COLORS.POWER_PELLET.g,
					Constants.PACMAN_CONST.COLORS.POWER_PELLET.b
				)
			elseif self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.FRUIT then
				local fruitTexture = self.gameState.textures[self.gameState.currentFruit]
				if fruitTexture then
					terminal:drawTextureScaled(
						fruitTexture,
						cellX,
						cellY,
						self.gameState.cellSize,
						self.gameState.cellSize,
						1,
						1,
						1,
						1
					)
				end
			end
		end
	end

	local pacmanX = self.gameState.gridOffsetX + (self.gameState.pacman.x - 1) * self.gameState.cellSize
	local pacmanY = self.gameState.gridOffsetY + (self.gameState.pacman.y - 1) * self.gameState.cellSize

	local pacmanTexturePath = Constants.PACMAN_CONST.TEXTURES.PACMAN_RIGHT
	if
		self.gameState.pacman.direction.x == Constants.PACMAN_CONST.DIRECTIONS.LEFT.x
		and self.gameState.pacman.direction.y == Constants.PACMAN_CONST.DIRECTIONS.LEFT.y
	then
		pacmanTexturePath = Constants.PACMAN_CONST.TEXTURES.PACMAN_LEFT
	elseif
		self.gameState.pacman.direction.x == Constants.PACMAN_CONST.DIRECTIONS.UP.x
		and self.gameState.pacman.direction.y == Constants.PACMAN_CONST.DIRECTIONS.UP.y
	then
		pacmanTexturePath = Constants.PACMAN_CONST.TEXTURES.PACMAN_UP
	elseif
		self.gameState.pacman.direction.x == Constants.PACMAN_CONST.DIRECTIONS.DOWN.x
		and self.gameState.pacman.direction.y == Constants.PACMAN_CONST.DIRECTIONS.DOWN.y
	then
		pacmanTexturePath = Constants.PACMAN_CONST.TEXTURES.PACMAN_DOWN
	end

	local pacmanTexture = self.gameState.textures[pacmanTexturePath]
	if pacmanTexture then
		-- for animation frame 0 (mouth open), draw normally
		-- for animation frame 1 (mouth closed), drawing rect or alternate texture, idk which yet
		if self.gameState.animationFrame == 0 then
			terminal:drawTextureScaled(
				pacmanTexture,
				pacmanX,
				pacmanY,
				self.gameState.cellSize,
				self.gameState.cellSize,
				1,
				1,
				1,
				1
			)
		else
			terminal:drawRect(pacmanX, pacmanY, self.gameState.cellSize, self.gameState.cellSize, 1, 1, 1, 0)
		end
	end

	for i = 1, #self.gameState.ghosts do
		local ghost = self.gameState.ghosts[i]
		local ghostX = self.gameState.gridOffsetX + (ghost.x - 1) * self.gameState.cellSize
		local ghostY = self.gameState.gridOffsetY + (ghost.y - 1) * self.gameState.cellSize

		local ghostTexture = nil
		local r, g, b, a = 1, 1, 1, 1

		if ghost.mode == "frightened" then
			ghostTexture = self.gameState.textures[Constants.PACMAN_CONST.TEXTURES.GHOST]
			r, g, b = 0, 0, 1

			if
				self.gameState.ghostFrightenedEndTime > 0
				and (self.gameState.ghostFrightenedEndTime - getTimeInMillis() < 2000)
				and (self.gameState.animationFrame == 1)
			then
				r, g, b = 1, 1, 1
			end
		elseif ghost.mode == "returning" then
			ghostTexture = self.gameState.textures[Constants.PACMAN_CONST.TEXTURES.GHOST]
			r, g, b, a = 1, 1, 1, 0.5
		else
			ghostTexture = self.gameState.textures[ghost.textureName]
		end

		if ghostTexture then
			terminal:drawTextureScaled(
				ghostTexture,
				ghostX,
				ghostY,
				self.gameState.cellSize,
				self.gameState.cellSize,
				a,
				r,
				g,
				b
			)
		end
	end

	local livesIconSize = self.gameState.cellSize * 1.75
	local livesSpacing = livesIconSize * 1.2
	local livesStartX = self.gameState.gridOffsetX
	local livesY = self.gameState.gridOffsetY + self.gameState.cellSize * Constants.PACMAN_CONST.GRID_HEIGHT + 5

	local pacmanLifeTexture = self.gameState.textures[Constants.PACMAN_CONST.TEXTURES.PACMAN_RIGHT]
	if pacmanLifeTexture then
		for i = 1, self.gameState.pacman.lives - 1 do
			terminal:drawTextureScaled(
				pacmanLifeTexture,
				livesStartX + (i - 1) * livesSpacing,
				livesY,
				livesIconSize,
				livesIconSize,
				1,
				1,
				1,
				1
			)
		end
	end

	if self.gameState.gameOver then
		local gameOverText = self.gameState.gameWon and "YOU WIN!" or "GAME OVER"
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
		local textX = self.gameState.gridOffsetX
			+ (self.gameState.cellSize * Constants.PACMAN_CONST.GRID_WIDTH - textWidth) / 2
		local textY = self.gameState.gridOffsetY + self.gameState.cellSize * Constants.PACMAN_CONST.GRID_HEIGHT / 2

		terminal:drawRect(textX - 20, textY - 20, textWidth + 40, 60, 0.8, 0, 0, 0)

		terminal:drawText(
			gameOverText,
			textX,
			textY,
			1,
			self.gameState.gameWon and 0.3 or 1,
			self.gameState.gameWon and 1 or 0.3,
			0.3,
			Constants.UI_CONST.FONT.LARGE
		)

		terminal:renderFooter(gameOverText .. "! | PRESS SPACE OR BACKSPACE TO CONTINUE")
	else
		if self.gameState.levelComplete then
			local levelCompleteText = "LEVEL " .. self.gameState.level .. " COMPLETE!"
			local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, levelCompleteText)
			local textX = self.gameState.gridOffsetX
				+ (self.gameState.cellSize * Constants.PACMAN_CONST.GRID_WIDTH - textWidth) / 2
			local textY = self.gameState.gridOffsetY + self.gameState.cellSize * Constants.PACMAN_CONST.GRID_HEIGHT / 2

			terminal:drawRect(textX - 20, textY - 20, textWidth + 40, 60, 0.8, 0, 0, 0)

			terminal:drawText(levelCompleteText, textX, textY, 1, 0.3, 1, 0.3, Constants.UI_CONST.FONT.LARGE)

			terminal:renderFooter("LEVEL COMPLETE! | PRESS SPACE TO CONTINUE")
		else
			terminal:renderFooter("ARROWS - MOVE | BACKSPACE - QUIT")
		end
	end
end

function PacmanGame:isValidPacmanPosition(x, y)
	if x < 1 or x > Constants.PACMAN_CONST.GRID_WIDTH or y < 1 or y > Constants.PACMAN_CONST.GRID_HEIGHT then
		if y == 14 then
			if x < 1 then
				return true, Constants.PACMAN_CONST.GRID_WIDTH, y
			elseif x > Constants.PACMAN_CONST.GRID_WIDTH then
				return true, 1, y
			end
		end
		return false
	end

	if self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.WALL then
		return false
	end

	return true
end

function PacmanGame:isValidGhostPosition(x, y, ghost)
	if x < 1 or x > Constants.PACMAN_CONST.GRID_WIDTH or y < 1 or y > Constants.PACMAN_CONST.GRID_HEIGHT then
		if y == 14 then
			if x < 1 then
				return true, Constants.PACMAN_CONST.GRID_WIDTH, y
			elseif x > Constants.PACMAN_CONST.GRID_WIDTH then
				return true, 1, y
			end
		end
		return false
	end

	if self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.WALL then
		return false
	end

	if ghost.mode == "frightened" or ghost.mode == "returning" then
		return true
	end

	local oppositeDir = self:getOppositeDirection(ghost.direction)
	local newDir = {
		x = x - ghost.x,
		y = y - ghost.y,
	}

	if newDir.x == oppositeDir.x and newDir.y == oppositeDir.y then
		return false
	end

	return true
end

function PacmanGame:getOppositeDirection(direction)
	if
		direction.x == Constants.PACMAN_CONST.DIRECTIONS.UP.x
		and direction.y == Constants.PACMAN_CONST.DIRECTIONS.UP.y
	then
		return Constants.PACMAN_CONST.DIRECTIONS.DOWN
	elseif
		direction.x == Constants.PACMAN_CONST.DIRECTIONS.DOWN.x
		and direction.y == Constants.PACMAN_CONST.DIRECTIONS.DOWN.y
	then
		return Constants.PACMAN_CONST.DIRECTIONS.UP
	elseif
		direction.x == Constants.PACMAN_CONST.DIRECTIONS.LEFT.x
		and direction.y == Constants.PACMAN_CONST.DIRECTIONS.LEFT.y
	then
		return Constants.PACMAN_CONST.DIRECTIONS.RIGHT
	elseif
		direction.x == Constants.PACMAN_CONST.DIRECTIONS.RIGHT.x
		and direction.y == Constants.PACMAN_CONST.DIRECTIONS.RIGHT.y
	then
		return Constants.PACMAN_CONST.DIRECTIONS.LEFT
	else
		return Constants.PACMAN_CONST.DIRECTIONS.NONE
	end
end

function PacmanGame:calculateDistance(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

function PacmanGame:getGhostTarget(ghost)
	local target = { x = 0, y = 0 }

	if ghost.mode == "returning" then
		target.x = ghost.homePosition.x
		target.y = ghost.homePosition.y
		return target
	end

	if ghost.mode == "frightened" then
		target.x = rand:random(1, Constants.PACMAN_CONST.GRID_WIDTH)
		target.y = rand:random(1, Constants.PACMAN_CONST.GRID_HEIGHT)
		return target
	end

	if ghost.mode == "scatter" then
		if ghost.name == "BLINKY" then
			target.x = Constants.PACMAN_CONST.GRID_WIDTH - 3
			target.y = 1
		elseif ghost.name == "PINKY" then
			target.x = 3
			target.y = 1
		elseif ghost.name == "INKY" then
			target.x = Constants.PACMAN_CONST.GRID_WIDTH - 1
			target.y = Constants.PACMAN_CONST.GRID_HEIGHT - 1
		elseif ghost.name == "CLYDE" then
			target.x = 1
			target.y = Constants.PACMAN_CONST.GRID_HEIGHT - 1
		end
		return target
	end

	if ghost.name == "BLINKY" then
		target.x = self.gameState.pacman.x
		target.y = self.gameState.pacman.y
	elseif ghost.name == "PINKY" then
		target.x = self.gameState.pacman.x + 4 * self.gameState.pacman.direction.x
		target.y = self.gameState.pacman.y + 4 * self.gameState.pacman.direction.y
	elseif ghost.name == "INKY" then
		local blinky = self.gameState.ghosts[1]
		local tempX = self.gameState.pacman.x + 2 * self.gameState.pacman.direction.x
		local tempY = self.gameState.pacman.y + 2 * self.gameState.pacman.direction.y
		target.x = tempX + (tempX - blinky.x)
		target.y = tempY + (tempY - blinky.y)
	elseif ghost.name == "CLYDE" then
		local distance = self:calculateDistance(ghost.x, ghost.y, self.gameState.pacman.x, self.gameState.pacman.y)
		if distance > 8 then
			target.x = self.gameState.pacman.x
			target.y = self.gameState.pacman.y
		else
			target.x = 1
			target.y = Constants.PACMAN_CONST.GRID_HEIGHT - 1
		end
	end

	return target
end

function PacmanGame:updateGhostMovement(ghost, currentTime)
	if ghost.mode == "home" and ghost.homeDelay and ghost.homeDelay > 0 then
		ghost.homeDelay = ghost.homeDelay - (currentTime - ghost.lastMoveTime)
		if ghost.homeDelay <= 0 then
			ghost.mode = "scatter"
		end
		ghost.lastMoveTime = currentTime
		return
	end

	local levelInfo = self:getCurrentLevelInfo()
	local moveSpeed = levelInfo.ghostSpeed or Constants.PACMAN_CONST.GHOST_TICK

	if ghost.mode == "frightened" then
		moveSpeed = Constants.PACMAN_CONST.GHOST_FRIGHTENED_TICK
	end

	if currentTime - ghost.lastMoveTime < moveSpeed then
		return
	end

	ghost.target = self:getGhostTarget(ghost)

	local possibleDirections = table.newarray() --[[@as table]]
	local directions = table.newarray(
		Constants.PACMAN_CONST.DIRECTIONS.UP,
		Constants.PACMAN_CONST.DIRECTIONS.LEFT,
		Constants.PACMAN_CONST.DIRECTIONS.DOWN,
		Constants.PACMAN_CONST.DIRECTIONS.RIGHT
	)

	for i = 1, #directions do
		local dir = directions[i]
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
				distance = distance,
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

	if ghost.mode == "returning" and ghost.x == ghost.homePosition.x and ghost.y == ghost.homePosition.y then
		ghost.mode = "scatter"
	end

	ghost.lastMoveTime = currentTime
end

function PacmanGame:handlePacmanCollision()
	local x, y = self.gameState.pacman.x, self.gameState.pacman.y
	local levelInfo = self:getCurrentLevelInfo()

	if self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.PELLET then
		self.gameState.board[y][x] = Constants.PACMAN_CONST.ENTITIES.EMPTY
		self.gameState.score = self.gameState.score + Constants.PACMAN_CONST.POINTS.PELLET
		self.gameState.pelletCount = self.gameState.pelletCount + 1
		TerminalSounds.playUISound("sfx_knoxnet_pacman_eat_dot_0")
	elseif self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.POWER_PELLET then
		self.gameState.board[y][x] = Constants.PACMAN_CONST.ENTITIES.EMPTY
		self.gameState.score = self.gameState.score + Constants.PACMAN_CONST.POINTS.POWER_PELLET
		self.gameState.pelletCount = self.gameState.pelletCount + 1

		local frightenedTime = levelInfo.frightenedTime or Constants.PACMAN_CONST.FRIGHTENED_TIME
		self.gameState.ghostFrightenedEndTime = getTimeInMillis() + frightenedTime
		self.gameState.ghostCombo = 0

		for i = 1, #self.gameState.ghosts do
			local ghost = self.gameState.ghosts[i]
			if ghost.mode ~= "returning" and ghost.mode ~= "home" then
				ghost.mode = "frightened"
				ghost.direction = self:getOppositeDirection(ghost.direction)
			end
		end

		TerminalSounds.playUISound("sfx_knoxnet_pacman_fright")
	elseif self.gameState.board[y][x] == Constants.PACMAN_CONST.ENTITIES.FRUIT then
		self.gameState.board[y][x] = Constants.PACMAN_CONST.ENTITIES.EMPTY
		self.gameState.score = self.gameState.score + (levelInfo.fruitValue or Constants.PACMAN_CONST.POINTS.FRUIT)
		TerminalSounds.playUISound("sfx_knoxnet_pacman_eat_fruit")
	end

	for i = 1, #self.gameState.ghosts do
		local ghost = self.gameState.ghosts[i]
		if ghost.x == x and ghost.y == y then
			if ghost.mode == "frightened" then
				ghost.mode = "returning"

				self.gameState.ghostCombo = self.gameState.ghostCombo + 1
				self.gameState.score = self.gameState.score
					+ Constants.PACMAN_CONST.POINTS.GHOST * self.gameState.ghostCombo

				TerminalSounds.playUISound("sfx_knoxnet_pacman_eat_ghost")
			elseif ghost.mode ~= "returning" and ghost.mode ~= "home" then
				self.gameState.pacman.lives = self.gameState.pacman.lives - 1

				if self.gameState.pacman.lives <= 0 then
					self.gameState.gameOver = true
					self.gameState.gameOverTime = getTimeInMillis()
					TerminalSounds.playUISound("sfx_knoxnet_pacman_death_0")
				else
					self:resetPositions()
					TerminalSounds.playUISound("sfx_knoxnet_pacman_start")
				end
			end
		end
	end

	if self.gameState.pelletCount >= self.gameState.totalPellets then
		self.gameState.levelComplete = true
		self.gameState.levelCompleteTime = getTimeInMillis()
		TerminalSounds.playUISound("sfx_knoxnet_pacman_intermission")
	end
end

function PacmanGame:resetPositions()
	self.gameState.pacman.x = 14
	self.gameState.pacman.y = 23
	self.gameState.pacman.direction = Constants.PACMAN_CONST.DIRECTIONS.LEFT
	self.gameState.pacman.nextDirection = Constants.PACMAN_CONST.DIRECTIONS.LEFT

	self.gameState.ghosts[1].x = 14
	self.gameState.ghosts[1].y = 11
	self.gameState.ghosts[1].mode = "scatter"

	self.gameState.ghosts[2].x = 14
	self.gameState.ghosts[2].y = 14
	self.gameState.ghosts[2].mode = "home"
	self.gameState.ghosts[2].homeDelay = 1000

	self.gameState.ghosts[3].x = 12
	self.gameState.ghosts[3].y = 14
	self.gameState.ghosts[3].mode = "home"
	self.gameState.ghosts[3].homeDelay = 3000

	self.gameState.ghosts[4].x = 16
	self.gameState.ghosts[4].y = 14
	self.gameState.ghosts[4].mode = "home"
	self.gameState.ghosts[4].homeDelay = 5000
end

local GamesModule = require("KnoxNet_GamesModule/core/Module")
GamesModule.registerGame(GAME_INFO, PacmanGame)

return PacmanGame
