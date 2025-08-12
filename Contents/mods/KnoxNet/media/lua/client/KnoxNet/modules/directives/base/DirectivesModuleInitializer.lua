local KnoxNet_Terminal = require("KnoxNet/core/Terminal")
local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
local DirectiveModuleManager = require("KnoxNet/modules/directives/base/DirectiveModuleManager")

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
		local DirectiveEditorPanel = require("KnoxNet/modules/directives/ui/DirectiveEditorPanel")
		return DirectiveEditorPanel:new(x, y, width, height)
	end)

	DirectivesModuleInitializer.setupAPI()
end

function DirectivesModuleInitializer.setupAPI()
	---@class KnoxNet_DirectivesModule_API
	DirectivesModuleInitializer.API = {}

	---Registers a new directive type with the system
	---@param typeName string The name of the directive type
	---@param moduleData table The module data containing functions and properties
	function DirectivesModuleInitializer.API.registerDirectiveType(typeName, moduleData)
		local DirectiveManager = require("KnoxNet/modules/directives/base/DirectiveManager")
		DirectiveManager.registerDirectiveType(typeName, moduleData)
	end

	---Creates a new directive instance
	---@param typeName string The type of directive to create
	---@param data table Initial data for the directive
	---@return BaseDirective|nil directive The created directive instance
	function DirectivesModuleInitializer.API.createDirective(typeName, data)
		local DirectiveManager = require("KnoxNet/modules/directives/base/DirectiveManager")
		return DirectiveManager.createDirective(typeName, data)
	end
end

DirectivesModuleInitializer.init()

return DirectivesModuleInitializer
