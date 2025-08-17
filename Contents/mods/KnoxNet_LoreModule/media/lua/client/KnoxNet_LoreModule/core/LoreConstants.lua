---@class LoreConstants
local LoreConstants = {}

LoreConstants.ENTRY_TYPES = {
	TEXT = "text", -- Text only
	AUDIO = "audio", -- Audio only
	BOTH = "both", -- Both text and audio
}

LoreConstants.ANIMATION = {
	CASSETTE_INSERT_DURATION = 1500, -- ms
	CASSETTE_EJECT_DURATION = 1200, -- ms
	AUDIO_VISUALIZER_UPDATE_RATE = 100, -- ms
}

LoreConstants.UI = {
	HEADER_HEIGHT = 40,
	FOOTER_HEIGHT = 40,
	ENTRY_HEIGHT = 80,
	ENTRY_PADDING = 10,
	CATEGORY_HEIGHT = 40,
	CATEGORY_PADDING = 10,

	AUDIO_CONTROLS = {
		HEIGHT = 40,
		BUTTON_SIZE = 30,
		PROGRESS_HEIGHT = 15,
	},

	CASSETTE = {
		WIDTH = 150,
		HEIGHT = 80,
	},

	VISUALIZER = {
		BARS = 16,
		MAX_HEIGHT = 40,
	},

	FONTS = {
		TITLE = UIFont.Medium,
		SUBTITLE = UIFont.Small,
		BODY = UIFont.Code,
		LABEL = UIFont.Small,
	},
}

LoreConstants.SOUNDS = {
	AMBIENT = "amb_knoxnet_terminal_lore",
	CASSETTE_INSERT = "sfx_knoxnet_lore_cassette_insert",
	CASSETTE_EJECT = "sfx_knoxnet_lore_cassette_eject",
	ACTIVATE = "sfx_knoxnet_lore_activate",
	BUTTON = "sfx_knoxnet_key_4",
}

return LoreConstants
