local KnoxNet_Terminal = require("KnoxNet/core/Terminal")
local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
local LoreModule = require("KnoxNet/modules/lore/LoreModule")
local LoreManagerPanel = require("KnoxNet/modules/lore/LoreManagerPanel")
local LoreManager = require("KnoxNet/modules/lore/LoreManager")
local Logger = require("KnoxNet/Logger")

---@class LoreModuleInitializer
local LoreModuleInitializer = {}

-- Initialize the lore module and register it with KnoxNet
function LoreModuleInitializer.init()
	Logger:info("Initializing Lore Module")

	KnoxNet_Terminal.registerModule("Lore Database", {
		onActivate = function(self)
			self.terminal = self.terminal or {}
			LoreModule.terminal = self.terminal
			LoreModule:onActivate()
		end,

		onDeactivate = function(self)
			LoreModule:onDeactivate()
		end,

		onClose = function(self)
			LoreModule:onClose()
		end,

		update = function(self)
			LoreModule:update()
		end,

		render = function(self)
			LoreModule:render()
		end,

		onKeyPress = function(self, key)
			return LoreModule:onKeyPress(key)
		end,

		onMouseWheel = function(self, delta)
			return LoreModule:onMouseWheel(delta)
		end,

		onMouseDown = function(self, x, y)
			return LoreModule:onMouseDown(x, y)
		end,
	})

	KnoxNet_ControlPanel.registerModule("lore_database", "Lore Database", function(x, y, width, height)
		return LoreManagerPanel:new(x, y, width, height)
	end)

	LoreModuleInitializer.setupAPI()
end

-- Setup API for other mods to interact with the lore system
function LoreModuleInitializer.setupAPI()
	---@class KnoxNet_LoreModule_API
	LoreModuleInitializer.API = {}

	-- Add a category
	---@param name string Category name
	---@param description string Category description
	---@return string categoryId The created category ID
	function LoreModuleInitializer.API.addCategory(name, description)
		return LoreManager.addCategory(name, description)
	end

	-- Add an entry
	---@param categoryId string Category ID
	---@param title string Entry title
	---@param content string Entry text content
	---@param audioFile string|nil Path to audio file (optional)
	---@param requiresCassette boolean Whether this entry requires a cassette
	---@param cassetteName string|nil Custom cassette name (optional)
	---@param date string|nil Date of the entry (optional)
	---@return string|nil entryId The created entry ID
	function LoreModuleInitializer.API.addEntry(
		categoryId,
		title,
		content,
		audioFile,
		requiresCassette,
		cassetteName,
		date
	)
		return LoreManager.addEntry(categoryId, title, content, audioFile, requiresCassette, cassetteName, date)
	end

	-- Get all categories
	---@return table categories List of all categories
	function LoreModuleInitializer.API.getCategories()
		return LoreManager.getCategories()
	end

	-- Get all entries
	---@return table entries List of all entries
	function LoreModuleInitializer.API.getEntries()
		return LoreManager.getEntries()
	end
end

Events.OnGameStart.Add(function()
	LoreManager.loadLoreData()
end)

-- Initialize the module
LoreModuleInitializer.init()

return LoreModuleInitializer
