local TerminalConstants = require("KnoxNet/core/TerminalConstants")

---@class KnoxNet_ControlPanel : ISPanel
local KnoxNet_ControlPanel = ISPanel:derive("KnoxNet_ControlPanel")

KnoxNet_ControlPanel.registeredModules = {}

-- Register a module to be available in the main panel
---@param moduleId string Unique identifier for the module
---@param moduleName string Display name for the module
---@param moduleFactory function Function that creates the module panel
function KnoxNet_ControlPanel.registerModule(moduleId, moduleName, moduleFactory)
	if not KnoxNet_ControlPanel.registeredModules[moduleId] then
		KnoxNet_ControlPanel.registeredModules[moduleId] = {
			id = moduleId,
			name = moduleName,
			factory = moduleFactory,
		}
	end
end

function KnoxNet_ControlPanel:createChildren()
	self.titleFontHeight = getTextManager():getFontHeight(UIFont.Medium)
	self.buttonFontHeight = getTextManager():getFontHeight(UIFont.Small)

	self:createTabs()
	self:activateFirstPanel()
end

function KnoxNet_ControlPanel:createTabs()
	local tabHeight = TerminalConstants.LAYOUT.TAB.HEIGHT
	local topY = TerminalConstants.LAYOUT.TITLE_HEIGHT + 5
	local btnMargin = 10
	local startX = 10

	self.tabs = {}
	for i, module in ipairs(self:getOrderedModules()) do
		local textWidth = getTextManager():MeasureStringX(UIFont.Small, module.name)
			+ TerminalConstants.LAYOUT.TAB.PADDING * 2

		local tabBtn = ISButton:new(startX, topY, textWidth, tabHeight, module.name, self, function()
			self:activatePanel(module.id)
		end)
		tabBtn:initialise()
		tabBtn.backgroundColor = TerminalConstants.COLORS.TAB.NORMAL
		tabBtn.borderColor = TerminalConstants.COLORS.BORDER
		tabBtn.textColor = TerminalConstants.COLORS.TEXT.NORMAL
		self:addChild(tabBtn)

		self.tabs[module.id] = tabBtn
		startX = startX + textWidth + btnMargin
	end

	local closeSize = tabHeight
	self.closeButton =
		ISButton:new(self.width - closeSize - 10, topY, closeSize, closeSize, "X", self, KnoxNet_ControlPanel.close)
	self.closeButton:initialise()
	self.closeButton.backgroundColor = TerminalConstants.COLORS.BUTTON.CLOSE
	self.closeButton.borderColor = TerminalConstants.COLORS.BORDER
	self.closeButton.textColor = { r = 1, g = 1, b = 1, a = 1 }
	self:addChild(self.closeButton)
end

function KnoxNet_ControlPanel:close()
	self:setVisible(false)
	self:removeFromUIManager()
	KnoxNet_ControlPanel.instance = nil
end

function KnoxNet_ControlPanel:activatePanel(moduleId)
	if self.currentPanel then
		self:removeChild(self.currentPanel)
		self.currentPanel = nil
	end

	for id, tab in pairs(self.tabs) do
		tab.backgroundColor = (id == moduleId) and TerminalConstants.COLORS.TAB.SELECTED
			or TerminalConstants.COLORS.TAB.NORMAL
	end

	local module = KnoxNet_ControlPanel.registeredModules[moduleId]
	if module and module.factory then
		local y = TerminalConstants.LAYOUT.TITLE_HEIGHT + TerminalConstants.LAYOUT.TAB.HEIGHT + 10
		local panelHeight = self.height - y - TerminalConstants.LAYOUT.PADDING.CONTENT

		self.currentPanel = module.factory(
			TerminalConstants.LAYOUT.PADDING.CONTENT,
			y,
			self.width - (TerminalConstants.LAYOUT.PADDING.CONTENT * 2),
			panelHeight
		)

		if self.currentPanel then
			self.currentPanel:initialise()
			self:addChild(self.currentPanel)
		end
	end
end

function KnoxNet_ControlPanel:activateFirstPanel()
	local modules = self:getOrderedModules()
	if #modules > 0 then
		self:activatePanel(modules[1].id)
	end
end

function KnoxNet_ControlPanel:getOrderedModules()
	local modules = {}
	for _, module in pairs(KnoxNet_ControlPanel.registeredModules) do
		table.insert(modules, module)
	end

	table.sort(modules, function(a, b)
		return a.name < b.name
	end)
	return modules
end

function KnoxNet_ControlPanel:prerender()
	ISPanel.prerender(self)

	local titleText = "KnoxNet Terminal Control System v0.1"
	local titleX = (self.width - getTextManager():MeasureStringX(UIFont.Medium, titleText)) / 2
	self:drawText(
		titleText,
		titleX,
		5,
		TerminalConstants.COLORS.TEXT.NORMAL.r,
		TerminalConstants.COLORS.TEXT.NORMAL.g,
		TerminalConstants.COLORS.TEXT.NORMAL.b,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		UIFont.Medium
	)

	self:drawRect(
		10,
		TerminalConstants.LAYOUT.TITLE_HEIGHT - 2,
		self.width - 20,
		1,
		0.5,
		TerminalConstants.COLORS.TEXT.DIM.r,
		TerminalConstants.COLORS.TEXT.DIM.g,
		TerminalConstants.COLORS.TEXT.DIM.b
	)
end

-- Create a new ControlPanel
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@return KnoxNet_ControlPanel
function KnoxNet_ControlPanel:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	o.backgroundColor = TerminalConstants.COLORS.BACKGROUND
	o.borderColor = TerminalConstants.COLORS.BORDER
	o.moveWithMouse = true

	return o
end

-- Open the main control panel
---@return KnoxNet_ControlPanel|nil
function KnoxNet_ControlPanel.openPanel()
	local hasAccess = false
	if not isServer() and not isClient() then
		hasAccess = true
	elseif isClient() then
		hasAccess = isAdmin()
	end

	if getDebug() then
		hasAccess = true
	end

	if not hasAccess then
		return nil
	end

	if KnoxNet_ControlPanel.instance then
		KnoxNet_ControlPanel.instance:close()
	end

	local w = 850
	local h = 650
	local x = (getCore():getScreenWidth() / 2) - (w / 2)
	local y = (getCore():getScreenHeight() / 2) - (h / 2)

	local panel = KnoxNet_ControlPanel:new(x, y, w, h)
	panel:initialise()
	panel:addToUIManager()

	KnoxNet_ControlPanel.instance = panel
	return panel
end

return KnoxNet_ControlPanel
