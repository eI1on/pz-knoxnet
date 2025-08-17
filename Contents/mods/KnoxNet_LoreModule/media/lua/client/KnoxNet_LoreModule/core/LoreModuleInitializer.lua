local Logger = require("KnoxNet/Logger")
local KnoxNet_Terminal = require("KnoxNet/core/Terminal")
local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
local LoreModule = require("KnoxNet_LoreModule/ui/LoreModule")
local LoreManagerPanel = require("KnoxNet_LoreModule/ui/LoreManagerPanel")
local LoreManager = require("KnoxNet_LoreModule/core/LoreManager")

---@class LoreModuleInitializer
local LoreModuleInitializer = {}

function LoreModuleInitializer.init()
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
end

Events.OnGameStart.Add(function()
	LoreManager.loadLoreData()
end)

LoreModuleInitializer.init()

return LoreModuleInitializer
