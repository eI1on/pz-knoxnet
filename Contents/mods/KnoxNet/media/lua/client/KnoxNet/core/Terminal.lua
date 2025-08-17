local getTimeInMillis = getTimeInMillis

local ColorUtils = require("ElyonLib/ColorUtils/ColorUtils")
local TableUtils = require("ElyonLib/TableUtils/TableUtils")
local AudioManager = require("KnoxNet/core/AudioManager")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local TerminalConstants = require("KnoxNet/core/TerminalConstants")

---@class KnoxNet_Terminal : ISPanel
---@field instance KnoxNet_Terminal
---@field modules table<string, table>
---@field activeModules table<string, table>
---@field states table<string, table>
---@field currentState string
---@field backgroundMusicId number
---@field crtMonitorTexture Texture
---@field crtScreenTexture Texture
---@field origTexWidth number
---@field origTexHeight number
---@field origScreenX number
---@field origScreenY number
---@field origScreenWidth number
---@field origScreenHeight number
---@field baseWidth number
---@field baseHeight number
---@field scaleX number
---@field scaleY number
---@field displayX number
---@field displayY number
---@field displayWidth number
---@field displayHeight number
---@field textPaddingX number
---@field textPaddingY number
---@field lineHeight number
---@field titleAreaY number
---@field titleAreaHeight number
---@field contentAreaY number
---@field contentAreaHeight number
---@field footerAreaY number
---@field footerAreaHeight number
---@field maxVisibleLines number
---@field crtFlicker number
---@field crtIntensity number
---@field lastRenderTime number
---@field rainbowMode boolean
---@field rainbowHue number
---@field lastRainbowUpdate number
---@field terminalColorScheme string
---@field screenBrightness number
---@field textBrightnessMultiplier number
---@field buttons table
---@field selectedButton number
---@field buttonHeight number
---@field buttonPadding number
---@field bootLines table
---@field asciiArt string
---@field currentLine number
---@field currentChar number
---@field lastCharUpdate number
---@field charDelay number
---@field lineDelay number
---@field bootInitComplete boolean
---@field bootComplete boolean
---@field showAsciiArt boolean
---@field displayText string
---@field visibleText string
---@field contentText string
---@field titleText string
---@field crtEffectsEnabled boolean
---@field powerButtonX number
---@field powerButtonY number
---@field powerButtonWidth number
---@field powerButtonHeight number
---@field scrollManager ScrollManager
local KnoxNet_Terminal = ISPanel:derive("KnoxNet_Terminal")
KnoxNet_Terminal.instance = nil

local keybind_storage = {}

local function storeKeyBinds(...)
	for _, key in pairs({ ... }) do
		keybind_storage[key] = getCore():getKey(key)
		getCore():addKeyBinding(key, 0)
	end
end

local function restoreKeyBinds(...)
	for _, key in pairs({ ... }) do
		getCore():addKeyBinding(key, keybind_storage[key] or getCore():getKey(key))
	end
end

KnoxNet_Terminal.modules = {}

---Registers a new module for the terminal
---@param moduleName string The name of the module
---@param moduleData table The module data containing functions and properties
function KnoxNet_Terminal.registerModule(moduleName, moduleData)
	if not KnoxNet_Terminal.modules[moduleName] then
		KnoxNet_Terminal.modules[moduleName] = moduleData
	end
end

function KnoxNet_Terminal:initialise()
	ISPanel.initialise(self)

	self:initCRTComponents()
	self:initStates()
	self:initModules()

	storeKeyBinds(unpack(TerminalConstants.DISABLED_KEYS))

	self:changeState("powerOff")
end

function KnoxNet_Terminal:close()
	if self.backgroundMusicId then
		AudioManager.stopSound(self.backgroundMusicId)
		self.backgroundMusicId = nil
	end

	TerminalSounds.stopAllSounds()
	restoreKeyBinds(unpack(TerminalConstants.DISABLED_KEYS))

	for _, module in pairs(self.activeModules) do
		if module.onClose then
			module:onClose()
		end
	end

	self:setVisible(false)
	self:removeFromUIManager()
	KnoxNet_Terminal.instance = nil
end

function KnoxNet_Terminal:initCRTComponents()
	self.origScreenX = 81
	self.origScreenY = 68
	self.origScreenWidth = 685
	self.origScreenHeight = 476

	self.scaleX = self.baseWidth / self.origTexWidth
	self.scaleY = self.baseHeight / self.origTexHeight

	self.displayX = self.origScreenX * self.scaleX
	self.displayY = self.origScreenY * self.scaleY
	self.displayWidth = self.origScreenWidth * self.scaleX
	self.displayHeight = self.origScreenHeight * self.scaleY

	self.textPaddingX = 15 * self.scaleX -- 15px padding in original texture
	self.textPaddingY = 10 * self.scaleY -- 10px padding in original texture

	self.lineHeight = math.floor(
		(self.displayHeight - TerminalConstants.LAYOUT.TITLE_HEIGHT - TerminalConstants.LAYOUT.FOOTER_HEIGHT) / 20
	) -- 20 lines max

	self.titleAreaY = self.displayY
	self.titleAreaHeight = TerminalConstants.LAYOUT.TITLE_HEIGHT

	self.contentAreaY = self.titleAreaY + self.titleAreaHeight
	self.contentAreaHeight = self.displayHeight - self.titleAreaHeight - TerminalConstants.LAYOUT.FOOTER_HEIGHT

	self.footerAreaY = self.contentAreaY + self.contentAreaHeight
	self.footerAreaHeight = TerminalConstants.LAYOUT.FOOTER_HEIGHT

	local ScrollManager = require("KnoxNet/ui/ScrollManager")
	self.scrollManager = ScrollManager:new(0, self.contentAreaHeight)
	self.scrollManager:setAutoScroll(true)
	self.maxVisibleLines = math.floor(self.contentAreaHeight / self.lineHeight)

	self.footerScrollOffset = 0
	self.footerScrollSpeed = 1.2
	self.lastFooterScrollUpdate = 0
	self.footerScrollDelay = 16
	self.footerScrollEnabled = true
	self.footerScrollSpeedLevel = 2
	self.footerScrollPauseTime = 2000
	self.footerScrollState = "scrolling" -- states: "scrolling", "paused"
	self.footerScrollPauseStart = 0

	self.crtFlicker = 0
	self.crtIntensity = 1.0
	self.lastRenderTime = 0

	self.rainbowMode = false
	self.rainbowHue = 0
	self.terminalColorScheme = "green"
	self.screenBrightness = 1 -- default 100%
	self.textBrightnessMultiplier = 1 -- default 100%
	self:applyColorScheme()

	self.buttons = {}
	self.selectedButton = 1
	self.buttonHeight = self.lineHeight * 1.5
	self.buttonPadding = 5

	self:initBootSequence()
end

function KnoxNet_Terminal:initBootSequence()
	self.bootLines = {
		"ELYON TECHNOLOGIES // KNOX COUNTY EMERGENCY NETWORK",
		"BIOS v2.3 INIT... MEMORY 64K OK... CRT OK [0x07E9]",
		"KNOX-TECH MODEL K7 TERMINAL ONLINE [1993-07-19 06:28]",
		" ",
		"DIAGNOSTICS:",
		"> POWER: OPERATIONAL [BACKUP GENERATOR]",
		"> UPLINK: LOCAL NODE ACTIVE [MESH NETWORK]",
		"> SECURITY: QUARANTINE PROTOCOL ACTIVE",
		" ",
		"MOUNTING KNOXNET OS v3.1...",
		"Knox Network Emergency Terminal System",
		" ",
		"KNOX COUNTY CONDITION: CRITICAL",
		"> INFECTION SPREAD: 91% POPULATION",
		"> SAFE ZONES: UNKNOWN",
		"> MILITARY PRESENCE: NONE DETECTED",
		" ",
		"ADVISORY: REMAIN INDOORS",
		"AVOID ALL INFECTED INDIVIDUALS",
		" ",
		"BOOTING KNOXNET INTERFACE...",
	}

	self.asciiArt = [[
     _  __                  _   _      _
    | |/ /                 | \ | |    | |
    | ' / _ __   _____  __ |  \| | ___| |_
    |  < | '_ \ / _ \ \/ / | . ` |/ _ \ __|
    | . \| | | | (_) >  <  | |\  |  __/ |_
    |_|\_\_| |_|\___/_/\_\ |_| \_|\___|\__|
 
 
Knox County Emergency Network Terminal System
    ]]

	self.currentLine = 1
	self.currentChar = 1
	self.lastCharUpdate = 0

	self.charDelay = 15 -- default to normal speed (5=fast, 15=normal, 30=slow)
	self.lineDelay = 0

	self.bootInitComplete = false
	self.bootComplete = false
	self.showAsciiArt = false

	self.displayText = ""
	self.visibleText = ""
end

function KnoxNet_Terminal:initStates()
	self.states = {
		powerOff = {
			enter = function(self)
				TerminalSounds.stopAllSounds()
				TerminalSounds.playUISound("sfx_knoxnet_poweroff")

				self.visibleText = ""
				self.displayText = ""
			end,
			render = function(self)
				self:renderPowerOffScreen()
			end,
			onKeyPress = function(self, key)
				return false
			end,
		},
		bootAndAscii = {
			enter = function(self)
				TerminalSounds.playUISound("sfx_knoxnet_poweron")
				self.backgroundMusicId = TerminalSounds.playLoopedSound("amb_knoxnet_terminal_hum")

				self:initBootSequence()
				self.showAsciiArt = false
				self.scrollManager:scrollTo(0, false)
				self.scrollManager:setAutoScroll(true)
			end,
			update = function(self)
				if not self.showAsciiArt then
					local currentTime = getTimeInMillis()
					if currentTime > self.lastCharUpdate + self.charDelay then
						for i = 1, 10 do -- process multiple chars per frame
							self:progressBootSequence()
							if self.bootInitComplete then
								break
							end
						end
						self.lastCharUpdate = currentTime
					end
				end
			end,
			render = function(self)
				self:renderCRTScreen()

				if self.showAsciiArt then
					self:renderText(self.asciiArt)
					self:renderFooter("PRESS SPACE TO CONTINUE | BACKSPACE - EXIT")
				else
					self:renderText(self.visibleText)

					if self.bootInitComplete then
						self:renderFooter("PRESS SPACE TO CONTINUE | BACKSPACE - EXIT | UP/DOWN - SCROLL")
					end
				end

				self:renderPowerButton()
			end,
			onKeyPress = function(self, key)
				self:playRandomKeySound()

				if key == TerminalConstants.KEYS.CONFIRM then
					if not self.showAsciiArt and self.bootInitComplete then
						self.showAsciiArt = true
					elseif self.showAsciiArt then
						self:changeState("mainMenu")
					end
					return true
				elseif key == TerminalConstants.KEYS.CLOSE then
					self:close()
					return true
				elseif key == TerminalConstants.KEYS.UP then
					if self.scrollManager and not self.showAsciiArt then
						self.scrollManager:setAutoScroll(false)
						self:scrollUp(self.lineHeight)
						return true
					end
				elseif key == TerminalConstants.KEYS.DOWN then
					if self.scrollManager and not self.showAsciiArt then
						self.scrollManager:setAutoScroll(false)
						self:scrollDown(self.lineHeight)
						return true
					end
				end
				return false
			end,
		},
		mainMenu = {
			enter = function(self)
				self:createMainMenuButtons()
			end,
			update = function(self)
				for _, module in pairs(self.activeModules) do
					if module.update then
						module:update()
					end
				end
			end,
			render = function(self)
				self:renderCRTScreen()
				self:renderTitle("KNOXNET EMERGENCY TERMINAL SYSTEM")
				self:renderButtonGrid()
				self:renderFooter("ARROW KEYS - NAVIGATE | SPACE - SELECT | BACKSPACE - EXIT | UP/DOWN - SCROLL")
				self:renderPowerButton()
			end,
			onKeyPress = function(self, key)
				self:playRandomKeySound()

				local buttons = self.buttons
				local cols = self:getButtonGridCols()
				local rows = math.ceil(#buttons / cols)
				local currentRow = math.ceil(self.selectedButton / cols)
				local currentCol = (self.selectedButton - 1) % cols + 1

				if key == TerminalConstants.KEYS.UP then
					if currentRow == 1 then
						if self.scrollManager then
							self.scrollManager:setAutoScroll(false)
							self:scrollUp(self.lineHeight)
							return true
						end
					else
						local newRow = math.max(1, currentRow - 1)
						self.selectedButton = (newRow - 1) * cols + currentCol
						if self.selectedButton > #buttons then
							self.selectedButton = self.selectedButton - cols
						end
						if self.selectedButton < 1 then
							self.selectedButton = 1
						end
						return true
					end
				elseif key == TerminalConstants.KEYS.DOWN then
					if currentRow == rows then
						if self.scrollManager then
							self.scrollManager:setAutoScroll(false)
							self:scrollDown(self.lineHeight)
							return true
						end
					else
						local newRow = math.min(rows, currentRow + 1)
						self.selectedButton = (newRow - 1) * cols + currentCol
						if self.selectedButton > #buttons then
							self.selectedButton = #buttons
						end
						return true
					end
				elseif key == TerminalConstants.KEYS.LEFT then
					local newCol = math.max(1, currentCol - 1)
					self.selectedButton = (currentRow - 1) * cols + newCol
					return true
				elseif key == TerminalConstants.KEYS.RIGHT then
					local newCol = math.min(cols, currentCol + 1)
					self.selectedButton = (currentRow - 1) * cols + newCol
					if self.selectedButton > #buttons then
						self.selectedButton = self.selectedButton - (cols - currentCol + 1)
					end
					return true
				elseif key == TerminalConstants.KEYS.CONFIRM then
					self:activateSelectedButton()
					return true
				elseif key == TerminalConstants.KEYS.CLOSE then
					self:close()
					return true
				end
				return false
			end,
		},
		module = {
			enter = function(self, moduleName)
				self.currentModule = moduleName
				local module = self.activeModules[moduleName]
				if module and module.onActivate then
					module:onActivate()
				end
			end,
			update = function(self)
				local module = self.activeModules[self.currentModule]
				if module and module.update then
					module:update()
				end
			end,
			render = function(self)
				self:renderCRTScreen()

				local module = self.activeModules[self.currentModule]
				if module and module.render then
					module:render()
				else
					self:renderTitle(self.currentModule or "UNKNOWN MODULE")
					self:renderText("MODULE DATA UNAVAILABLE")
					self:renderFooter("BACKSPACE - BACK TO MAIN MENU | UP/DOWN - SCROLL")
				end
				self:renderPowerButton()
			end,
			onKeyPress = function(self, key)
				local module = self.activeModules[self.currentModule]
				if module and module.onKeyPress then
					if module:onKeyPress(key) then
						return true
					end
				end

				if key == TerminalConstants.KEYS.UP then
					if self.scrollManager then
						self.scrollManager:setAutoScroll(false)
						self:scrollUp(self.lineHeight)
						self:playRandomKeySound()
						return true
					end
				elseif key == TerminalConstants.KEYS.DOWN then
					if self.scrollManager then
						self.scrollManager:setAutoScroll(false)
						self:scrollDown(self.lineHeight)
						self:playRandomKeySound()
						return true
					end
				elseif key == TerminalConstants.KEYS.CLOSE then
					self:changeState("mainMenu")
					return true
				end
				return false
			end,
			onMouseDown = function(self, x, y)
				local module = self.activeModules[self.currentModule]
				if module and module.onMouseDown then
					return module:onMouseDown(x, y)
				end
				return false
			end,
			onMouseWheel = function(self, del)
				local module = self.activeModules[self.currentModule]
				if module and module.onMouseWheel then
					if module:onMouseWheel(del) then
						return true
					end
				end

				return false
			end,
		},
		settings = {
			enter = function(self)
				self:createSettingsButtons()
			end,
			render = function(self)
				self:renderCRTScreen()
				self:renderTitle("TERMINAL CONFIGURATION")
				self:renderButtonGrid()
				self:renderFooter("ARROW KEYS - NAVIGATE | SPACE - SELECT | BACKSPACE - BACK | UP/DOWN - SCROLL")
				self:renderPowerButton()
			end,
			onKeyPress = function(self, key)
				self:playRandomKeySound()

				local buttons = self.buttons
				local cols = self:getButtonGridCols()
				local rows = math.ceil(#buttons / cols)
				local currentRow = math.ceil(self.selectedButton / cols)
				local currentCol = (self.selectedButton - 1) % cols + 1

				if key == TerminalConstants.KEYS.CLOSE then
					self:changeState("mainMenu")
					return true
				elseif key == TerminalConstants.KEYS.UP then
					if currentRow == 1 then
						if self.scrollManager then
							self.scrollManager:setAutoScroll(false)
							self:scrollUp(self.lineHeight)
							return true
						end
					else
						local newRow = math.max(1, currentRow - 1)
						self.selectedButton = (newRow - 1) * cols + currentCol
						if self.selectedButton > #buttons then
							self.selectedButton = self.selectedButton - cols
						end
						if self.selectedButton < 1 then
							self.selectedButton = 1
						end
						return true
					end
				elseif key == TerminalConstants.KEYS.DOWN then
					if currentRow == rows then
						if self.scrollManager then
							self.scrollManager:setAutoScroll(false)
							self:scrollDown(self.lineHeight)
							return true
						end
					else
						local newRow = math.min(rows, currentRow + 1)
						self.selectedButton = (newRow - 1) * cols + currentCol
						if self.selectedButton > #buttons then
							self.selectedButton = #buttons
						end
						return true
					end
				elseif key == TerminalConstants.KEYS.LEFT then
					local newCol = math.max(1, currentCol - 1)
					self.selectedButton = (currentRow - 1) * cols + newCol
					return true
				elseif key == TerminalConstants.KEYS.RIGHT then
					local newCol = math.min(cols, currentCol + 1)
					self.selectedButton = (currentRow - 1) * cols + newCol
					if self.selectedButton > #buttons then
						self.selectedButton = self.selectedButton - (cols - currentCol + 1)
					end
					return true
				elseif key == TerminalConstants.KEYS.CONFIRM then
					self:activateSelectedButton()
					return true
				end
				return false
			end,
		},
	}

	self.currentState = nil
end

---Resets the footer scroll position
function KnoxNet_Terminal:resetFooterScroll()
	self.footerScrollOffset = 0
	self.lastFooterScrollUpdate = 0
	self.footerScrollState = "scrolling"
	self.footerScrollPauseStart = 0
end

function KnoxNet_Terminal:renderPowerOffScreen()
	local texScale = math.min(self.width / self.origTexWidth, self.height / self.origTexHeight)
	local texWidth = self.origTexWidth * texScale
	local texHeight = self.origTexHeight * texScale
	local texX = (self.width - texWidth) / 2
	local texY = (self.height - texHeight) / 2

	self:drawTextureScaled(
		self.crtScreenTexture,
		self.displayX,
		self.displayY,
		self.displayWidth,
		self.displayHeight,
		0.75,
		0,
		0,
		0
	)

	self:drawTextureScaled(self.crtMonitorTexture, texX, texY, texWidth, texHeight, 1, 1, 1, 1)
	self:renderPowerButton()
end

function KnoxNet_Terminal:playRandomKeySound()
	local sounds = {
		"sfx_knoxnet_key_1",
		"sfx_knoxnet_key_2",
		"sfx_knoxnet_key_3",
		"sfx_knoxnet_key_4",
	}
	local randomSound = sounds[ZombRand(1, #sounds + 1)]
	TerminalSounds.playUISound(randomSound)
end

function KnoxNet_Terminal:renderPowerButton()
	local buttonRatioX = 759 / self.origTexWidth
	local buttonRatioY = 576 / self.origTexHeight
	local buttonRatioWidth = 27 / self.origTexWidth
	local buttonRatioHeight = 27 / self.origTexHeight

	local sizeMultiplier = 1.0

	local texScale = math.min(self.width / self.origTexWidth, self.height / self.origTexHeight)
	local texWidth = self.origTexWidth * texScale
	local texHeight = self.origTexHeight * texScale
	local texX = (self.width - texWidth) / 2
	local texY = (self.height - texHeight) / 2

	local originalCenterX = texX + buttonRatioX * texWidth + (buttonRatioWidth * texWidth / 2)
	local originalCenterY = texY + buttonRatioY * texHeight + (buttonRatioHeight * texHeight / 2)

	local powerButtonWidth = buttonRatioWidth * texWidth * sizeMultiplier
	local powerButtonHeight = buttonRatioHeight * texHeight * sizeMultiplier

	local powerButtonX = originalCenterX - (powerButtonWidth / 2)
	local powerButtonY = originalCenterY - (powerButtonHeight / 2)

	self.powerButtonX = powerButtonX
	self.powerButtonY = powerButtonY
	self.powerButtonWidth = powerButtonWidth
	self.powerButtonHeight = powerButtonHeight

	local isPowered = self.currentState ~= "powerOff"

	local indicatorSize = math.min(powerButtonWidth, powerButtonHeight) * 0.8
	local indicatorX = powerButtonX + (powerButtonWidth - indicatorSize) / 2
	local indicatorY = powerButtonY + (powerButtonHeight - indicatorSize) / 2

	local buttonColor
	if self.rainbowMode then
		local hue = self.rainbowHue
		local r, g, b = ColorUtils.hslToRgb(hue, 1.0, isPowered and 0.7 or 0.3)
		buttonColor = { r = r, g = g, b = b, a = 0.8 }
	else
		if isPowered then
			buttonColor = TerminalConstants.COLORS.POWER_BUTTON.ON
		else
			buttonColor = TerminalConstants.COLORS.POWER_BUTTON.OFF
		end
	end

	self:drawRect(
		indicatorX,
		indicatorY,
		indicatorSize,
		indicatorSize,
		buttonColor.a,
		buttonColor.r,
		buttonColor.g,
		buttonColor.b
	)

	local highlightSize = indicatorSize * 0.5
	local highlightX = indicatorX + (indicatorSize - highlightSize) / 2
	local highlightY = indicatorY + (indicatorSize - highlightSize) / 2

	self:drawRect(
		highlightX,
		highlightY,
		highlightSize,
		highlightSize,
		1.0,
		buttonColor.r - 0.05,
		buttonColor.g - 0.05,
		buttonColor.b - 0.05
	)

	self:drawRectBorder(indicatorX, indicatorY, indicatorSize, indicatorSize, 0.5, 0.2, 0.2, 0.2)

	local glowSize = indicatorSize * 1.6
	local glowX = indicatorX - (glowSize - indicatorSize) / 2
	local glowY = indicatorY - (glowSize - indicatorSize) / 2

	self:drawRect(glowX, glowY, glowSize, glowSize, 0.2, buttonColor.r * 0.6, buttonColor.g * 0.6, buttonColor.b * 0.6)
end

---Changes the terminal's current state
---@param stateName string The name of the state to change to
---@param ... any Additional arguments to pass to the state's enter function
function KnoxNet_Terminal:changeState(stateName, ...)
	if self.states[stateName] then
		self.currentState = stateName
		self.buttons = {}
		self.selectedButton = 1

		self:resetFooterScroll()

		if self.states[stateName].enter then
			self.states[stateName].enter(self, ...)
		end
	end
end

function KnoxNet_Terminal:initModules()
	self.activeModules = {}
	for name, moduleData in pairs(KnoxNet_Terminal.modules) do
		self:loadModule(name, moduleData)
	end
	self:initDefaultModules()
end

function KnoxNet_Terminal:initDefaultModules()
	self:loadModule("Help", {
		moduleSounds = {},

		onActivate = function(self) end,

		onDeactivate = function(self)
			for _, soundId in pairs(self.moduleSounds) do
				TerminalSounds.stopSound(soundId)
			end
			self.moduleSounds = {}
		end,

		onClose = function(self)
			self:onDeactivate()
		end,

		render = function(self)
			self.terminal:renderTitle("SYSTEM HELP MODULE")
			self.terminal:renderText([[
KNOXNET TERMINAL HELP GUIDE
 
NAVIGATION:
    Arrow Keys - Navigate menu options
    Space      - Select current option
    Backspace  - Return or exit
 
SCROLLING:
    Mouse Wheel - Scroll content
    Up/Down     - Keyboard scrolling (Arrow Keys)
 
AVAILABLE MODULES:
    Lore Database  - Historical records
    Directives     - Community missions
    Help           - This guide
 
ADMIN FEATURES:
    Create and manage directives
    Expand lore database
 
Contact local KnoxNet administrator for support
			            ]])

			self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU | UP/DOWN - SCROLL")
		end,
	})
end

---Loads a module into the terminal
---@param name string The module name
---@param moduleData table The module data
function KnoxNet_Terminal:loadModule(name, moduleData)
	if not moduleData then
		return
	end

	moduleData.terminal = self
	self.activeModules[name] = moduleData
end

function KnoxNet_Terminal:createMainMenuButtons()
	self.buttons = {}

	for name, _ in pairs(self.activeModules) do
		table.insert(self.buttons, {
			text = name,
			action = function()
				self:changeState("module", name)
			end,
		})
	end

	local hasAccess = false

	if not isServer() and not isClient() then
		hasAccess = true
	elseif isClient() then
		hasAccess = isAdmin()
	end

	if getDebug() then
		hasAccess = true
	end

	if hasAccess then
		table.insert(self.buttons, {
			text = "Admin Control",
			action = function()
				local KnoxNet_ControlPanel = require("KnoxNet/core/ControlPanel")
				KnoxNet_ControlPanel.openPanel()
			end,
		})
	end

	table.insert(self.buttons, {
		text = "Configuration",
		action = function()
			self:changeState("settings")
		end,
	})

	table.insert(self.buttons, {
		text = "Power Down",
		action = function()
			self:close()
		end,
	})
end

function KnoxNet_Terminal:createSettingsButtons()
	self.buttons = {}

	table.insert(self.buttons, {
		text = "Text Speed: " .. (self.charDelay == 5 and "Fast" or (self.charDelay == 15 and "Normal" or "Slow")),
		action = function()
			if self.charDelay == 5 then
				self.charDelay = 15 -- normal
			elseif self.charDelay == 15 then
				self.charDelay = 30 -- slow
			else
				self.charDelay = 5 -- fast
			end
			self:createSettingsButtons()
		end,
	})

	-- CRT effects
	table.insert(self.buttons, {
		text = "CRT Effects: " .. (self.crtEffectsEnabled and "Enabled" or "Disabled"),
		action = function()
			self.crtEffectsEnabled = not self.crtEffectsEnabled
			self:createSettingsButtons()
		end,
	})

	-- CRT flicker intensity
	self.crtFlickerLevel = self.crtFlickerLevel or 1
	table.insert(self.buttons, {
		text = "CRT Flicker: "
			.. (
				self.crtFlickerLevel == 0 and "None"
				or self.crtFlickerLevel == 1 and "Subtle"
				or self.crtFlickerLevel == 2 and "Moderate"
				or "Strong"
			),
		action = function()
			self.crtFlickerLevel = (self.crtFlickerLevel + 1) % 4
			TerminalConstants.CRT.FLICKER_INTENSITY = self.crtFlickerLevel * 0.05
			self:createSettingsButtons()
		end,
	})

	table.insert(self.buttons, {
		text = "Brightness: " .. math.floor(self.screenBrightness * 100) .. "%",
		action = function()
			self.screenBrightness = self.screenBrightness == 1 and 0.5
				or self.screenBrightness == 0.5 and 0.7
				or self.screenBrightness == 0.7 and 0.9
				or 1
			self.textBrightnessMultiplier = self.screenBrightness
			self:createSettingsButtons()
		end,
	})

	table.insert(self.buttons, {
		text = "Footer Scrolling: " .. (self.footerScrollEnabled and "Enabled" or "Disabled"),
		action = function()
			self.footerScrollEnabled = not self.footerScrollEnabled
			if not self.footerScrollEnabled then
				self.footerScrollOffset = 0
			end
			self:createSettingsButtons()
		end,
	})

	self.footerScrollSpeedLevel = self.footerScrollSpeedLevel or 2
	table.insert(self.buttons, {
		text = "Footer Speed: "
			.. (
				self.footerScrollSpeedLevel == 1 and "Slow"
				or self.footerScrollSpeedLevel == 2 and "Normal"
				or self.footerScrollSpeedLevel == 3 and "Fast"
				or "Very Fast"
			),
		action = function()
			self.footerScrollSpeedLevel = (self.footerScrollSpeedLevel % 4) + 1
			if self.footerScrollSpeedLevel == 1 then
				self.footerScrollSpeed = 0.6 -- Slow
			elseif self.footerScrollSpeedLevel == 2 then
				self.footerScrollSpeed = 1.2 -- Normal
			elseif self.footerScrollSpeedLevel == 3 then
				self.footerScrollSpeed = 2.0 -- Fast
			else
				self.footerScrollSpeed = 3.0 -- Very Fast
			end
			self:createSettingsButtons()
		end,
	})

	self.terminalColorScheme = self.terminalColorScheme or "green"
	local currentScheme = TerminalConstants.COLOR_SCHEMES[self.terminalColorScheme]
		or TerminalConstants.COLOR_SCHEMES["green"]
	table.insert(self.buttons, {
		text = "Theme: " .. currentScheme.name,
		action = function()
			local schemes = {}
			local currentIndex = 1
			local i = 1

			for key, _ in pairs(TerminalConstants.COLOR_SCHEMES) do
				table.insert(schemes, key)
				if key == self.terminalColorScheme then
					currentIndex = i
				end
				i = i + 1
			end

			table.sort(schemes, function(a, b)
				return a < b
			end)

			for j = 1, #schemes do
				local scheme = schemes[j]
				if scheme == self.terminalColorScheme then
					currentIndex = j
					break
				end
			end

			currentIndex = (currentIndex % #schemes) + 1
			self.terminalColorScheme = schemes[currentIndex]
			self:applyColorScheme()
			self:createSettingsButtons()
		end,
	})

	table.insert(self.buttons, {
		text = "Return to Main",
		action = function()
			self:changeState("mainMenu")
		end,
	})
end

function KnoxNet_Terminal:applyColorScheme()
	if not self.terminalColorScheme then
		self.terminalColorScheme = "green"
	end

	local currentBrightness = self.screenBrightness
	self.screenBrightness = currentBrightness
	self.textBrightnessMultiplier = currentBrightness

	if self.terminalColorScheme == "rainbow" then
		self.rainbowMode = true
		self.rainbowHue = 0
		self.lastRainbowUpdate = getTimeInMillis()
	else
		self.rainbowMode = false
	end

	local scheme = TerminalConstants.COLOR_SCHEMES[self.terminalColorScheme]
	if scheme then
		TerminalConstants.COLORS = TableUtils.deepCopy(scheme)
	end
end

---Sets the title text for the terminal
---@param text string The title text
function KnoxNet_Terminal:setTitle(text)
	self.titleText = text
end

function KnoxNet_Terminal:progressBootSequence()
	if self.bootInitComplete then
		return
	end

	if self.currentLine > #self.bootLines then
		self.bootInitComplete = true
		self.visibleText = self.visibleText .. "\n\nSYSTEM INITIALIZATION COMPLETE\nPRESS SPACE TO CONTINUE..."

		local lines = {}
		for line in self.visibleText:gmatch("[^\n]+") do
			table.insert(lines, line)
		end
		self.scrollManager:updateContentHeight(#lines * self.lineHeight)

		if self.scrollManager:getAutoScroll() then
			self.scrollManager:scrollTo(self.scrollManager.contentHeight - self.scrollManager.visibleHeight, true)
		end

		return
	end

	local line = self.bootLines[self.currentLine]
	self.visibleText = self.visibleText .. string.sub(line, self.currentChar, self.currentChar)

	self.currentChar = self.currentChar + 1

	if self.currentChar > #line then
		self.visibleText = self.visibleText .. "\n"
		self.currentLine = self.currentLine + 1
		self.currentChar = 1
		self.lastCharUpdate = getTimeInMillis() + self.lineDelay

		local lines = {}
		for line in self.visibleText:gmatch("[^\n]+") do
			table.insert(lines, line)
		end
		self.scrollManager:updateContentHeight(#lines * self.lineHeight)

		if self.scrollManager:getAutoScroll() then
			self.scrollManager:scrollTo(self.scrollManager.contentHeight - self.scrollManager.visibleHeight, true)
		end
	end
end

function KnoxNet_Terminal:renderCRTScreen()
	local currentTime = getTimeInMillis()
	local timeDiff = currentTime - self.lastRenderTime
	self.lastRenderTime = currentTime

	if self.crtEffectsEnabled then
		self.crtFlicker = self.crtFlicker + timeDiff * TerminalConstants.CRT.FLICKER_SPEED
		self.crtIntensity = 1.0 - (math.sin(self.crtFlicker) * TerminalConstants.CRT.FLICKER_INTENSITY)
	else
		self.crtIntensity = 1.0
	end

	local texScale = math.min(self.width / self.origTexWidth, self.height / self.origTexHeight)
	local texWidth = self.origTexWidth * texScale
	local texHeight = self.origTexHeight * texScale
	local texX = (self.width - texWidth) / 2
	local texY = (self.height - texHeight) / 2

	self:drawRect(self.displayX, self.displayY, self.displayWidth, self.displayHeight, 0.75, 0, 0, 0)

	self:drawTextureScaled(self.crtMonitorTexture, texX, texY, texWidth, texHeight, 1, 1, 1, 1)

	if self.crtEffectsEnabled then
		local lineSpacing = 2
		for y = self.displayY, self.displayY + self.displayHeight, lineSpacing do
			self:drawRect(self.displayX, y, self.displayWidth, 1, TerminalConstants.CRT.SCAN_LINE_INTENSITY, 0, 0, 0)
		end
	end
end

---Renders text
---@param text string The text to render
function KnoxNet_Terminal:renderText(text)
	if not text then
		return
	end

	local lines = {}
	for line in text:gmatch("[^\n]+") do
		table.insert(lines, line)
	end

	local totalHeight = #lines * self.lineHeight
	self.scrollManager:updateContentHeight(totalHeight)
	self.scrollManager:updateVisibleHeight(self.contentAreaHeight)

	local textX = self.displayX + self.textPaddingX
	local textY = self.contentAreaY + self.textPaddingY

	local scrollOffset = self.scrollManager:getScrollOffset()

	local startLine = math.max(1, math.floor(scrollOffset / self.lineHeight) + 1)
	local endLine = math.min(startLine + self.maxVisibleLines - 1, #lines)

	if self.currentState == "bootAndAscii" and self.showAsciiArt then
		local maxWidth = 0
		for i = 1, #lines do
			if lines[i] then
				local lineWidth = getTextManager():MeasureStringX(TerminalConstants.FONT.CODE, lines[i])
				maxWidth = math.max(maxWidth, lineWidth)
			end
		end

		local centeredX = self.displayX + ((self.displayWidth - maxWidth) / 2)
		totalHeight = #lines * self.lineHeight
		local startY = self.displayY + ((self.displayHeight - totalHeight) / 2)

		for i = 1, #lines do
			if lines[i] then
				local currentY = startY + (i - 1) * self.lineHeight

				if currentY >= self.displayY and currentY < self.displayY + self.displayHeight then
					self:drawText(
						lines[i],
						centeredX,
						currentY,
						TerminalConstants.COLORS.TEXT.NORMAL.r * self.crtIntensity,
						TerminalConstants.COLORS.TEXT.NORMAL.g * self.crtIntensity,
						TerminalConstants.COLORS.TEXT.NORMAL.b * self.crtIntensity,
						TerminalConstants.COLORS.TEXT.NORMAL.a,
						TerminalConstants.FONT.CODE
					)
				end
			end
		end
	else
		local currentY = textY - (scrollOffset % self.lineHeight)
		for i = startLine, endLine do
			if lines[i] then
				self:drawText(
					lines[i],
					textX,
					currentY,
					TerminalConstants.COLORS.TEXT.NORMAL.r * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.NORMAL.g * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.NORMAL.b * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.NORMAL.a,
					TerminalConstants.FONT.CODE
				)
				currentY = currentY + self.lineHeight
			end
		end
	end

	if self.scrollManager and not (self.currentState == "bootAndAscii" and self.showAsciiArt) then
		local scrollbarX = self.displayX + self.displayWidth - (TerminalConstants.LAYOUT.SCROLLBAR.WIDTH + 2) -- 10px width + 2px margin

		self.scrollManager:renderScrollbar(self, scrollbarX, self.contentAreaY, self.contentAreaHeight)
	end
end

---Renders the title bar with a title
---@param title string The title text
function KnoxNet_Terminal:renderTitle(title)
	local textX = self.displayX + self.textPaddingX
	local textY = self.titleAreaY
		+ (self.titleAreaHeight - getTextManager():MeasureStringY(TerminalConstants.FONT.CODE, title)) / 2

	self:drawRect(
		self.displayX,
		self.titleAreaY,
		self.displayWidth,
		self.titleAreaHeight,
		TerminalConstants.COLORS.HEADER.BACKGROUND.a,
		TerminalConstants.COLORS.HEADER.BACKGROUND.r,
		TerminalConstants.COLORS.HEADER.BACKGROUND.g,
		TerminalConstants.COLORS.HEADER.BACKGROUND.b
	)

	self:drawText(
		title,
		textX,
		textY,
		TerminalConstants.COLORS.TEXT.NORMAL.r * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.NORMAL.g * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.NORMAL.b * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.NORMAL.a,
		TerminalConstants.FONT.CODE
	)

	self:drawRect(
		self.displayX,
		self.titleAreaY + self.titleAreaHeight - 1,
		self.displayWidth,
		1,
		TerminalConstants.COLORS.HEADER.BORDER.a,
		TerminalConstants.COLORS.HEADER.BORDER.r * self.crtIntensity,
		TerminalConstants.COLORS.HEADER.BORDER.g * self.crtIntensity,
		TerminalConstants.COLORS.HEADER.BORDER.b * self.crtIntensity
	)

	local closeButtonSize = 20
	local closeButtonX = self.displayX + self.displayWidth - closeButtonSize - 5
	local closeButtonY = self.titleAreaY + (self.titleAreaHeight - closeButtonSize) / 2

	self:drawRect(
		closeButtonX,
		closeButtonY,
		closeButtonSize,
		closeButtonSize,
		TerminalConstants.COLORS.BUTTON.CLOSE.a,
		TerminalConstants.COLORS.BUTTON.CLOSE.r,
		TerminalConstants.COLORS.BUTTON.CLOSE.g,
		TerminalConstants.COLORS.BUTTON.CLOSE.b
	)
	self:drawRectBorder(
		closeButtonX,
		closeButtonY,
		closeButtonSize,
		closeButtonSize,
		TerminalConstants.COLORS.BUTTON.BORDER.a,
		TerminalConstants.COLORS.BUTTON.BORDER.r * self.crtIntensity,
		TerminalConstants.COLORS.BUTTON.BORDER.g * self.crtIntensity,
		TerminalConstants.COLORS.BUTTON.BORDER.b * self.crtIntensity
	)

	local xChar = "X"
	textX = closeButtonX + (closeButtonSize - getTextManager():MeasureStringX(TerminalConstants.FONT.MEDIUM, xChar)) / 2
	textY = closeButtonY + (closeButtonSize - getTextManager():MeasureStringY(TerminalConstants.FONT.MEDIUM, xChar)) / 2

	self:drawText(
		xChar,
		textX,
		textY,
		TerminalConstants.COLORS.TEXT.ERROR.r * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.ERROR.g * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.ERROR.b * self.crtIntensity,
		TerminalConstants.COLORS.TEXT.ERROR.a,
		TerminalConstants.FONT.MEDIUM
	)
end

---Renders the footer bar with text
---@param text string The footer text
function KnoxNet_Terminal:renderFooter(text)
	if not text then
		return
	end

	local textX = self.displayX + self.textPaddingX
	local textY = self.footerAreaY
		+ (self.footerAreaHeight - getTextManager():MeasureStringY(TerminalConstants.FONT.CODE, text)) / 2

	self:drawRect(
		self.displayX,
		self.footerAreaY,
		self.displayWidth,
		self.footerAreaHeight,
		TerminalConstants.COLORS.FOOTER.BACKGROUND.a,
		TerminalConstants.COLORS.FOOTER.BACKGROUND.r,
		TerminalConstants.COLORS.FOOTER.BACKGROUND.g,
		TerminalConstants.COLORS.FOOTER.BACKGROUND.b
	)

	self:drawRect(
		self.displayX,
		self.footerAreaY,
		self.displayWidth,
		1,
		TerminalConstants.COLORS.FOOTER.BORDER.a,
		TerminalConstants.COLORS.FOOTER.BORDER.r * self.crtIntensity,
		TerminalConstants.COLORS.FOOTER.BORDER.g * self.crtIntensity,
		TerminalConstants.COLORS.FOOTER.BORDER.b * self.crtIntensity
	)

	local textWidth = getTextManager():MeasureStringX(TerminalConstants.FONT.CODE, text)
	local availableWidth = self.displayWidth - (self.textPaddingX * 2)

	if textWidth <= availableWidth then
		self:drawText(
			text,
			textX,
			textY,
			TerminalConstants.COLORS.TEXT.DIM.r * self.crtIntensity,
			TerminalConstants.COLORS.TEXT.DIM.g * self.crtIntensity,
			TerminalConstants.COLORS.TEXT.DIM.b * self.crtIntensity,
			TerminalConstants.COLORS.TEXT.DIM.a,
			TerminalConstants.FONT.CODE
		)
	else
		local maxScrollOffset = textWidth - availableWidth

		if self.footerScrollEnabled then
			local currentTime = getTimeInMillis()
			
			if self.footerScrollState == "scrolling" then
				if currentTime > self.lastFooterScrollUpdate + self.footerScrollDelay then
					self.footerScrollOffset = self.footerScrollOffset + self.footerScrollSpeed

					if self.footerScrollOffset >= maxScrollOffset then
						self.footerScrollState = "paused"
						self.footerScrollPauseStart = currentTime
					end

					self.lastFooterScrollUpdate = currentTime
				end
			elseif self.footerScrollState == "paused" then
				if currentTime > self.footerScrollPauseStart + self.footerScrollPauseTime then
					self.footerScrollState = "scrolling"
					self.footerScrollOffset = 0
					self.lastFooterScrollUpdate = currentTime
				end
			end
		end

		local visibleTextX = textX - self.footerScrollOffset
		
		local footerLeft = self.displayX + self.textPaddingX
		local footerRight = self.displayX + self.displayWidth - self.textPaddingX
		
		local textLeft = visibleTextX
		local textRight = visibleTextX + textWidth
		
		if textRight > footerLeft and textLeft < footerRight then
			local clipLeft = math.max(footerLeft, textLeft)
			local clipRight = math.min(footerRight, textRight)
			
			local visibleStartX = clipLeft - textLeft
			local visibleEndX = clipRight - textLeft
			
			local startPercent = visibleStartX / textWidth
			local endPercent = visibleEndX / textWidth
			
			local startChar = math.floor(startPercent * #text) + 1
			local endChar = math.floor(endPercent * #text)
			
			startChar = math.max(1, startChar)
			endChar = math.min(#text, endChar)
			
			local visibleText = string.sub(text, startChar, endChar)
			
			if #visibleText > 0 then
				local renderX = clipLeft
				
				self:drawText(
					visibleText,
					renderX,
					textY,
					TerminalConstants.COLORS.TEXT.DIM.r * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.DIM.g * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.DIM.b * self.crtIntensity,
					TerminalConstants.COLORS.TEXT.DIM.a,
					TerminalConstants.FONT.CODE
				)
			end
		end
	end
end

function KnoxNet_Terminal:getButtonGridCols()
	return 2
end

function KnoxNet_Terminal:renderButtonGrid()
	local columns = self:getButtonGridCols()

	local totalButtonWidth = self.displayWidth * 0.8
	local buttonWidth = (totalButtonWidth - TerminalConstants.LAYOUT.MAIN_MENU.BUTTONS_PADDING) / columns
	local buttonHeight = self.lineHeight * 1.5

	local startX = self.displayX + (self.displayWidth - totalButtonWidth) / 2
	local startY = self.contentAreaY + 30

	for i = 1, #self.buttons do
		local button = self.buttons[i]
		local col = (i - 1) % columns
		local row = math.floor((i - 1) / columns)

		local x = startX + col * (buttonWidth + TerminalConstants.LAYOUT.MAIN_MENU.BUTTONS_PADDING)
		local y = startY + row * (buttonHeight + TerminalConstants.LAYOUT.MAIN_MENU.BUTTONS_PADDING)

		local isSelected = (i == self.selectedButton)

		local bgColor = isSelected and TerminalConstants.COLORS.BUTTON.SELECTED or TerminalConstants.COLORS.BUTTON.COLOR
		local borderColor = TerminalConstants.COLORS.BUTTON.BORDER

		self:drawRect(x, y, buttonWidth, buttonHeight, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

		self:drawRectBorder(
			x,
			y,
			buttonWidth,
			buttonHeight,
			borderColor.a,
			borderColor.r * self.crtIntensity,
			borderColor.g * self.crtIntensity,
			borderColor.b * self.crtIntensity
		)

		local textWidth = getTextManager():MeasureStringX(TerminalConstants.FONT.CODE, button.text)
		local textX = x + (buttonWidth - textWidth) / 2
		local textY = y + (buttonHeight - getTextManager():MeasureStringY(TerminalConstants.FONT.CODE, button.text)) / 2

		local textColor = isSelected and TerminalConstants.COLORS.TEXT.DIM or TerminalConstants.COLORS.TEXT.NORMAL

		self:drawText(
			button.text,
			textX,
			textY,
			textColor.r * self.crtIntensity,
			textColor.g * self.crtIntensity,
			textColor.b * self.crtIntensity,
			textColor.a,
			TerminalConstants.FONT.CODE
		)
	end
end

function KnoxNet_Terminal:activateSelectedButton()
	if self.selectedButton <= #self.buttons then
		local button = self.buttons[self.selectedButton]
		if button and button.action then
			button.action()
		end
	end
end

---Handles mouse down events
---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@return boolean
function KnoxNet_Terminal:onMouseDown(x, y)
	ISPanel.onMouseDown(self, x, y)

	if self.powerButtonX and self.powerButtonY and self.powerButtonWidth and self.powerButtonHeight then
		if
			x >= self.powerButtonX
			and x <= self.powerButtonX + self.powerButtonWidth
			and y >= self.powerButtonY
			and y <= self.powerButtonY + self.powerButtonHeight
		then
			if self.currentState == "powerOff" then
				self:changeState("bootAndAscii")
			else
				self:changeState("powerOff")
			end
			return true
		end
	end

	if self.currentState ~= "powerOff" then
		local closeButtonSize = 20
		local closeButtonX = self.displayX + self.displayWidth - closeButtonSize - 5
		local closeButtonY = self.titleAreaY + (self.titleAreaHeight - closeButtonSize) / 2

		if
			x >= closeButtonX
			and x <= closeButtonX + closeButtonSize
			and y >= closeButtonY
			and y <= closeButtonY + closeButtonSize
		then
			self:drawRect(
				closeButtonX,
				closeButtonY,
				closeButtonSize,
				closeButtonSize,
				TerminalConstants.COLORS.BUTTON.SELECTED.a,
				TerminalConstants.COLORS.BUTTON.SELECTED.r,
				TerminalConstants.COLORS.BUTTON.SELECTED.g,
				TerminalConstants.COLORS.BUTTON.SELECTED.b
			)
			self:playRandomKeySound()
			self:close()
			return true
		end

		if
			x >= self.displayX
			and x <= self.displayX + self.displayWidth
			and y >= self.displayY
			and y <= self.displayY + self.displayHeight
		then
			if self.currentState == "mainMenu" or self.currentState == "settings" then
				local columns = self:getButtonGridCols()
				local totalButtonWidth = self.displayWidth * 0.8
				local buttonWidth = (totalButtonWidth - TerminalConstants.LAYOUT.MAIN_MENU.BUTTONS_PADDING) / columns
				local buttonHeight = self.lineHeight * 1.5

				local startX = self.displayX + (self.displayWidth - totalButtonWidth) / 2
				local startY = self.contentAreaY + 30

				for i = 1, #self.buttons do
					local col = (i - 1) % columns
					local row = math.floor((i - 1) / columns)

					local buttonX = startX + col * (buttonWidth + TerminalConstants.LAYOUT.MAIN_MENU.BUTTONS_PADDING)
					local buttonY = startY + row * (buttonHeight + 15)

					if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
						self.selectedButton = i
						self:activateSelectedButton()
						self:playRandomKeySound()
						return true
					end
				end
			end
		end

		if self.currentState == "module" then
			local module = self.activeModules[self.currentModule]
			if module and module.onMouseDown then
				if module:onMouseDown(x, y) then
					return true
				end
			end
		end
	end
	return false
end

---Handles mouse wheel events
---@param del number Scroll delta
---@return boolean
function KnoxNet_Terminal:onMouseWheel(del)
	if self.currentState == "module" then
		local stateHandler = self.states[self.currentState]
		if stateHandler and stateHandler.onMouseWheel then
			if stateHandler.onMouseWheel(self, del) then
				return true
			end
		end
	end

	if self.scrollManager then
		self.scrollManager:setAutoScroll(false)
		if del > 0 then
			self:scrollDown(self.lineHeight)
		else
			self:scrollUp(self.lineHeight)
		end
	end

	return true
end

function KnoxNet_Terminal:scrollUp(amount)
	if self.scrollManager then
		self.scrollManager:setAutoScroll(false)
		self.scrollManager:scrollUp(amount)
	end
end

function KnoxNet_Terminal:scrollDown(amount)
	if self.scrollManager then
		self.scrollManager:setAutoScroll(false)
		self.scrollManager:scrollDown(amount)
	end
end

---Handles key press events
---@param key number The key code
---@return boolean
function KnoxNet_Terminal:onKeyPress(key)
	if key == TerminalConstants.KEYS.CLOSE then
		if self.currentState == "mainMenu" then
			self:close()
			return true
		elseif self.currentState ~= "bootAndAscii" then
			self:changeState("mainMenu")
			return true
		end
	end

	if self.states[self.currentState] and self.states[self.currentState].onKeyPress then
		return self.states[self.currentState].onKeyPress(self, key)
	end

	return false
end

function KnoxNet_Terminal:render()
	ISPanel.render(self)

	if self.states[self.currentState] and self.states[self.currentState].render then
		self.states[self.currentState].render(self)
	end
end

function KnoxNet_Terminal:update()
	if self.rainbowMode then
		local currentTime = getTimeInMillis()
		local timeDelta = currentTime - (self.lastRainbowUpdate or currentTime)
		self.lastRainbowUpdate = currentTime

		self.rainbowHue = (self.rainbowHue + timeDelta * 0.0005) % 1.0

		local r, g, b = ColorUtils.hslToRgb(self.rainbowHue, 1.0, 0.7)
		local dimR, dimG, dimB = ColorUtils.hslToRgb(self.rainbowHue, 0.8, 0.5)

		TerminalConstants.COLORS.HEADER.BORDER = { r = r, g = g, b = b, a = 0.7 }
		TerminalConstants.COLORS.FOOTER.BORDER = { r = r, g = g, b = b, a = 0.7 }
		TerminalConstants.COLORS.DIVIDER = { r = r, g = g, b = b, a = 0.7 }

		TerminalConstants.COLORS.TEXT.NORMAL = { r = r, g = g, b = b, a = 1.0 }
		TerminalConstants.COLORS.TEXT.DIM = { r = dimR, g = dimG, b = dimB, a = 1.0 }
		TerminalConstants.COLORS.TEXT.HIGHLIGHT = { r = r, g = g, b = b, a = 1.0 }
		TerminalConstants.COLORS.TEXT.WARNING = { r = r, g = g, b = b, a = 1.0 }
		TerminalConstants.COLORS.TEXT.ERROR = { r = r, g = g, b = b, a = 1.0 }

		TerminalConstants.COLORS.BUTTON.SELECTED = { r = r, g = g, b = b, a = 0.5 }
		TerminalConstants.COLORS.BUTTON.BORDER = { r = r, g = g, b = b, a = 0.5 }
		TerminalConstants.COLORS.BUTTON.COLOR = { r = r, g = g, b = b, a = 0.2 }
		TerminalConstants.COLORS.BUTTON.HOVER = { r = r, g = g, b = b, a = 0.5 }

		TerminalConstants.COLORS.SCROLLBAR.HANDLE = { r = r, g = g, b = b, a = 0.4 }
		TerminalConstants.COLORS.SCROLLBAR.BORDER = { r = r, g = g, b = b, a = 0.5 }

		TerminalConstants.COLORS.TAB.SELECTED = { r = r, g = g, b = b, a = 0.9 }
		TerminalConstants.COLORS.TAB.BORDER = { r = r, g = g, b = b, a = 0.7 }
	end

	if self.states[self.currentState] and self.states[self.currentState].update then
		self.states[self.currentState].update(self)
	end

	local currentTime = getTimeInMillis()
	local timeDelta = currentTime - (self.lastUpdateTime or currentTime)
	self.lastUpdateTime = currentTime

	if self.scrollManager then
		self.scrollManager:update(timeDelta)
	end
end

---Creates a new terminal instance
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param playerObj IsoPlayer Player object
---@return KnoxNet_Terminal
function KnoxNet_Terminal:new(x, y, width, height, playerObj)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self

	TerminalSounds.reset()

	o.backgroundMusicId = nil

	o.crtMonitorTexture = getTexture("media/ui/KnoxNet/computer/ui_knoxnet_monitor.png")
	o.crtScreenTexture = getTexture("media/ui/KnoxNet/computer/ui_knoxnet_screen.png")

	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()

	o.origTexWidth = o.crtMonitorTexture:getWidthOrig()
	o.origTexHeight = o.crtMonitorTexture:getHeightOrig()
	local aspectRatio = o.origTexWidth / o.origTexHeight

	o.baseWidth = math.min(
		math.max(screenWidth * TerminalConstants.SCREEN_RATIO, TerminalConstants.MIN_WIDTH),
		TerminalConstants.MAX_WIDTH
	)
	o.baseHeight = o.baseWidth / aspectRatio

	if o.baseHeight > screenHeight then
		o.baseHeight = screenHeight * 0.9
		o.baseWidth = o.baseHeight * aspectRatio
	end

	o.width = o.baseWidth
	o.height = o.baseHeight

	o.playerObj = playerObj
	o.playerNum = playerObj and playerObj:getPlayerNum() or -1

	o.moveWithMouse = true

	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	o.anchorLeft = true
	o.anchorRight = true
	o.anchorTop = true
	o.anchorBottom = true
	o.resizable = false

	o.crtEffectsEnabled = true
	o.contentText = ""
	o.titleText = "KnoxNet Terminal"

	return o
end

---Opens the terminal panel for a specific player
---@param playerNum number The player number
function KnoxNet_Terminal.openPanel(playerNum)
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()

	local x = (screenWidth - TerminalConstants.MIN_WIDTH) / 2
	local y = (screenHeight - (TerminalConstants.MIN_WIDTH / TerminalConstants.ASPECT_RATIO)) / 2

	if KnoxNet_Terminal.instance == nil then
		local window = KnoxNet_Terminal:new(
			x,
			y,
			TerminalConstants.MIN_WIDTH,
			TerminalConstants.MIN_WIDTH / TerminalConstants.ASPECT_RATIO,
			getSpecificPlayer(playerNum)
		)
		window:initialise()
		window:addToUIManager()
		KnoxNet_Terminal.instance = window
	else
		KnoxNet_Terminal.instance:close()
	end
end

---Register the terminal in the world context menu
---@param playerNum number Player number
---@param context ISContextMenu Context menu
---@param worldobjects table World objects
---@param test boolean Test flag
local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
	if not playerNum then
		return
	end

	local hasAccess = false
	if not isServer() and not isClient() then
		hasAccess = true
	elseif isClient() then
		hasAccess = isAdmin()
	end

	if getDebug() then
		hasAccess = true
	end

	if hasAccess then
		context:addOptionOnTop("KnoxNet Terminal", worldobjects, function()
			KnoxNet_Terminal.openPanel(playerNum)
		end)
	end
end

Events.OnFillWorldObjectContextMenu.Remove(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

---Handles key press events globally
---@param key number Key code
local function onKeyPressed(key)
	if KnoxNet_Terminal.instance then
		KnoxNet_Terminal.instance:onKeyPress(key)
	end
end

Events.OnKeyPressed.Add(onKeyPressed)

return KnoxNet_Terminal
