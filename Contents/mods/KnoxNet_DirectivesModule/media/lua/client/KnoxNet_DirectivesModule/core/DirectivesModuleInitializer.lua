local KnoxNet_Terminal = require("KnoxNet/core/Terminal")
local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
local DirectiveModuleManager = require("KnoxNet_DirectivesModule/core/DirectiveModuleManager")

---@class DirectivesModuleInitializer
local DirectivesModuleInitializer = {}

function DirectivesModuleInitializer.init()
	KnoxNet_Terminal.registerModule("Directives", {
		onActivate = function(self)
			self.terminal = self.terminal or {}
			DirectiveModuleManager.terminal = self.terminal
			DirectiveModuleManager.onActivate()
		end,

		onDeactivate = function(self)
			DirectiveModuleManager.onDeactivate()
		end,

		onClose = function(self)
			DirectiveModuleManager.onClose()
		end,

		update = function(self)
			DirectiveModuleManager.update()
		end,

		render = function(self)
			DirectiveModuleManager.render()
		end,

		onKeyPress = function(self, key)
			return DirectiveModuleManager.onKeyPress(key)
		end,

		onMouseWheel = function(self, delta)
			return DirectiveModuleManager.onMouseWheel(delta)
		end,

		onMouseDown = function(self, x, y)
			return DirectiveModuleManager.onMouseDown(x, y)
		end,
	})

	KnoxNet_ControlPanel.registerModule("directives", "Directives", function(x, y, width, height)
		local DirectiveEditorPanel = require("KnoxNet_DirectivesModule/ui/DirectiveEditorPanel")
		return DirectiveEditorPanel:new(x, y, width, height)
	end)
end

DirectivesModuleInitializer.init()

return DirectivesModuleInitializer
