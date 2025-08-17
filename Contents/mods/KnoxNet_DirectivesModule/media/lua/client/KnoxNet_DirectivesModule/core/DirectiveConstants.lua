---@class DirectiveConstants
local DirectiveConstants = {}

DirectiveConstants.LAYOUT = {
	DIRECTIVE_ITEM = {
		HEIGHT = 120,
		PADDING = 10,
		VISIBLE_COUNT = 5,
	},

	SCROLLBAR = {
		WIDTH = 10,
		MIN_HANDLE_HEIGHT = 30,
		PADDING = 5,
	},

	FONT = {
		SMALL = UIFont.Small,
		MEDIUM = UIFont.Medium,
		LARGE = UIFont.Large,
		CODE = UIFont.Code,
	},

	CONTENT = {
		PADDING_X = 20,
		PADDING_Y = 10,
		LINE_SPACING = 5,
		SECTION_SPACING = 20,
	},

	BUTTON = {
		HEIGHT = 30,
		WIDTH = 200,
		PADDING = 10,
		SPACING = 10,
	},

	FORM = {
		FIELD_HEIGHT = 30,
		LABEL_WIDTH = 120,
		FIELD_PADDING = 10,
	},

	TAB = {
		HEIGHT = 30,
		DEFAULT_PADDING = 10,
	},
}

DirectiveConstants.COLORS = {
	BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
	BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },

	TEXT = {
		NORMAL = { r = 1, g = 1, b = 1, a = 1 },
		DIM = { r = 0.4, g = 1, b = 0.4, a = 1 },
		HIGHLIGHT = { r = 0.8, g = 1, b = 0.8, a = 1 },
		WARNING = { r = 1, g = 0.8, b = 0.2, a = 1 },
		ERROR = { r = 1, g = 0.3, b = 0.3, a = 1 },
	},

	SCROLLBAR = {
		BACKGROUND = { r = 0.2, g = 0.3, b = 0.3, a = 0.3 },
		HANDLE = { r = 0.4, g = 1, b = 0.4, a = 0.4 },
		BORDER = { r = 0.3, g = 0.8, b = 0.3, a = 0.5 },
	},

	BUTTON = {
		NORMAL = { r = 0.2, g = 0.2, b = 1.0, a = 0.2 },
		HOVER = { r = 0.3, g = 0.3, b = 1.0, a = 0.5 },
		SELECTED = { r = 0.4, g = 0.4, b = 1.0, a = 0.7 },
		BORDER = { r = 0.2, g = 0.2, b = 1.0, a = 0.5 },
		DISABLED = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 },
		CLOSE = { r = 0.5, g = 0.1, b = 0.1, a = 1.0 },
	},

	ITEM = {
		BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
		SELECTED = { r = 0.2, g = 0.2, b = 0.3, a = 0.8 },
		BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
		ACTIVE = { r = 0.2, g = 0.5, b = 0.2, a = 0.7 },
		COMPLETED = { r = 0.5, g = 0.5, b = 0.2, a = 0.7 },
	},

	FIELD = {
		BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
		SELECTED = { r = 0.2, g = 0.2, b = 0.3, a = 0.8 },
		BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
		ACTIVE = { r = 0.2, g = 0.3, b = 0.5, a = 0.7 },
	},

	TAB = {
		BAR_BACKGROUND = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 },
		NORMAL = { r = 0.1, g = 0.1, b = 0.2, a = 0.7 },
		SELECTED = { r = 0.2, g = 0.2, b = 0.4, a = 0.9 },
		BORDER = { r = 0.3, g = 0.3, b = 0.5, a = 0.7 },
	},

	PROGRESS = {
		BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 },
		FILL = { r = 0.2, g = 0.8, b = 0.2, a = 0.8 },
		BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 },
	},
}

DirectiveConstants.DIRECTIVE_TYPES = {
	DEFAULT = "Default",
	SCAVENGE = "Scavenge",
}

DirectiveConstants.VIEWS = {
	ACTIVE = "active",
	HISTORY = "history",
	CONTRIBUTIONS = "contributions",
	DETAILS = "viewDirective",
}

-- Helper function to get progress bar color based on progress percentage
---@param progress number Progress value between 0 and 1
---@return table color RGBA color table
function DirectiveConstants.getProgressBarColor(progress)
	if progress < 0.3 then
		return { r = 0.8, g = 0.2, b = 0.2, a = 0.8 }
	elseif progress < 0.7 then
		return { r = 0.8, g = 0.8, b = 0.2, a = 0.8 }
	else
		return { r = 0.2, g = 0.8, b = 0.2, a = 0.8 }
	end
end

return DirectiveConstants
