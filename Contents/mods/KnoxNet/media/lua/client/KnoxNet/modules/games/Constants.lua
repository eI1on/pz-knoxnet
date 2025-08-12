local UI_CONST = {
	TILES_PER_ROW = 3,
	TILE_PADDING = 10,
	TILE_SPACING = 15,
	TITLE_HEIGHT = 25,
	DESCRIPTION_HEIGHT = 80,
	PREVIEW_HEIGHT = 100,

	VISIBLE_ROWS = 1,
	SCROLL_MARGIN = 10,

	SCROLLBAR_WIDTH = 10,
	SCROLLBAR_MIN_HANDLE = 30,

	FONT = {
		SMALL = UIFont.Small,
		MEDIUM = UIFont.Medium,
		LARGE = UIFont.Large,
		CODE = UIFont.Code,
	},

	COLORS = {
		BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
		BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },

		TEXT = { r = 1, g = 1, b = 1, a = 1 },
		TEXT_DIM = { r = 0.4, g = 1, b = 0.4, a = 1 },

		SCROLLBAR_BG = { r = 0.2, g = 0.3, b = 0.3, a = 0.3 },
		SCROLLBAR = { r = 0.4, g = 1, b = 0.4, a = 0.4 },

		BUTTON_SELECTED = { r = 0, g = 0, b = 0, a = 0 },
		BUTTON_BORDER = { r = 0.2, g = 0.2, b = 1.0, a = 0.5 },
		BUTTON_COLOR = { r = 0.2, g = 0.2, b = 1.0, a = 0.2 },
		BUTTON_HOVER = { r = 0.3, g = 0.3, b = 1.0, a = 0.5 },
	},
}

local SNAKE_CONST = {
	GRID_WIDTH = 30,
	GRID_HEIGHT = 20,
	CELL_SIZE = 1,

	INITIAL_LENGTH = 3,
	MOVE_DELAY = 150,
	FOOD_POINTS = 10,

	DIRECTIONS = {
		UP = { x = 0, y = -1 },
		DOWN = { x = 0, y = 1 },
		LEFT = { x = -1, y = 0 },
		RIGHT = { x = 1, y = 0 },
	},
	COLORS = {
		SNAKE_HEAD = { r = 0, g = 0.8, b = 0, a = 1 },
		SNAKE_BODY = { r = 0, g = 0.6, b = 0, a = 1 },
		FOOD = { r = 0.8, g = 0, b = 0, a = 1 },
		BACKGROUND = { r = 0, g = 0.1, b = 0, a = 0.5 },
		BORDER = { r = 0.2, g = 0.4, b = 0.2, a = 1 },
		GRID = { r = 0.1, g = 0.2, b = 0.1, a = 0.7 },
	},
	GAME_TICK = 150,
	GAME_OVER_DELAY = 3000,
}

local TETRIS_CONST = {
	BOARD_WIDTH = 10,
	BOARD_HEIGHT = 20,
	COLORS = {
		BACKGROUND = { r = 0, g = 0, b = 0.1, a = 1 },
		GRID = { r = 0.2, g = 0.2, b = 0.3, a = 0.5 },
		TEXT = { r = 1, g = 1, b = 1, a = 1 },
	},
	PIECE_TYPES = {
		I = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 1, 1, 1, 1 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 0, g = 1, b = 1, a = 1 },
			char = "I",
		},
		J = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 1, 0, 0, 0 },
				{ 0, 1, 1, 1, 1 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 0, g = 0, b = 1, a = 1 },
			char = "J",
		},
		L = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 1 },
				{ 0, 1, 1, 1, 1 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 1, g = 0.5, b = 0, a = 1 },
			char = "L",
		},
		O = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 1, 1, 0 },
				{ 0, 0, 1, 1, 0 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 1, g = 1, b = 0, a = 1 },
			char = "O",
		},
		S = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 1, 1, 0 },
				{ 0, 1, 1, 0, 0 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 0, g = 1, b = 0, a = 1 },
			char = "S",
		},
		T = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 1, 0, 0 },
				{ 0, 1, 1, 1, 0 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 0.8, g = 0, b = 0.8, a = 1 },
			char = "T",
		},
		Z = {
			shape = {
				{ 0, 0, 0, 0, 0 },
				{ 0, 1, 1, 0, 0 },
				{ 0, 0, 1, 1, 0 },
				{ 0, 0, 0, 0, 0 },
				{ 0, 0, 0, 0, 0 },
			},
			color = { r = 1, g = 0, b = 0, a = 1 },
			char = "Z",
		},
	},
	DROP_INTERVAL = 500,
	GAME_OVER_DELAY = 3000,
}

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
		GHOST_HOME = 7,
	},

	DIRECTIONS = {
		UP = { x = 0, y = -1 },
		DOWN = { x = 0, y = 1 },
		LEFT = { x = -1, y = 0 },
		RIGHT = { x = 1, y = 0 },
		NONE = { x = 0, y = 0 },
	},

	COLORS = {
		PACMAN = { r = 1, g = 1, b = 0, a = 1 }, -- yellow
		WALL = { r = 0, g = 0.3, b = 0.8, a = 1 }, -- blue
		PELLET = { r = 1, g = 1, b = 1, a = 1 }, -- white
		POWER_PELLET = { r = 1, g = 1, b = 1, a = 1 }, -- white
		FRUIT = { r = 1, g = 0, b = 0.5, a = 1 }, -- pink
		BACKGROUND = { r = 0, g = 0, b = 0, a = 1 }, -- black
		TEXT = { r = 1, g = 1, b = 1, a = 1 }, -- white
		SCORE = { r = 1, g = 0.8, b = 0, a = 1 }, -- gold

		-- ghost colors (for tinting)
		GHOST_FRIGHTENED = { r = 0, g = 0, b = 1, a = 1 }, -- blue
		GHOST_RETURNING = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 }, -- translucent
	},

	GAME_TICK = 150, -- base ms between game updates
	GHOST_TICK = 200, -- ghost movement speed (ms)
	GHOST_FRIGHTENED_TICK = 300, -- slower frightened speed
	FRIGHTENED_TIME = 8000, -- time ghosts remain frightened (ms)
	FRUIT_TIME = 10000, -- time fruit remains visible (ms)
	GAME_OVER_DELAY = 3000, -- delay after game over (ms)
	LEVEL_COMPLETE_DELAY = 3000, -- delay after completing a level (ms)

	ANIMATION_FRAMES = 2, -- number of animation frames
	ANIMATION_SPEED = 200, -- ms between animation frames

	POINTS = {
		PELLET = 10,
		POWER_PELLET = 50,
		FRUIT = 100,
		GHOST = 200, -- multiplied by ghost combo (1-4)
	},

	TEXTURES = {
		PACMAN_RIGHT = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_pacman_right.png",
		PACMAN_LEFT = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_pacman_left.png",
		PACMAN_UP = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_pacman_top.png",
		PACMAN_DOWN = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_pacman_down.png",
		BLINKY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_blinky.png",
		PINKY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_pinky.png",
		INKY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_inky.png",
		CLYDE = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_clyde.png",
		GHOST = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_ghost.png",

		CHERRY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_cherry.png",
		STRAWBERRY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_strawberry.png",
		ORANGE = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_orange.png",
		APPLE = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_apple.png",
		GALAXIAN_FLAGSHIP = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_galaxian_flagship.png",
		BELL = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_bell.png",
		KEY = "media/ui/KnoxNet/games/pacman/ui_knoxnet_pacman_key.png",
	},
}
PACMAN_CONST.FRUITS_BY_LEVEL = {
	PACMAN_CONST.TEXTURES.CHERRY,
	PACMAN_CONST.TEXTURES.STRAWBERRY,
	PACMAN_CONST.TEXTURES.ORANGE,
	PACMAN_CONST.TEXTURES.APPLE,
	PACMAN_CONST.TEXTURES.GALAXIAN_FLAGSHIP,
	PACMAN_CONST.TEXTURES.BELL,
	PACMAN_CONST.TEXTURES.KEY,
}

return {
	UI_CONST = UI_CONST,
	SNAKE_CONST = SNAKE_CONST,
	TETRIS_CONST = TETRIS_CONST,
	PACMAN_CONST = PACMAN_CONST,
}
