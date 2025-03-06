local UI_CONST = {
    TILES_PER_ROW = 3,
    TILE_PADDING = 10,
    TILE_SPACING = 15,
    TITLE_HEIGHT = 25,
    DESCRIPTION_HEIGHT = 45,
    PREVIEW_HEIGHT = 80,

    VISIBLE_ROWS = 1,
    SCROLL_MARGIN = 10,

    SCROLLBAR_WIDTH = 10,
    SCROLLBAR_MIN_HANDLE = 30,

    FONT = {
        SMALL = UIFont.Small,
        MEDIUM = UIFont.Medium,
        LARGE = UIFont.Large,
        CODE = UIFont.Code
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
    GRID_HEIGHT = 15,
    CELL_SIZE = 1,
    DIRECTIONS = {
        UP = { x = 0, y = -1 },
        DOWN = { x = 0, y = 1 },
        LEFT = { x = -1, y = 0 },
        RIGHT = { x = 1, y = 0 }
    },
    COLORS = {
        BACKGROUND = { r = 0, g = 0.1, b = 0, a = 1 },
        GRID = { r = 0.1, g = 0.3, b = 0.1, a = 0.5 },
        SNAKE = { r = 0, g = 1, b = 0, a = 1 },
        FOOD = { r = 1, g = 0, b = 0, a = 1 },
        TEXT = { r = 0.5, g = 1, b = 0.5, a = 1 }
    },
    GAME_TICK = 150,
    GAME_OVER_DELAY = 3000
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
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 0, g = 1, b = 1, a = 1 },
            char = "I"
        },
        J = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 1, 0, 0, 0 },
                { 0, 1, 1, 1, 1 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 0, g = 0, b = 1, a = 1 },
            char = "J"
        },
        L = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 1 },
                { 0, 1, 1, 1, 1 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 1, g = 0.5, b = 0, a = 1 },
            char = "L"
        },
        O = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 0, 1, 1, 0 },
                { 0, 0, 1, 1, 0 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 1, g = 1, b = 0, a = 1 },
            char = "O"
        },
        S = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 0, 1, 1, 0 },
                { 0, 1, 1, 0, 0 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 0, g = 1, b = 0, a = 1 },
            char = "S"
        },
        T = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 0, 1, 0, 0 },
                { 0, 1, 1, 1, 0 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 0.8, g = 0, b = 0.8, a = 1 },
            char = "T"
        },
        Z = {
            shape = {
                { 0, 0, 0, 0, 0 },
                { 0, 1, 1, 0, 0 },
                { 0, 0, 1, 1, 0 },
                { 0, 0, 0, 0, 0 },
                { 0, 0, 0, 0, 0 }
            },
            color = { r = 1, g = 0, b = 0, a = 1 },
            char = "Z"
        }
    },
    DROP_INTERVAL = 500,
    GAME_OVER_DELAY = 3000
}

return {
    SNAKE_CONST = SNAKE_CONST,
    TETRIS_CONST = TETRIS_CONST,
    UI_CONST = UI_CONST
}