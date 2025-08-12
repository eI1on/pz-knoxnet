---@class LoreConstants
local LoreConstants = {}

-- Entry types
LoreConstants.ENTRY_TYPES = {
	TEXT = "text", -- Text only
	AUDIO = "audio", -- Audio only
	BOTH = "both", -- Both text and audio
}

-- Animation times
LoreConstants.ANIMATION = {
	CASSETTE_INSERT_DURATION = 1500, -- ms
	CASSETTE_EJECT_DURATION = 1200, -- ms
	AUDIO_VISUALIZER_UPDATE_RATE = 100, -- ms
}

-- UI Constants
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

-- Sound IDs
LoreConstants.SOUNDS = {
	AMBIENT = "amb_knoxnet_terminal_lore",
	CASSETTE_INSERT = "sfx_knoxnet_lore_cassette_insert",
	CASSETTE_EJECT = "sfx_knoxnet_lore_cassette_eject",
	ACTIVATE = "sfx_knoxnet_lore_activate",
	BUTTON = "sfx_knoxnet_key_4",
}

-- Metadata for auto-population
LoreConstants.DEFAULT_CATEGORIES = {
	{
		name = "General Information",
		description = "General information about Knox County and the outbreak.",
		entries = {
			{
				title = "Welcome to Knox County",
				content = "Welcome to the Knox County Emergency Network (KnoxNet). This system has been established to provide critical information during the ongoing crisis.\n\nThe Knox County authorities are working diligently to contain the situation. Please follow all emergency protocols and stay tuned for further instructions.",
				date = "1993-07-04",
			},
			{
				title = "Evacuation Protocol",
				content = "Knox County evacuation protocol is now in effect. All citizens should proceed to designated evacuation centers.\n\nBring only essential items. Do not attempt to drive personal vehicles outside the county. Military transport will be provided.",
				audioFile = "media/sound/knoxnet_evac_alert.ogg",
				requiresCassette = true,
				cassetteName = "Evacuation Protocol Tape",
				date = "1993-07-08",
			},
		},
	},
	{
		name = "Medical",
		description = "Medical information and emergency procedures.",
		entries = {
			{
				title = "Contamination Protocol",
				content = "If you suspect exposure to the infection, follow these steps:\n\n1. Isolate yourself immediately\n2. Cover any open wounds with clean bandages\n3. Monitor for symptoms: fever, disorientation, loss of consciousness\n4. Report to nearest medical checkpoint if symptoms develop\n\nDo NOT attempt self-medication. Official medical personnel will provide proper treatment.",
				date = "1993-07-09",
			},
			{
				title = "Medical Supply Conservation",
				content = "Due to the ongoing crisis, all residents must conserve medical supplies. Use only what is absolutely necessary.\n\nPriority medical care is available at designated emergency centers. Non-emergency cases should not seek medical attention at this time.",
				audioFile = "media/sound/knoxnet_medical_alert.ogg",
				requiresCassette = true,
				cassetteName = "Medical Conservation Tape",
				date = "1993-07-12",
			},
		},
	},
	{
		name = "Survivors' Accounts",
		description = "Personal accounts from Knox County residents.",
		entries = {
			{
				title = "Riverside Fishing Trip",
				content = "I was fishing at the Riverside spot when I heard all the commotion. People running, screaming. Something about an emergency at the hospital.\n\nI packed up my gear quick and headed home. Roads were jammed. Took me three hours to get back to my place in West Point. By then the radio was saying to stay indoors.\n\nI haven't left since. That was two days ago. Power's still on, thankfully. But I hear strange noises outside at night.",
				audioFile = "media/sound/knoxnet_survivor_riverside.ogg",
				requiresCassette = true,
				cassetteName = "Riverside Fishing Trip Recording",
				date = "1993-07-06",
			},
		},
	},
}

return LoreConstants
