local TerminalConstants = {}

TerminalConstants = {
	SCREEN_RATIO = 1,
	MAX_WIDTH = 1500,
	MIN_WIDTH = 800,
	ASPECT_RATIO = 848 / 910, -- original texture aspect ratio

	LAYOUT = {
		TAB = {
			HEIGHT = 25,
			PADDING = 10,
		},
		FOOTER_HEIGHT = 30,
		TITLE_HEIGHT = 30,
		PADDING = {
			NORMAL = 10,
			SECTION = 10,
			CONTENT = 10,
			ITEM = 5,
		},
		MAIN_MENU = {
			BUTTONS_PADDING = 20,
		},
		SCROLLBAR = {
			WIDTH = 10,
			MIN_HANDLE_HEIGHT = 30,
			PADDING = 5,
		},
	},

	FONT = {
		SMALL = UIFont.Small,
		MEDIUM = UIFont.Medium,
		LARGE = UIFont.Large,
		CODE = UIFont.Code,
	},

	COLORS = {
		BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
		BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },
		PANEL = {
			BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.8 },
			BORDER = { r = 0.35, g = 0.35, b = 0.35, a = 0.9 },
		},
		HEADER = {
			BACKGROUND = { r = 0.2, g = 0.2, b = 0.3, a = 0.85 },
			BORDER = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
		},
		FOOTER = {
			BACKGROUND = { r = 0.2, g = 0.2, b = 0.3, a = 0.85 },
			BORDER = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
		},
		CONTENT = {
			BACKGROUND = { r = 0.1, g = 0.1, b = 0.15, a = 0.7 },
			BORDER = { r = 0.25, g = 0.25, b = 0.3, a = 0.8 },
		},
		DIALOG = {
			BACKGROUND = { r = 0.15, g = 0.15, b = 0.2, a = 0.9 },
			BORDER = { r = 0.4, g = 0.4, b = 0.5, a = 1.0 },
		},
		INPUT = {
			BACKGROUND = { r = 0.05, g = 0.05, b = 0.1, a = 0.8 },
			BORDER = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
			FOCUS = { r = 0.3, g = 0.3, b = 0.6, a = 0.9 },
		},
		PROGRESS = {
			BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.6 },
			FILL = { r = 0.3, g = 0.5, b = 0.3, a = 0.8 },
			BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
		},
		SELECTION = { r = 0.2, g = 0.3, b = 0.5, a = 0.5 },
		DIVIDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 },
		MENU = {
			BACKGROUND = { r = 0.12, g = 0.12, b = 0.15, a = 0.85 },
			BORDER = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
			ITEM = { r = 0.15, g = 0.15, b = 0.2, a = 0.7 },
			ITEM_HOVER = { r = 0.2, g = 0.2, b = 0.3, a = 0.8 },
			ITEM_SELECTED = { r = 0.25, g = 0.25, b = 0.4, a = 0.9 },
		},
		TEXT = {
			NORMAL = { r = 1, g = 1, b = 1, a = 1 },
			DIM = { r = 0.4, g = 1, b = 0.4, a = 1 },
			HIGHLIGHT = { r = 0.8, g = 1, b = 0.8, a = 1 },
			WARNING = { r = 1, g = 0.8, b = 0.2, a = 1 },
			ERROR = { r = 1, g = 0.3, b = 0.3, a = 1 },
		},
		BUTTON = {
			SELECTED = { r = 0, g = 0, b = 0, a = 0.5 },
			BORDER = { r = 0.2, g = 0.2, b = 1.0, a = 0.5 },
			COLOR = { r = 0.2, g = 0.2, b = 1.0, a = 0.2 },
			HOVER = { r = 0.3, g = 0.3, b = 1.0, a = 0.5 },
			CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
			DISABLED = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 },
		},
		SCROLLBAR = {
			BACKGROUND = { r = 0.2, g = 0.3, b = 0.3, a = 0.3 },
			HANDLE = { r = 0.4, g = 1, b = 0.4, a = 0.4 },
			BORDER = { r = 0.3, g = 0.8, b = 0.3, a = 0.5 },
		},
		TAB = {
			SELECTED = { r = 0.2, g = 0.2, b = 0.4, a = 0.9 },
			NORMAL = { r = 0.1, g = 0.1, b = 0.2, a = 0.7 },
			BORDER = { r = 0.3, g = 0.3, b = 0.5, a = 0.7 },
		},
		POWER_BUTTON = {
			OFF = { r = 0.9, g = 0.05, b = 0.05, a = 0.8 },
			ON = { r = 0.9, g = 0.6, b = 0.1, a = 0.8 },
		},
	},

	KEYS = {
		CLOSE = Keyboard.KEY_BACK,
		CONFIRM = Keyboard.KEY_SPACE,
		UP = Keyboard.KEY_UP,
		DOWN = Keyboard.KEY_DOWN,
		LEFT = Keyboard.KEY_LEFT,
		RIGHT = Keyboard.KEY_RIGHT,
	},

	CRT = {
		FLICKER_SPEED = 0.05,
		FLICKER_INTENSITY = 0.1,
		SCAN_LINE_INTENSITY = 0.05,
	},

	-- keybinds to disable while terminal is open
	DISABLED_KEYS = {
		"Left",
		"Right",
		"Forward",
		"Backward",
		"Melee",
		"Aim",
		"Run",
		"Jump",
		"Crouch",
		"Sprint",
		"Sneak",
		"Toggle Inventory",
	},
	COLOR_SCHEMES = {
		green = {
			name = "Classic Green",
			TEXT = {
				NORMAL = { r = 0.5, g = 1.0, b = 0.5, a = 1.0 },
				DIM = { r = 0.2, g = 0.8, b = 0.2, a = 1.0 },
				HIGHLIGHT = { r = 0.8, g = 1.0, b = 0.8, a = 1.0 },
				WARNING = { r = 1.0, g = 1.0, b = 0.3, a = 1.0 },
				ERROR = { r = 1.0, g = 0.4, b = 0.4, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.1, g = 0.3, b = 0.1, a = 0.3 },
				HOVER = { r = 0.2, g = 0.5, b = 0.2, a = 0.5 },
				BORDER = { r = 0.4, g = 0.8, b = 0.4, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.2, g = 0.3, b = 0.2, a = 0.5 },
				SELECTED = { r = 0.1, g = 0.4, b = 0.1, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.2, g = 0.6, b = 0.2, a = 0.8 },
				ON = { r = 0.4, g = 1.0, b = 0.4, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.1, g = 0.3, b = 0.1, a = 0.3 },
				HANDLE = { r = 0.4, g = 1.0, b = 0.4, a = 0.4 },
				BORDER = { r = 0.3, g = 0.8, b = 0.3, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.2, g = 0.6, b = 0.2, a = 0.9 },
				NORMAL = { r = 0.1, g = 0.3, b = 0.1, a = 0.7 },
				BORDER = { r = 0.3, g = 0.8, b = 0.3, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.05, g = 0.15, b = 0.05, a = 0.8 },
				BORDER = { r = 0.2, g = 0.5, b = 0.2, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.1, g = 0.3, b = 0.1, a = 0.85 },
				BORDER = { r = 0.3, g = 0.7, b = 0.3, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.1, g = 0.3, b = 0.1, a = 0.85 },
				BORDER = { r = 0.3, g = 0.7, b = 0.3, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.05, g = 0.1, b = 0.05, a = 0.7 },
				BORDER = { r = 0.15, g = 0.4, b = 0.15, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.1, g = 0.2, b = 0.1, a = 0.9 },
				BORDER = { r = 0.3, g = 0.6, b = 0.3, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.05, g = 0.1, b = 0.05, a = 0.8 },
				BORDER = { r = 0.2, g = 0.5, b = 0.2, a = 0.9 },
				FOCUS = { r = 0.3, g = 0.7, b = 0.3, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.1, g = 0.2, b = 0.1, a = 0.6 },
				FILL = { r = 0.3, g = 0.8, b = 0.3, a = 0.8 },
				BORDER = { r = 0.2, g = 0.5, b = 0.2, a = 0.8 },
			},
			SELECTION = { r = 0.2, g = 0.5, b = 0.2, a = 0.5 },
			DIVIDER = { r = 0.3, g = 0.6, b = 0.3, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.08, g = 0.2, b = 0.08, a = 0.85 },
				BORDER = { r = 0.25, g = 0.6, b = 0.25, a = 0.9 },
				ITEM = { r = 0.1, g = 0.25, b = 0.1, a = 0.7 },
				ITEM_HOVER = { r = 0.15, g = 0.4, b = 0.15, a = 0.8 },
				ITEM_SELECTED = { r = 0.2, g = 0.5, b = 0.2, a = 0.9 },
			},
			BORDER = { r = 0.3, g = 0.7, b = 0.3, a = 1.0 },
			BACKGROUND = { r = 0.06, g = 0.12, b = 0.06, a = 0.75 },
		},
		amber = {
			name = "Amber/Orange",
			TEXT = {
				NORMAL = { r = 1.0, g = 0.75, b = 0.1, a = 1.0 },
				DIM = { r = 0.9, g = 0.5, b = 0.0, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 0.9, b = 0.5, a = 1.0 },
				WARNING = { r = 1.0, g = 0.4, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.6, g = 0.3, b = 0.0, a = 0.3 },
				HOVER = { r = 0.8, g = 0.5, b = 0.0, a = 0.5 },
				BORDER = { r = 1.0, g = 0.6, b = 0.0, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.4, g = 0.2, b = 0.1, a = 0.5 },
				SELECTED = { r = 0.7, g = 0.35, b = 0.0, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.7, g = 0.4, b = 0.0, a = 0.8 },
				ON = { r = 1.0, g = 0.7, b = 0.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.6, g = 0.3, b = 0.0, a = 0.3 },
				HANDLE = { r = 1.0, g = 0.7, b = 0.0, a = 0.4 },
				BORDER = { r = 1.0, g = 0.6, b = 0.0, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.8, g = 0.5, b = 0.0, a = 0.9 },
				NORMAL = { r = 0.6, g = 0.3, b = 0.0, a = 0.7 },
				BORDER = { r = 1.0, g = 0.6, b = 0.0, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.2, g = 0.1, b = 0.0, a = 0.8 },
				BORDER = { r = 0.7, g = 0.4, b = 0.0, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.3, g = 0.15, b = 0.0, a = 0.85 },
				BORDER = { r = 0.8, g = 0.5, b = 0.0, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.3, g = 0.15, b = 0.0, a = 0.85 },
				BORDER = { r = 0.8, g = 0.5, b = 0.0, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.15, g = 0.08, b = 0.0, a = 0.7 },
				BORDER = { r = 0.6, g = 0.3, b = 0.0, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.25, g = 0.12, b = 0.0, a = 0.9 },
				BORDER = { r = 0.8, g = 0.4, b = 0.0, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.1, g = 0.05, b = 0.0, a = 0.8 },
				BORDER = { r = 0.7, g = 0.4, b = 0.0, a = 0.9 },
				FOCUS = { r = 0.9, g = 0.6, b = 0.0, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.2, g = 0.1, b = 0.0, a = 0.6 },
				FILL = { r = 0.9, g = 0.5, b = 0.0, a = 0.8 },
				BORDER = { r = 0.7, g = 0.4, b = 0.0, a = 0.8 },
			},
			SELECTION = { r = 0.6, g = 0.3, b = 0.0, a = 0.5 },
			DIVIDER = { r = 0.7, g = 0.4, b = 0.0, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.18, g = 0.09, b = 0.0, a = 0.85 },
				BORDER = { r = 0.7, g = 0.35, b = 0.0, a = 0.9 },
				ITEM = { r = 0.25, g = 0.12, b = 0.0, a = 0.7 },
				ITEM_HOVER = { r = 0.4, g = 0.2, b = 0.0, a = 0.8 },
				ITEM_SELECTED = { r = 0.5, g = 0.25, b = 0.0, a = 0.9 },
			},
			BORDER = { r = 0.8, g = 0.5, b = 0.0, a = 1.0 },
			BACKGROUND = { r = 0.18, g = 0.09, b = 0.0, a = 0.75 },
		},
		blue = {
			name = "Cool Blue",
			TEXT = {
				NORMAL = { r = 0.3, g = 0.7, b = 1.0, a = 1.0 },
				DIM = { r = 0.2, g = 0.4, b = 0.8, a = 1.0 },
				HIGHLIGHT = { r = 0.6, g = 0.9, b = 1.0, a = 1.0 },
				WARNING = { r = 1.0, g = 0.9, b = 0.2, a = 1.0 },
				ERROR = { r = 1.0, g = 0.4, b = 0.4, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.1, g = 0.3, b = 0.6, a = 0.3 },
				HOVER = { r = 0.2, g = 0.5, b = 0.8, a = 0.5 },
				BORDER = { r = 0.3, g = 0.6, b = 1.0, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.2, g = 0.2, b = 0.3, a = 0.5 },
				SELECTED = { r = 0.15, g = 0.4, b = 0.7, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.1, g = 0.5, b = 0.9, a = 0.8 },
				ON = { r = 0.3, g = 0.7, b = 1.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.1, g = 0.3, b = 0.6, a = 0.3 },
				HANDLE = { r = 0.3, g = 0.7, b = 1.0, a = 0.4 },
				BORDER = { r = 0.4, g = 0.8, b = 1.0, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.2, g = 0.5, b = 0.8, a = 0.9 },
				NORMAL = { r = 0.1, g = 0.3, b = 0.6, a = 0.7 },
				BORDER = { r = 0.3, g = 0.6, b = 1.0, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.05, g = 0.1, b = 0.2, a = 0.8 },
				BORDER = { r = 0.15, g = 0.4, b = 0.8, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.1, g = 0.2, b = 0.4, a = 0.85 },
				BORDER = { r = 0.2, g = 0.5, b = 0.9, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.1, g = 0.2, b = 0.4, a = 0.85 },
				BORDER = { r = 0.2, g = 0.5, b = 0.9, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.03, g = 0.08, b = 0.15, a = 0.7 },
				BORDER = { r = 0.1, g = 0.3, b = 0.7, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.1, g = 0.15, b = 0.3, a = 0.9 },
				BORDER = { r = 0.2, g = 0.4, b = 0.8, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.02, g = 0.06, b = 0.12, a = 0.8 },
				BORDER = { r = 0.15, g = 0.4, b = 0.8, a = 0.9 },
				FOCUS = { r = 0.25, g = 0.6, b = 1.0, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.05, g = 0.1, b = 0.2, a = 0.6 },
				FILL = { r = 0.2, g = 0.5, b = 0.9, a = 0.8 },
				BORDER = { r = 0.15, g = 0.4, b = 0.8, a = 0.8 },
			},
			SELECTION = { r = 0.1, g = 0.3, b = 0.6, a = 0.5 },
			DIVIDER = { r = 0.2, g = 0.4, b = 0.8, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.06, g = 0.12, b = 0.25, a = 0.85 },
				BORDER = { r = 0.15, g = 0.35, b = 0.7, a = 0.9 },
				ITEM = { r = 0.08, g = 0.16, b = 0.3, a = 0.7 },
				ITEM_HOVER = { r = 0.12, g = 0.25, b = 0.5, a = 0.8 },
				ITEM_SELECTED = { r = 0.15, g = 0.35, b = 0.7, a = 0.9 },
			},
			BORDER = { r = 0.2, g = 0.5, b = 0.9, a = 1.0 },
			BACKGROUND = { r = 0.05, g = 0.1, b = 0.2, a = 0.75 },
		},
		white = {
			name = "White Legacy",
			TEXT = {
				NORMAL = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
				DIM = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 1.0, b = 0.9, a = 1.0 },
				WARNING = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 0.3 },
				HOVER = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 },
				BORDER = { r = 0.9, g = 0.9, b = 0.9, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 },
				SELECTED = { r = 0.6, g = 0.6, b = 0.6, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.8, g = 0.8, b = 0.8, a = 0.8 },
				ON = { r = 1.0, g = 1.0, b = 1.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.4, g = 0.4, b = 0.4, a = 0.3 },
				HANDLE = { r = 0.8, g = 0.8, b = 0.8, a = 0.4 },
				BORDER = { r = 0.9, g = 0.9, b = 0.9, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.6, g = 0.6, b = 0.6, a = 0.9 },
				NORMAL = { r = 0.4, g = 0.4, b = 0.4, a = 0.7 },
				BORDER = { r = 0.8, g = 0.8, b = 0.8, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.8 },
				BORDER = { r = 0.6, g = 0.6, b = 0.6, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.85 },
				BORDER = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.85 },
				BORDER = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
				BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.9 },
				BORDER = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.05, g = 0.05, b = 0.05, a = 0.8 },
				BORDER = { r = 0.6, g = 0.6, b = 0.6, a = 0.9 },
				FOCUS = { r = 0.8, g = 0.8, b = 0.8, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.6 },
				FILL = { r = 0.7, g = 0.7, b = 0.7, a = 0.8 },
				BORDER = { r = 0.6, g = 0.6, b = 0.6, a = 0.8 },
			},
			SELECTION = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 },
			DIVIDER = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.85 },
				BORDER = { r = 0.6, g = 0.6, b = 0.6, a = 0.9 },
				ITEM = { r = 0.2, g = 0.2, b = 0.2, a = 0.7 },
				ITEM_HOVER = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
				ITEM_SELECTED = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
			},
			BORDER = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
			BACKGROUND = { r = 0.12, g = 0.12, b = 0.12, a = 0.75 },
		},
		cyan = {
			name = "Cyan-Matrix",
			TEXT = {
				NORMAL = { r = 0.0, g = 1.0, b = 1.0, a = 1.0 },
				DIM = { r = 0.0, g = 0.7, b = 0.7, a = 1.0 },
				HIGHLIGHT = { r = 0.5, g = 1.0, b = 1.0, a = 1.0 },
				WARNING = { r = 1.0, g = 0.9, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.0, g = 0.5, b = 0.5, a = 0.3 },
				HOVER = { r = 0.0, g = 0.7, b = 0.7, a = 0.5 },
				BORDER = { r = 0.0, g = 0.9, b = 0.9, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.2, g = 0.3, b = 0.3, a = 0.5 },
				SELECTED = { r = 0.0, g = 0.6, b = 0.6, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.0, g = 0.7, b = 0.7, a = 0.8 },
				ON = { r = 0.0, g = 1.0, b = 1.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.0, g = 0.5, b = 0.5, a = 0.3 },
				HANDLE = { r = 0.0, g = 1.0, b = 1.0, a = 0.4 },
				BORDER = { r = 0.0, g = 0.9, b = 0.9, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.0, g = 0.7, b = 0.7, a = 0.9 },
				NORMAL = { r = 0.0, g = 0.5, b = 0.5, a = 0.7 },
				BORDER = { r = 0.0, g = 0.9, b = 0.9, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.05, g = 0.15, b = 0.15, a = 0.8 },
				BORDER = { r = 0.0, g = 0.6, b = 0.6, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.0, g = 0.25, b = 0.25, a = 0.85 },
				BORDER = { r = 0.0, g = 0.7, b = 0.7, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.0, g = 0.25, b = 0.25, a = 0.85 },
				BORDER = { r = 0.0, g = 0.7, b = 0.7, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.03, g = 0.1, b = 0.1, a = 0.7 },
				BORDER = { r = 0.0, g = 0.5, b = 0.5, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.05, g = 0.2, b = 0.2, a = 0.9 },
				BORDER = { r = 0.0, g = 0.7, b = 0.7, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.02, g = 0.08, b = 0.08, a = 0.8 },
				BORDER = { r = 0.0, g = 0.6, b = 0.6, a = 0.9 },
				FOCUS = { r = 0.0, g = 0.9, b = 0.9, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.05, g = 0.15, b = 0.15, a = 0.6 },
				FILL = { r = 0.0, g = 0.8, b = 0.8, a = 0.8 },
				BORDER = { r = 0.0, g = 0.6, b = 0.6, a = 0.8 },
			},
			SELECTION = { r = 0.0, g = 0.5, b = 0.5, a = 0.5 },
			DIVIDER = { r = 0.0, g = 0.6, b = 0.6, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.03, g = 0.15, b = 0.15, a = 0.85 },
				BORDER = { r = 0.0, g = 0.6, b = 0.6, a = 0.9 },
				ITEM = { r = 0.05, g = 0.2, b = 0.2, a = 0.7 },
				ITEM_HOVER = { r = 0.0, g = 0.3, b = 0.3, a = 0.8 },
				ITEM_SELECTED = { r = 0.0, g = 0.4, b = 0.4, a = 0.9 },
			},
			BORDER = { r = 0.0, g = 0.8, b = 0.8, a = 1.0 },
			BACKGROUND = { r = 0.04, g = 0.12, b = 0.12, a = 0.75 },
		},
		purple = {
			name = "Retro Purple",
			TEXT = {
				NORMAL = { r = 0.8, g = 0.3, b = 1.0, a = 1.0 },
				DIM = { r = 0.6, g = 0.2, b = 0.8, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 0.6, b = 1.0, a = 1.0 },
				WARNING = { r = 1.0, g = 0.7, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.4, g = 0.1, b = 0.6, a = 0.3 },
				HOVER = { r = 0.6, g = 0.2, b = 0.8, a = 0.5 },
				BORDER = { r = 0.8, g = 0.3, b = 1.0, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.3, g = 0.1, b = 0.4, a = 0.5 },
				SELECTED = { r = 0.5, g = 0.15, b = 0.7, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.6, g = 0.1, b = 0.8, a = 0.8 },
				ON = { r = 0.8, g = 0.3, b = 1.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.4, g = 0.1, b = 0.6, a = 0.3 },
				HANDLE = { r = 0.8, g = 0.3, b = 1.0, a = 0.4 },
				BORDER = { r = 0.9, g = 0.5, b = 1.0, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.6, g = 0.2, b = 0.8, a = 0.9 },
				NORMAL = { r = 0.4, g = 0.1, b = 0.6, a = 0.7 },
				BORDER = { r = 0.8, g = 0.3, b = 1.0, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.2, g = 0.05, b = 0.25, a = 0.8 },
				BORDER = { r = 0.5, g = 0.15, b = 0.7, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.3, g = 0.1, b = 0.4, a = 0.85 },
				BORDER = { r = 0.6, g = 0.2, b = 0.8, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.3, g = 0.1, b = 0.4, a = 0.85 },
				BORDER = { r = 0.6, g = 0.2, b = 0.8, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.15, g = 0.03, b = 0.2, a = 0.7 },
				BORDER = { r = 0.4, g = 0.1, b = 0.6, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.25, g = 0.08, b = 0.35, a = 0.9 },
				BORDER = { r = 0.6, g = 0.2, b = 0.8, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.1, g = 0.02, b = 0.15, a = 0.8 },
				BORDER = { r = 0.5, g = 0.15, b = 0.7, a = 0.9 },
				FOCUS = { r = 0.7, g = 0.25, b = 0.9, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.2, g = 0.05, b = 0.3, a = 0.6 },
				FILL = { r = 0.7, g = 0.25, b = 0.9, a = 0.8 },
				BORDER = { r = 0.5, g = 0.15, b = 0.7, a = 0.8 },
			},
			SELECTION = { r = 0.4, g = 0.1, b = 0.6, a = 0.5 },
			DIVIDER = { r = 0.5, g = 0.15, b = 0.7, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.18, g = 0.04, b = 0.25, a = 0.85 },
				BORDER = { r = 0.5, g = 0.15, b = 0.7, a = 0.9 },
				ITEM = { r = 0.25, g = 0.06, b = 0.35, a = 0.7 },
				ITEM_HOVER = { r = 0.35, g = 0.1, b = 0.5, a = 0.8 },
				ITEM_SELECTED = { r = 0.45, g = 0.15, b = 0.65, a = 0.9 },
			},
			BORDER = { r = 0.6, g = 0.2, b = 0.9, a = 1.0 },
			BACKGROUND = { r = 0.15, g = 0.04, b = 0.2, a = 0.75 },
		},
		yellow = {
			name = "Radiation Alert",
			TEXT = {
				NORMAL = { r = 1.0, g = 0.9, b = 0.0, a = 1.0 },
				DIM = { r = 0.8, g = 0.7, b = 0.0, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 1.0, b = 0.5, a = 1.0 },
				WARNING = { r = 1.0, g = 0.5, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.2, b = 0.0, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.7, g = 0.6, b = 0.0, a = 0.3 },
				HOVER = { r = 0.9, g = 0.8, b = 0.0, a = 0.5 },
				BORDER = { r = 1.0, g = 0.9, b = 0.0, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.4, g = 0.35, b = 0.1, a = 0.5 },
				SELECTED = { r = 0.8, g = 0.7, b = 0.0, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.8, g = 0.7, b = 0.0, a = 0.8 },
				ON = { r = 1.0, g = 0.9, b = 0.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.7, g = 0.6, b = 0.0, a = 0.3 },
				HANDLE = { r = 1.0, g = 0.9, b = 0.0, a = 0.4 },
				BORDER = { r = 1.0, g = 0.8, b = 0.0, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.9, g = 0.8, b = 0.0, a = 0.9 },
				NORMAL = { r = 0.7, g = 0.6, b = 0.0, a = 0.7 },
				BORDER = { r = 1.0, g = 0.9, b = 0.0, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.25, g = 0.2, b = 0.05, a = 0.8 },
				BORDER = { r = 0.7, g = 0.6, b = 0.0, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.35, g = 0.3, b = 0.05, a = 0.85 },
				BORDER = { r = 0.8, g = 0.7, b = 0.0, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.35, g = 0.3, b = 0.05, a = 0.85 },
				BORDER = { r = 0.8, g = 0.7, b = 0.0, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.15, g = 0.12, b = 0.03, a = 0.7 },
				BORDER = { r = 0.6, g = 0.5, b = 0.0, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.3, g = 0.25, b = 0.05, a = 0.9 },
				BORDER = { r = 0.8, g = 0.7, b = 0.0, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.1, g = 0.08, b = 0.02, a = 0.8 },
				BORDER = { r = 0.7, g = 0.6, b = 0.0, a = 0.9 },
				FOCUS = { r = 0.9, g = 0.8, b = 0.0, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.2, g = 0.15, b = 0.03, a = 0.6 },
				FILL = { r = 0.9, g = 0.8, b = 0.0, a = 0.8 },
				BORDER = { r = 0.7, g = 0.6, b = 0.0, a = 0.8 },
			},
			SELECTION = { r = 0.6, g = 0.5, b = 0.0, a = 0.5 },
			DIVIDER = { r = 0.7, g = 0.6, b = 0.0, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.22, g = 0.18, b = 0.04, a = 0.85 },
				BORDER = { r = 0.7, g = 0.6, b = 0.0, a = 0.9 },
				ITEM = { r = 0.3, g = 0.25, b = 0.05, a = 0.7 },
				ITEM_HOVER = { r = 0.4, g = 0.35, b = 0.07, a = 0.8 },
				ITEM_SELECTED = { r = 0.5, g = 0.45, b = 0.1, a = 0.9 },
			},
			BORDER = { r = 0.9, g = 0.8, b = 0.0, a = 1.0 },
			BACKGROUND = { r = 0.2, g = 0.17, b = 0.04, a = 0.75 },
		},
		red = {
			name = "Emergency Alert",
			TEXT = {
				NORMAL = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
				DIM = { r = 0.8, g = 0.2, b = 0.2, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 0.6, b = 0.6, a = 1.0 },
				WARNING = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.6, g = 0.1, b = 0.1, a = 0.3 },
				HOVER = { r = 0.8, g = 0.2, b = 0.2, a = 0.5 },
				BORDER = { r = 1.0, g = 0.3, b = 0.3, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.4, g = 0.1, b = 0.1, a = 0.5 },
				SELECTED = { r = 0.7, g = 0.15, b = 0.15, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.7, g = 0.0, b = 0.0, a = 0.8 },
				ON = { r = 1.0, g = 0.0, b = 0.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.6, g = 0.1, b = 0.1, a = 0.3 },
				HANDLE = { r = 1.0, g = 0.3, b = 0.3, a = 0.4 },
				BORDER = { r = 1.0, g = 0.2, b = 0.2, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.8, g = 0.2, b = 0.2, a = 0.9 },
				NORMAL = { r = 0.6, g = 0.1, b = 0.1, a = 0.7 },
				BORDER = { r = 1.0, g = 0.3, b = 0.3, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.25, g = 0.05, b = 0.05, a = 0.8 },
				BORDER = { r = 0.7, g = 0.15, b = 0.15, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.35, g = 0.07, b = 0.07, a = 0.85 },
				BORDER = { r = 0.8, g = 0.2, b = 0.2, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.35, g = 0.07, b = 0.07, a = 0.85 },
				BORDER = { r = 0.8, g = 0.2, b = 0.2, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.15, g = 0.03, b = 0.03, a = 0.7 },
				BORDER = { r = 0.6, g = 0.1, b = 0.1, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.3, g = 0.06, b = 0.06, a = 0.9 },
				BORDER = { r = 0.8, g = 0.2, b = 0.2, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.1, g = 0.02, b = 0.02, a = 0.8 },
				BORDER = { r = 0.7, g = 0.15, b = 0.15, a = 0.9 },
				FOCUS = { r = 0.9, g = 0.25, b = 0.25, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.2, g = 0.04, b = 0.04, a = 0.6 },
				FILL = { r = 0.9, g = 0.2, b = 0.2, a = 0.8 },
				BORDER = { r = 0.7, g = 0.15, b = 0.15, a = 0.8 },
			},
			SELECTION = { r = 0.6, g = 0.1, b = 0.1, a = 0.5 },
			DIVIDER = { r = 0.7, g = 0.15, b = 0.15, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.22, g = 0.04, b = 0.04, a = 0.85 },
				BORDER = { r = 0.7, g = 0.15, b = 0.15, a = 0.9 },
				ITEM = { r = 0.3, g = 0.06, b = 0.06, a = 0.7 },
				ITEM_HOVER = { r = 0.4, g = 0.08, b = 0.08, a = 0.8 },
				ITEM_SELECTED = { r = 0.5, g = 0.1, b = 0.1, a = 0.9 },
			},
			BORDER = { r = 0.9, g = 0.2, b = 0.2, a = 1.0 },
			BACKGROUND = { r = 0.2, g = 0.04, b = 0.04, a = 0.75 },
		},
		rainbow = {
			name = "Rainbow Mode",
			BASE_HUE = 0,
			HUE_SPEED = 0.1,
			TEXT = {
				NORMAL = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
				DIM = { r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
				HIGHLIGHT = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
				WARNING = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
				ERROR = { r = 1.0, g = 0.3, b = 0.3, a = 1.0 },
			},
			BUTTON = {
				COLOR = { r = 0.5, g = 0.3, b = 0.7, a = 0.3 },
				HOVER = { r = 0.7, g = 0.5, b = 0.9, a = 0.5 },
				BORDER = { r = 0.9, g = 0.7, b = 1.0, a = 0.5 },
				CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
				DISABLED = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 },
				SELECTED = { r = 0.6, g = 0.4, b = 0.8, a = 0.5 },
			},
			POWER_BUTTON = {
				OFF = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 },
				ON = { r = 1.0, g = 1.0, b = 1.0, a = 0.9 },
			},
			SCROLLBAR = {
				BACKGROUND = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 },
				HANDLE = { r = 0.7, g = 0.7, b = 0.7, a = 0.4 },
				BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 },
			},
			TAB = {
				SELECTED = { r = 0.5, g = 0.5, b = 0.5, a = 0.9 },
				NORMAL = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 },
				BORDER = { r = 0.6, g = 0.6, b = 0.6, a = 0.7 },
			},
			PANEL = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.8 },
				BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
			},
			HEADER = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.85 },
				BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 0.9 },
			},
			FOOTER = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.85 },
				BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 0.9 },
			},
			CONTENT = {
				BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
				BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
			},
			DIALOG = {
				BACKGROUND = { r = 0.2, g = 0.2, b = 0.2, a = 0.9 },
				BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
			},
			INPUT = {
				BACKGROUND = { r = 0.05, g = 0.05, b = 0.05, a = 0.8 },
				BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
				FOCUS = { r = 0.6, g = 0.6, b = 0.6, a = 0.9 },
			},
			PROGRESS = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.6 },
				FILL = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 },
				BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 0.8 },
			},
			SELECTION = { r = 0.4, g = 0.4, b = 0.4, a = 0.5 },
			DIVIDER = { r = 0.4, g = 0.4, b = 0.4, a = 0.7 },
			MENU = {
				BACKGROUND = { r = 0.15, g = 0.15, b = 0.15, a = 0.85 },
				BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
				ITEM = { r = 0.2, g = 0.2, b = 0.2, a = 0.7 },
				ITEM_HOVER = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
				ITEM_SELECTED = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
			},
			BORDER = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
			BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },
		},
	},
}

return TerminalConstants
