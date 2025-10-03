local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local ScrollManager = require("KnoxNet/ui/ScrollManager")
local TerminalConstants = require("KnoxNet/core/TerminalConstants")

local TerminalMenuManager = {}

local MENU_OPTION_TYPES = {
	BUTTON = "button",
	SEPARATOR = "separator",
	MODULE = "module",
}

local DEFAULT_MENU_OPTIONS = {
	{
		id = "separator_1",
		type = MENU_OPTION_TYPES.SEPARATOR,
	},
	{
		id = "admin_control",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "Admin Control",
		action = function(self, terminal)
			local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
			KnoxNet_ControlPanel.openPanel()
		end,
		enabled = function(self, terminal)
			local hasAccess = false
			if not isServer() and not isClient() then
				hasAccess = true
			elseif isClient() then
				hasAccess = isAdmin()
			end
			if getDebug() then
				hasAccess = true
			end
			return hasAccess
		end,
	},
	{
		id = "configuration",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "Configuration",
		action = function(self, terminal)
			terminal:changeState("settings")
		end,
		enabled = true,
	},
	{
		id = "separator_2",
		type = MENU_OPTION_TYPES.SEPARATOR,
	},
	{
		id = "power_down",
		type = MENU_OPTION_TYPES.BUTTON,
		text = "Power Down",
		action = function(self, terminal)
			terminal:close()
		end,
		enabled = true,
	},
}

function TerminalMenuManager:new(terminal)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.terminal = terminal
	o.menuOptions = table.newarray() --[[@as table]]
	o.selectedOption = 1
	o.scrollManager = nil
	o.optionHeight = 40
	o.optionSpacing = 10
	o.optionWidth = 300

	o:initializeDefaultOptions()
	o:addModuleOptions()

	return o
end

function TerminalMenuManager:initializeDefaultOptions()
	for i = 1, #DEFAULT_MENU_OPTIONS do
		local newOption = {}
		for k, v in pairs(DEFAULT_MENU_OPTIONS[i]) do
			newOption[k] = v
		end
		table.insert(self.menuOptions, newOption)
	end
end

function TerminalMenuManager:addModuleOptions()
	for name, module in pairs(self.terminal.activeModules) do
		table.insert(self.menuOptions, 1, {
			id = "module_" .. name,
			type = MENU_OPTION_TYPES.MODULE,
			text = name,
			moduleName = name,
			action = function(self, terminal)
				terminal:changeState("module", name)
			end,
			enabled = true,
		})
	end

	self:addCustomMenuOptions()

	self:initializeScrollManager()
end

function TerminalMenuManager:addCustomMenuOptions()
	-- this function can be overridden by other mods to add custom menu options
	-- example:
	-- self:addMenuOption({
	--     id = "custom_option",
	--     type = MENU_OPTION_TYPES.BUTTON,
	--     text = "Custom Option",
	--     action = function(self, terminal)
	--         -- Custom action here
	--     end,
	--     enabled = true,
	-- })
end

function TerminalMenuManager:initializeScrollManager()
	-- Get responsive padding based on terminal size
	local padding = TerminalConstants.getResponsivePadding(self.terminal.width, self.terminal.height)

	-- Calculate content area dimensions (EXCLUDING padding)
	local contentHeight = self.terminal.contentAreaHeight - (padding.contentEdge * 2)
	local totalHeight = #self.menuOptions * (self.optionHeight + self.optionSpacing) - self.optionSpacing

	-- Create scroll manager with content area dimensions (excluding padding)
	self.scrollManager = ScrollManager:new(totalHeight, contentHeight)

	-- Ensure scroll manager uses content area coordinates
	if self.scrollManager then
		self.scrollManager:updateContentHeight(totalHeight)
		self.scrollManager:updateVisibleHeight(contentHeight)
	end
end

function TerminalMenuManager:addMenuOption(option)
	table.insert(self.menuOptions, option)

	if self.scrollManager then
		local totalHeight = #self.menuOptions * (self.optionHeight + self.optionSpacing) - self.optionSpacing
		self.scrollManager:updateContentHeight(totalHeight)
	end
end

function TerminalMenuManager:activate()
	self.selectedOption = 1

	if self.scrollManager then
		-- Get responsive padding based on terminal size
		local padding = TerminalConstants.getResponsivePadding(self.terminal.width, self.terminal.height)

		-- Use content area height MINUS padding for scroll manager
		local contentHeight = self.terminal.contentAreaHeight - (padding.contentEdge * 2)
		self.scrollManager:updateVisibleHeight(contentHeight)

		-- Reset scroll to beginning of content area
		self.scrollManager:scrollTo(0, false)
	end

	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function TerminalMenuManager:onKeyPress(key)
	if key == Keyboard.KEY_UP then
		self:selectPreviousOption()
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_DOWN then
		self:selectNextOption()
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_ENTER then
		self:executeSelectedOption()
		return true
	elseif key == Keyboard.KEY_BACK then
		self.terminal:close()
		TerminalSounds.playUISound("sfx_knoxnet_key_3")
		return true
	end
	return false
end

function TerminalMenuManager:selectPreviousOption()
	local enabledOptions = self:getEnabledOptions()
	if #enabledOptions == 0 then
		return
	end

	local currentIndex = self:getCurrentOptionIndex()
	local newIndex = currentIndex - 1
	if newIndex < 1 then
		newIndex = #enabledOptions
	end

	self.selectedOption = enabledOptions[newIndex]
	self:ensureOptionVisible()
end

function TerminalMenuManager:selectNextOption()
	local enabledOptions = self:getEnabledOptions()
	if #enabledOptions == 0 then
		return
	end

	local currentIndex = self:getCurrentOptionIndex()
	local newIndex = currentIndex + 1
	if newIndex > #enabledOptions then
		newIndex = 1
	end

	self.selectedOption = enabledOptions[newIndex]
	self:ensureOptionVisible()
end

function TerminalMenuManager:ensureOptionVisible()
	if not self.scrollManager then
		return
	end

	local optionIndex = self.selectedOption
	local optionY = (optionIndex - 1) * (self.optionHeight + self.optionSpacing)
	local visibleHeight = self.scrollManager.visibleHeight

	-- Use more permissive bounds checking
	if optionY < self.scrollManager.scrollOffset then
		self.scrollManager:scrollTo(optionY, true)
	elseif optionY + self.optionHeight > self.scrollManager.scrollOffset + visibleHeight then
		self.scrollManager:scrollTo(optionY + self.optionHeight - visibleHeight, true)
	end
end

function TerminalMenuManager:getEnabledOptions()
	local enabled = table.newarray() --[[@as table]]
	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		if option.type ~= MENU_OPTION_TYPES.SEPARATOR then
			local isEnabled = option.enabled
			if type(isEnabled) == "function" then
				isEnabled = isEnabled(self, self.terminal)
			end
			if isEnabled then
				table.insert(enabled, i)
			end
		end
	end
	return enabled
end

function TerminalMenuManager:getCurrentOptionIndex()
	local enabledOptions = self:getEnabledOptions()
	for i = 1, #enabledOptions do
		if enabledOptions[i] == self.selectedOption then
			return i
		end
	end
	return 1
end

function TerminalMenuManager:executeSelectedOption()
	local option = self.menuOptions[self.selectedOption]
	if option and option.action and option.enabled then
		option.action(self, self.terminal)
	end
end

function TerminalMenuManager:onMouseUp(x, y)
	-- Get responsive padding based on terminal size
	local padding = TerminalConstants.getResponsivePadding(self.terminal.width, self.terminal.height)

	-- Calculate content area with proper padding
	local contentX = self.terminal.displayX + padding.contentEdge
	local contentY = self.terminal.contentAreaY + padding.contentEdge
	local contentWidth = self.terminal.displayWidth - (padding.contentEdge * 2)
	local contentHeight = self.terminal.contentAreaHeight - (padding.contentEdge * 2)

	local menuX = contentX + padding.contentEdge
	local menuY = contentY + padding.contentEdge

	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		if option.type ~= MENU_OPTION_TYPES.SEPARATOR then
			local isEnabled = option.enabled
			if type(isEnabled) == "function" then
				isEnabled = isEnabled(self, self.terminal)
			end

			if isEnabled then
				local optionY = menuY + (i - 1) * (self.optionHeight + self.optionSpacing)
				local adjustedY = optionY - (self.scrollManager and self.scrollManager.scrollOffset or 0)

				if
					x >= menuX
					and x <= menuX + self.optionWidth
					and y >= adjustedY
					and y <= adjustedY + self.optionHeight
				then
					self.selectedOption = i
					self:executeSelectedOption()
					return true
				end
			end
		end
	end

	return false
end

function TerminalMenuManager:onMouseWheel(delta)
	if self.scrollManager then
		-- Ensure scroll manager can handle the delta properly
		local oldOffset = self.scrollManager.scrollOffset
		self.scrollManager:onMouseWheel(delta)
		local newOffset = self.scrollManager.scrollOffset

		-- Debug scroll changes
		if oldOffset ~= newOffset then
			print(
				"TerminalMenuManager: Scroll offset changed from "
					.. oldOffset
					.. " to "
					.. newOffset
					.. " (delta: "
					.. delta
					.. ")"
			)
		end

		return true
	end
	return false
end

function TerminalMenuManager:update()
	if self.scrollManager then
		self.scrollManager:update(16.67) -- 60 FPS
	end
end

function TerminalMenuManager:render()
	self.terminal:renderTitle("KNOXNET EMERGENCY TERMINAL SYSTEM")

	-- Get responsive padding based on terminal size
	local padding = TerminalConstants.getResponsivePadding(self.terminal.width, self.terminal.height)

	-- Calculate content area with proper padding - EXCLUDE title/footer areas
	local contentX = self.terminal.displayX + padding.contentEdge
	local contentY = self.terminal.contentAreaY + padding.contentEdge
	local contentWidth = self.terminal.displayWidth - (padding.contentEdge * 2)
	local contentHeight = self.terminal.contentAreaHeight - (padding.contentEdge * 2)

	-- Update option width to use available content width
	self.optionWidth = math.max(300, contentWidth - (padding.contentEdge * 2))

	local termColors = TerminalConstants.COLORS

	-- Render background for content area only
	self.terminal:drawRect(
		contentX,
		contentY,
		contentWidth,
		contentHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)

	-- Menu positioning: Start from content area, not terminal area
	local menuX = contentX + padding.contentEdge
	local menuY = contentY + padding.contentEdge
	local scrollOffset = self.scrollManager and self.scrollManager.scrollOffset or 0

	-- Debug info
	local renderedCount = 0
	local totalOptions = #self.menuOptions

	for i = 1, #self.menuOptions do
		local option = self.menuOptions[i]
		-- Calculate option position relative to content area
		local optionY = menuY + (i - 1) * (self.optionHeight + self.optionSpacing)
		local visibleY = optionY - scrollOffset

		-- SMART CLIPPING: Allow partial visibility for smooth scrolling, but prevent title/footer overlap
		-- Check if button intersects with content area (allows partial visibility)
		if visibleY + self.optionHeight > contentY and visibleY < contentY + contentHeight then
			renderedCount = renderedCount + 1

			if option.type == MENU_OPTION_TYPES.SEPARATOR then
				local separatorY = visibleY + self.optionHeight / 2
				self.terminal:drawRect(
					menuX,
					separatorY,
					self.optionWidth,
					2,
					termColors.BORDER.a,
					termColors.BORDER.r,
					termColors.BORDER.g,
					termColors.BORDER.b
				)
			else
				local isSelected = (i == self.selectedOption)
				local isEnabled = option.enabled
				if type(isEnabled) == "function" then
					isEnabled = isEnabled(self, self.terminal)
				end

				local bgColor = isSelected and termColors.BUTTON.SELECTED or termColors.BUTTON.COLOR
				local borderColor = termColors.BUTTON.BORDER
				local textColor = isEnabled and termColors.TEXT.NORMAL or termColors.TEXT.DIM

				if isEnabled then
					self.terminal:drawRect(
						menuX,
						visibleY,
						self.optionWidth,
						self.optionHeight,
						bgColor.a,
						bgColor.r,
						bgColor.g,
						bgColor.b
					)
				end

				self.terminal:drawRectBorder(
					menuX,
					visibleY,
					self.optionWidth,
					self.optionHeight,
					borderColor.a,
					borderColor.r,
					borderColor.g,
					borderColor.b
				)

				local textX = menuX + padding.base
				local textY = visibleY + (self.optionHeight - 15) / 2

				self.terminal:drawText(
					option.text,
					textX,
					textY,
					textColor.r,
					textColor.g,
					textColor.b,
					textColor.a,
					TerminalConstants.FONT.CODE
				)
			end
		end
	end

	-- Debug info
	if self.scrollManager then
		local debugText = string.format(
			"Options: %d/%d | Scroll: %.1f | Content: %.1f/%.1f",
			renderedCount,
			totalOptions,
			scrollOffset,
			self.scrollManager.contentHeight,
			self.scrollManager.visibleHeight
		)

		-- Render debug info in top-right corner
		local debugX = contentX
			+ contentWidth
			- getTextManager():MeasureStringX(TerminalConstants.FONT.SMALL, debugText)
			- 10
		local debugY = contentY + 5

		self.terminal:drawText(debugText, debugX, debugY, 0.8, 0.8, 0.8, 0.7, TerminalConstants.FONT.SMALL)
	end

	-- Render scrollbar if needed - ensure it's within content bounds
	if self.scrollManager and self.scrollManager.contentHeight > self.scrollManager.visibleHeight then
		local scrollbarX = contentX + contentWidth - TerminalConstants.LAYOUT.SCROLLBAR.WIDTH
		local scrollbarY = contentY
		local scrollbarHeight = contentHeight

		self.scrollManager:renderScrollbar(self.terminal, scrollbarX, scrollbarY, scrollbarHeight)
	end

	self.terminal:renderFooter("ARROWS - NAVIGATE | SPACE/ENTER - SELECT | BACKSPACE - EXIT")
end

return TerminalMenuManager
