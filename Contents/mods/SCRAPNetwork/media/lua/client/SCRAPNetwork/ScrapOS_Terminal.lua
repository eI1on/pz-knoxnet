local Globals = require("Starlit/Globals")

local ScrapSoundManager = require("SCRAPNetwork/ScrapSoundManager")
local TerminalSounds = require("SCRAPNetwork/ScrapOS_TerminalSoundsManager")

local CONST = {
    SCREEN_RATIO = 0.4, -- use 40% of screen width
    MAX_WIDTH = 1200,
    MIN_WIDTH = 800,
    ASPECT_RATIO = 848 / 910, -- original texture aspect ratio

    PADDING = 10,
    SECTION_SPACING = 10,
    ITEM_SPACING = 5,
    TITLE_HEIGHT = 30,
    FOOTER_HEIGHT = 30,

    FONT = {
        SMALL = UIFont.Small,
        MEDIUM = UIFont.Medium,
        LARGE = UIFont.Large,
        CODE = UIFont.Code
    },

    COLORS = {
        BORDER = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
        BACKGROUND = { r = 0.1, g = 0.1, b = 0.1, a = 0.75 },

        TEXT = { r = 1, g = 1, b = 1, a = 1 },
        TEXT_DIM = { r = 0.4, g = 1, b = 0.4, a = 1 },

        SCROLLBAR_BG = { r = 0.2, g = 0.3, b = 0.3, a = 0.3 },
        SCROLLBAR = { r = 0.4, g = 1, b = 0.4, a = 0.4 },

        BUTTON_SELECTED = { r = 0, g = 0, b = 0, a = 0 },
        BUTTON_BORDER = { r = 0.2, g = 0.2, b = 1.0, a = 0.5 },
        BUTTON_COLOR = { r = 0.2, g = 0.2, b = 1.0, a = 0.2 },
        BUTTON_HOVER = { r = 0.3, g = 0.3, b = 1.0, a = 0.5 },
    },

    KEYS = {
        CLOSE = Keyboard.KEY_BACK,
        CONFIRM = Keyboard.KEY_SPACE,
        UP = Keyboard.KEY_UP,
        DOWN = Keyboard.KEY_DOWN,
        LEFT = Keyboard.KEY_LEFT,
        RIGHT = Keyboard.KEY_RIGHT
    },

    CRT = {
        FLICKER_SPEED = 0.05,
        FLICKER_INTENSITY = 0.1,
        SCAN_LINE_INTENSITY = 0.05
    },

    -- keybinds to disable while terminal is open
    DISABLED_KEYS = {
        "Left", "Right", "Forward", "Backward",
        "Melee", "Aim", "Run", "Jump", "Crouch",
        "Sprint", "Sneak", "Toggle Inventory"
    }
}

local keybind_storage = {}

local storeKeyBinds = function(...)
    for _, key in pairs({ ... }) do
        keybind_storage[key] = getCore():getKey(key)
        getCore():addKeyBinding(key, 0)
    end
end

local restoreKeyBinds = function(...)
    for _, key in pairs({ ... }) do
        getCore():addKeyBinding(key, keybind_storage[key] or getCore():getKey(key))
    end
end

---@class SCRAP_Terminal : ISPanel
---@field instance SCRAP_Terminal
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
---@field scrollOffset number
---@field totalLines number
---@field autoScroll boolean
---@field crtFlicker number
---@field crtIntensity number
---@field lastRenderTime number
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
local SCRAP_Terminal = ISPanel:derive("SCRAP_Terminal")
SCRAP_Terminal.instance = nil

SCRAP_Terminal.modules = {}

---Registers a new module for the terminal
---@param moduleName string The name of the module
---@param moduleData table The module data containing functions and properties
function SCRAP_Terminal.registerModule(moduleName, moduleData)
    if not SCRAP_Terminal.modules[moduleName] then
        SCRAP_Terminal.modules[moduleName] = moduleData
    end
end

---Gets the current formatted date from the game
---@return string The formatted date string
local function getCurrentFormattedDate()
    local gameTime = getGameTime()
    if not gameTime then return "UNKNOWN DATE" end

    local year = gameTime:getYear()
    local month = gameTime:getMonth() + 1
    local day = gameTime:getDay() + 1

    return string.format("%02d/%02d/%d", month, day, year)
end


---Initializes the terminal
function SCRAP_Terminal:initialise()
    ISPanel.initialise(self)

    self:initCRTComponents()
    self:initStates()
    self:initModules()
    self:initKeybindings()

    storeKeyBinds(unpack(CONST.DISABLED_KEYS))

    self:changeState("powerOff")
end

---Closes the terminal
function SCRAP_Terminal:close()
    if self.backgroundMusicId then
        ScrapSoundManager.stopSound(self.backgroundMusicId)
        self.backgroundMusicId = nil
    end

    TerminalSounds.stopAllSounds()

    restoreKeyBinds(unpack(CONST.DISABLED_KEYS))

    self:setVisible(false)
    self:removeFromUIManager()
    SCRAP_Terminal.instance = nil

    for _, module in pairs(self.activeModules) do
        if module.onClose then module:onClose() end
    end
end

---Initializes CRT screen components
function SCRAP_Terminal:initCRTComponents()
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

    -- calculate line height based on scaled display height
    self.lineHeight = math.floor((self.displayHeight - CONST.TITLE_HEIGHT - CONST.FOOTER_HEIGHT) / 20) -- 20 lines max

    self.titleAreaY = self.displayY
    self.titleAreaHeight = CONST.TITLE_HEIGHT

    self.contentAreaY = self.titleAreaY + self.titleAreaHeight
    self.contentAreaHeight = self.displayHeight - self.titleAreaHeight - CONST.FOOTER_HEIGHT

    self.footerAreaY = self.contentAreaY + self.contentAreaHeight
    self.footerAreaHeight = CONST.FOOTER_HEIGHT

    self.maxVisibleLines = math.floor(self.contentAreaHeight / self.lineHeight)
    self.scrollOffset = 0
    self.totalLines = 0
    self.autoScroll = true

    -- CRT effects
    self.crtFlicker = 0
    self.crtIntensity = 1.0
    self.lastRenderTime = 0

    self.buttons = {}
    self.selectedButton = 1
    self.buttonHeight = self.lineHeight * 1.5
    self.buttonPadding = 5

    self:initBootSequence()
end

---Initializes the boot sequence text and properties
function SCRAP_Terminal:initBootSequence()
    self.bootLines = {
        "ELYON TECHNOLOGIES // KNOX COUNTY EMERGENCY NETWORK",
        "BIOS v2.3 INIT... MEMORY 64K OK... CRT OK [0x07E9]",
        "QUANTUM-7 TERMINAL ONLINE [1993-07-19 06:28]",
        " ",
        "DIAGNOSTICS:",
        "> POWER: OPERATIONAL [BACKUP GENERATOR]",
        "> UPLINK: LOCAL NODE ACTIVE [MESH NETWORK]",
        "> SECURITY: QUARANTINE PROTOCOL ACTIVE",
        " ",
        "MOUNTING S.C.R.A.P. OS v3.1...",
        "Survivor Cooperative Resilience & Action Protocol",
        " ",
        "KNOX COUNTY CONDITION: CRITICAL",
        "> INFECTION SPREAD: 91% POPULATION",
        "> SAFE ZONES: UNKNOWN",
        "> MILITARY PRESENCE: NONE DETECTED",
        " ",
        "ADVISORY: REMAIN INDOORS",
        "AVOID ALL INFECTED INDIVIDUALS",
        " ",
        "BOOTING S.C.R.A.P. INTERFACE...",
    }

    self.asciiArt = [[
             _____ _____  ______    ___   ______
            /  ___/  __ \ | ___ \  / _ \  | ___ \
            \ `--.| /  \/ | |_/ / / /_\ \ | |_/ /
             `--. \ |     |    /  |  _  | |  __/
            /\__/ / \__/\_| |\ \ _| | | |_| |_
            \____(_)____(_)_| \_(_)_| |_(_)_(_)
             _   _      _                      _
            | \ | |    | |                    | |
            |  \| | ___| |___      _____  _ __| | __
            | . ` |/ _ \ __\ \ /\ / / _ \| '__| |/ /
            | |\  |  __/ |_ \ V  V / (_) | |  |   <
            \_| \_/\___|\__| \_/\_/ \___/|_|  |_|\_\

        Survivor Cooperative Resilience & Action Protocol
    ]]

    self.currentLine = 1
    self.currentChar = 1
    self.lastCharUpdate = 0

    self.charDelay = 0
    self.lineDelay = 0

    self.bootInitComplete = false -- Flag for completing initial boot text
    self.bootComplete = false     -- Flag for completing the entire boot process
    self.showAsciiArt = false     -- Flag for showing ASCII art

    self.displayText = ""
    self.visibleText = ""
end

-- Initialize state system
function SCRAP_Terminal:initStates()
    self.states = {
        powerOff = {
            enter = function(self)
                TerminalSounds.stopAllSounds()
                TerminalSounds.playUISound("scrap_terminal_poweroff")

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
        boot = {
            enter = function(self)
                TerminalSounds.playUISound("scrap_terminal_poweron")
                self.backgroundMusicId = TerminalSounds.playLoopedSound("scrap_terminal_powered_hum")

                self:initBootSequence()
            end,
            update = function(self)
                local currentTime = getTimeInMillis()
                if currentTime > self.lastCharUpdate + self.charDelay then
                    for i = 1, 10 do -- process multiple chars per frame
                        self:progressBootSequence()
                        if self.bootInitComplete then break end
                    end
                    self.lastCharUpdate = currentTime
                end
            end,
            render = function(self)
                self:renderCRTScreen()
                self:renderText(self.visibleText)

                if self.bootInitComplete then
                    self:renderFooter("PRESS SPACE TO CONTINUE | BACKSPACE - EXIT")
                end
                self:renderPowerButton()
            end,
            onKeyPress = function(self, key)
                self:playRandomKeySound()

                if key == CONST.KEYS.CONFIRM and self.bootInitComplete then
                    self:changeState("asciiArt")
                    return true
                elseif key == CONST.KEYS.CLOSE then
                    self:close()
                    return true
                end
                return false
            end
        },
        asciiArt = {
            enter = function(self)
                self.visibleText = self.asciiArt
                self.bootComplete = true
            end,
            render = function(self)
                self:renderCRTScreen()
                self:renderText(self.visibleText)
                self:renderFooter("PRESS SPACE TO CONTINUE | BACKSPACE - EXIT")

                self:renderPowerButton()
            end,
            onKeyPress = function(self, key)
                self:playRandomKeySound()

                if key == CONST.KEYS.CONFIRM then
                    self:changeState("mainMenu")
                    return true
                elseif key == CONST.KEYS.CLOSE then
                    self:close()
                    return true
                end
                return false
            end
        },
        mainMenu = {
            enter = function(self)
                self:createMainMenuButtons()
            end,
            update = function(self)
                for _, module in pairs(self.activeModules) do
                    if module.update then module:update() end
                end
            end,
            render = function(self)
                self:renderCRTScreen()
                self:renderTitle("S.C.R.A.P. TERMINAL v3.1")
                self:renderButtons()
                self:renderFooter("SPACE - SELECT | ARROWS - NAVIGATE | BACKSPACE - EXIT")
                self:renderPowerButton()
            end,
            onKeyPress = function(self, key)
                self:playRandomKeySound()

                if key == CONST.KEYS.UP then
                    self.selectedButton = math.max(1, self.selectedButton - 1)
                    return true
                elseif key == CONST.KEYS.DOWN then
                    self.selectedButton = math.min(#self.buttons, self.selectedButton + 1)
                    return true
                elseif key == CONST.KEYS.CONFIRM then
                    self:activateSelectedButton()
                    return true
                elseif key == CONST.KEYS.CLOSE then
                    self:close()
                    return true
                end
                return false
            end
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
                    self:renderFooter("BACKSPACE - BACK TO MAIN MENU")
                end
                self:renderPowerButton()
            end,
            onKeyPress = function(self, key)
                if key == CONST.KEYS.CLOSE then
                    self:changeState("mainMenu")
                    return true
                end

                local module = self.activeModules[self.currentModule]
                if module and module.onKeyPress then
                    return module:onKeyPress(key)
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
                self:renderTitle("TERMINAL SETTINGS")
                self:renderButtons()
                self:renderFooter("SPACE - SELECT | ARROWS - NAVIGATE | BACKSPACE - BACK")
                self:renderPowerButton()
            end,
            onKeyPress = function(self, key)
                self:playRandomKeySound()
                if key == CONST.KEYS.CLOSE then
                    self:changeState("mainMenu")
                    return true
                elseif key == CONST.KEYS.UP then
                    self.selectedButton = math.max(1, self.selectedButton - 1)
                    return true
                elseif key == CONST.KEYS.DOWN then
                    self.selectedButton = math.min(#self.buttons, self.selectedButton + 1)
                    return true
                elseif key == CONST.KEYS.CONFIRM then
                    self:activateSelectedButton()
                    return true
                end
                return false
            end
        }
    }

    self.currentState = nil
end

---Renders the powered off screen
function SCRAP_Terminal:renderPowerOffScreen()
    local texScale = math.min(self.width / self.origTexWidth, self.height / self.origTexHeight)
    local texWidth = self.origTexWidth * texScale
    local texHeight = self.origTexHeight * texScale
    local texX = (self.width - texWidth) / 2
    local texY = (self.height - texHeight) / 2

    self:drawTextureScaled(self.crtScreenTexture, self.displayX, self.displayY, self.displayWidth, self.displayHeight,
        0.75, 0, 0, 0)

    self:drawTextureScaled(self.crtMonitorTexture, texX, texY, texWidth, texHeight, 1, 1, 1, 1)

    self:renderPowerButton()
end

---Renders the power button on the terminal
function SCRAP_Terminal:renderPowerButton()
    local buttonRatioX = 759 / self.origTexWidth
    local buttonRatioY = 576 / self.origTexHeight
    local buttonRatioWidth = 27 / self.origTexWidth
    local buttonRatioHeight = 27 / self.origTexHeight

    local sizeMultiplier = 1

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
    if isPowered then
        -- Warm amber glow for power on (vintage electronic look)
        buttonColor = { r = 0.9, g = 0.6, b = 0.1, a = 0.8 }
    else
        -- Dark red for power off (unlit indicator)
        buttonColor = { r = 0.9, g = 0.05, b = 0.05, a = 0.8 }
    end

    self:drawRect(indicatorX, indicatorY, indicatorSize, indicatorSize, buttonColor.a, buttonColor.r, buttonColor.g,
        buttonColor.b)

    local highlightSize = indicatorSize * 0.5
    local highlightX = indicatorX + (indicatorSize - highlightSize) / 2
    local highlightY = indicatorY + (indicatorSize - highlightSize) / 2

    self:drawRect(highlightX, highlightY, highlightSize, highlightSize, 1.0, buttonColor.r - 0.05, buttonColor.g - 0.05,
        buttonColor.b - 0.05)

    self:drawRectBorder(indicatorX, indicatorY, indicatorSize, indicatorSize, 0.5, 0.2, 0.2, 0.2)

    local glowSize = indicatorSize * 1.6
    local glowX = indicatorX - (glowSize - indicatorSize) / 2
    local glowY = indicatorY - (glowSize - indicatorSize) / 2

    self:drawRect(glowX, glowY, glowSize, glowSize, 0.2, buttonColor.r * 0.6, buttonColor.g * 0.6, buttonColor.b * 0.6)
end

---Plays a random keyboard sound effect
function SCRAP_Terminal:playRandomKeySound()
    local sounds = {
        "scrap_terminal_key_1",
        "scrap_terminal_key_2",
        "scrap_terminal_key_3",
        "scrap_terminal_key_4"
    }
    local randomSound = sounds[ZombRand(1, #sounds + 1)]
    TerminalSounds.playUISound(randomSound)
end

---Changes the terminal's current state
---@param stateName string The name of the state to change to
---@param ... any Additional arguments to pass to the state's enter function
function SCRAP_Terminal:changeState(stateName, ...)
    if self.states[stateName] then
        self.currentState = stateName
        self.scrollOffset = 0
        self.buttons = {}
        self.selectedButton = 1

        if self.states[stateName].enter then
            self.states[stateName].enter(self, ...)
        end
    end
end

---Initializes all terminal modules
function SCRAP_Terminal:initModules()
    self.activeModules = {}

    self:initDefaultModules()

    for name, moduleData in pairs(SCRAP_Terminal.modules) do
        self:loadModule(name, moduleData)
    end
end

---Initializes the default built-in modules
function SCRAP_Terminal:initDefaultModules()
    self:loadModule("Lore Database", {
        messages = {
            {
                title = "INCIDENT REPORT #458",
                content =
                "07/16/93 - First confirmed zombie sighting in Knox County.\nMultiple casualties reported at Louisville General Hospital.\nInitial containment protocols activated.\n\nWARNING: Infection appears to spread through bites.\nAvoid all contact with infected individuals.",
                date = "July 16, 1993"
            },
            {
                title = "EMERGENCY BROADCAST #27",
                content =
                "07/17/93 - ATTENTION ALL CITIZENS\n\nRemain in your homes. Lock all doors and windows.\nDo not attempt to reach evacuation centers at this time.\nMilitary checkpoints being established on all major roads.\n\nPower outages expected. Conserve food and water.\nStand by for further instructions.",
                date = "July 17, 1993"
            },
            {
                title = "LAST SERVER UPDATE",
                content =
                "07/19/93 - Network infrastructure failing. Most nodes offline.\nMain server contamination imminent.\n\nFalling back to autonomous operation.\nAll remaining personnel evacuate immediately.\n\nGod help us all.",
                date = "July 19, 1993"
            }
        },
        currentMessageIndex = 1,

        moduleSounds = {},

        onActivate = function(self)
            self.terminal:setTitle("LORE DATABASE")
            self:showCurrentMessage()
            -- Play activation sound if needed
            -- self.moduleSounds.activationSound = TerminalSounds.playSound("lore_database_open")
        end,

        onDeactivate = function(self)
            for _, soundId in pairs(self.moduleSounds) do
                TerminalSounds.stopSound(soundId)
            end
            self.moduleSounds = {}
        end,

        onClose = function(self)
            self:onDeactivate()
        end,

        showCurrentMessage = function(self)
            if #self.messages == 0 then return end

            local message = self.messages[self.currentMessageIndex]
            local text = message.title .. "\n\n" .. message.content .. "\n\n" .. message.date
            self.terminal:setContent(text)
        end,

        onKeyPress = function(self, key)
            if key == CONST.KEYS.LEFT then
                self.currentMessageIndex = math.max(1, self.currentMessageIndex - 1)
                self:showCurrentMessage()
                return true
            elseif key == CONST.KEYS.RIGHT then
                self.currentMessageIndex = math.min(#self.messages, self.currentMessageIndex + 1)
                self:showCurrentMessage()
                return true
            end
            return false
        end,

        render = function(self)
            self.terminal:renderTitle("LORE DATABASE")

            if #self.messages == 0 then
                self.terminal:renderText("NO RECORDS FOUND")
                return
            end

            local message = self.messages[self.currentMessageIndex]
            self.terminal:renderText(message.title .. "\n\n" .. message.content)

            local paginationText = string.format("< %d/%d >", self.currentMessageIndex, #self.messages)
            local textWidth = getTextManager():MeasureStringX(CONST.FONT.CODE, paginationText)
            local x = self.terminal.displayX + (self.terminal.displayWidth - textWidth) / 2
            local y = self.terminal.footerAreaY - self.terminal.lineHeight

            self.terminal:drawText(paginationText, x, y,
                CONST.COLORS.TEXT_DIM.r,
                CONST.COLORS.TEXT_DIM.g,
                CONST.COLORS.TEXT_DIM.b,
                CONST.COLORS.TEXT_DIM.a,
                CONST.FONT.CODE
            )

            self.terminal:renderFooter("← PREV | NEXT → | BACKSPACE - BACK")
        end,

        addMessage = function(self, title, content, date)
            table.insert(self.messages, {
                title = title,
                content = content,
                date = date or getCurrentFormattedDate()
            })
        end
    })

    self:loadModule("Admin Broadcast", {
        messages = {},
        currentMessageIndex = 1,
        moduleSounds = {},

        onActivate = function(self)
            self:loadMessages()
            self:showCurrentMessage()
            -- Play activation sound if needed
            -- self.moduleSounds.activationSound = TerminalSounds.playSound("admin_broadcast_open")
        end,

        onDeactivate = function(self)
            for _, soundId in pairs(self.moduleSounds) do
                TerminalSounds.stopSound(soundId)
            end
            self.moduleSounds = {}
        end,

        onClose = function(self)
            self:onDeactivate()
        end,

        loadMessages = function(self)
            if #self.messages == 0 then
                self.terminal:setContent("NO ADMIN BROADCASTS AVAILABLE")
            end
        end,

        showCurrentMessage = function(self)
            if #self.messages == 0 then return end

            local message = self.messages[self.currentMessageIndex]
            local text = message.title ..
                "\n\n" .. message.content .. "\n\nFrom: " .. message.sender .. " - " .. message.date
            self.terminal:setContent(text)
        end,

        onKeyPress = function(self, key)
            if key == CONST.KEYS.LEFT then
                self.currentMessageIndex = math.max(1, self.currentMessageIndex - 1)
                self:showCurrentMessage()
                return true
            elseif key == CONST.KEYS.RIGHT then
                self.currentMessageIndex = math.min(#self.messages, self.currentMessageIndex + 1)
                self:showCurrentMessage()
                return true
            end
            return false
        end,

        render = function(self)
            self.terminal:renderTitle("ADMIN BROADCASTS")

            if #self.messages == 0 then
                self.terminal:renderText("NO BROADCASTS AVAILABLE")
                return
            end

            local message = self.messages[self.currentMessageIndex]
            self.terminal:renderText(message.title ..
                "\n\n" .. message.content .. "\n\nFrom: " .. message.sender .. " - " .. message.date)

            local paginationText = string.format("< %d/%d >", self.currentMessageIndex, #self.messages)
            local textWidth = getTextManager():MeasureStringX(CONST.FONT.CODE, paginationText)
            local x = self.terminal.displayX + (self.terminal.displayWidth - textWidth) / 2
            local y = self.terminal.footerAreaY - self.terminal.lineHeight

            self.terminal:drawText(paginationText, x, y,
                CONST.COLORS.TEXT_DIM.r,
                CONST.COLORS.TEXT_DIM.g,
                CONST.COLORS.TEXT_DIM.b,
                CONST.COLORS.TEXT_DIM.a,
                CONST.FONT.CODE
            )

            self.terminal:renderFooter("← PREV | NEXT → | BACKSPACE - BACK")
        end,

        sendBroadcast = function(self, title, content, sender)
            if not isAdmin() and not Globals.isDebug then
                return false
            end

            table.insert(self.messages, {
                title = title,
                content = content,
                sender = sender or "SYSTEM",
                date = getCurrentFormattedDate()
            })

            return true
        end
    })

    self:loadModule("Help", {
        moduleSounds = {},

        onActivate = function(self)
            local helpText = [[
S.C.R.A.P. TERMINAL HELP GUIDE

NAVIGATION:
- Use UP/DOWN arrows to navigate menus
- SPACE to select options
- BACKSPACE to return to previous screen or exit

MODULES:
- Lore Database: Historical records of the Knox Event
- Admin Broadcast: Messages from server administrators
- Help: This guide

SCROLLING:
- Mouse wheel to scroll content
- Click on scrollbar to jump to position

ADMIN FEATURES:
- Administrators can send broadcast messages
- Lore can be expanded by server admins

For further assistance, contact your local SCRAP administrator.
            ]]
            self.terminal:setContent(helpText)
        end,

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
            self.terminal:renderTitle("HELP SYSTEM")
            self.terminal:renderText([[
S.C.R.A.P. TERMINAL HELP GUIDE

NAVIGATION:
- Use UP/DOWN arrows to navigate menus
- SPACE to select options
- BACKSPACE to return to previous screen or exit

MODULES:
- Lore Database: Historical records of the Knox Event
- Admin Broadcast: Messages from server administrators
- Help: This guide

SCROLLING:
- Mouse wheel to scroll content
- Click on scrollbar to jump to position

ADMIN FEATURES:
- Administrators can send broadcast messages
- Lore can be expanded by server admins

For further assistance, contact your local SCRAP administrator.
            ]])
            self.terminal:renderFooter("BACKSPACE - BACK TO MAIN MENU")
        end
    })
end

---Loads a module into the terminal
---@param name string The module name
---@param moduleData table The module data
function SCRAP_Terminal:loadModule(name, moduleData)
    if not moduleData then return end

    moduleData.terminal = self

    self.activeModules[name] = moduleData
end

---Initializes keybindings for the terminal
function SCRAP_Terminal:initKeybindings()
end

---Creates the main menu buttons
function SCRAP_Terminal:createMainMenuButtons()
    self.buttons = {}

    for name, _ in pairs(self.activeModules) do
        table.insert(self.buttons, {
            text = name,
            action = function()
                self:changeState("module", name)
            end
        })
    end

    table.insert(self.buttons, {
        text = "Settings",
        action = function()
            self:changeState("settings")
        end
    })

    table.insert(self.buttons, {
        text = "Exit Terminal",
        action = function()
            self:close()
        end
    })
end

---Creates the settings menu buttons
function SCRAP_Terminal:createSettingsButtons()
    self.buttons = {}

    table.insert(self.buttons, {
        text = "Text Speed: " .. (self.charDelay == 5 and "Fast" or (self.charDelay == 15 and "Normal" or "Slow")),
        action = function()
            if self.charDelay == 5 then
                self.charDelay = 15 -- Normal
            elseif self.charDelay == 15 then
                self.charDelay = 30 -- Slow
            else
                self.charDelay = 5  -- Fast
            end
            self:createSettingsButtons()
        end
    })

    -- CRT effect toggle
    table.insert(self.buttons, {
        text = "CRT Effects: " .. (self.crtEffectsEnabled and "Enabled" or "Disabled"),
        action = function()
            self.crtEffectsEnabled = not self.crtEffectsEnabled
            self:createSettingsButtons()
        end
    })

    table.insert(self.buttons, {
        text = "Back to Main Menu",
        action = function()
            self:changeState("mainMenu")
        end
    })
end

---Sets the title text for the terminal
---@param text string The title text
function SCRAP_Terminal:setTitle(text)
    self.titleText = text
end

---Sets the content text for the terminal
---@param text string The content text
function SCRAP_Terminal:setContent(text)
    self.contentText = text

    self.totalLines = 0
    for _ in text:gmatch("[^\n]+") do
        self.totalLines = self.totalLines + 1
    end

    if self.autoScroll then
        self.scrollOffset = math.max(0, self.totalLines - self.maxVisibleLines)
    end
end

---Progresses the boot sequence animation
function SCRAP_Terminal:progressBootSequence()
    if self.bootInitComplete then
        return
    end

    if self.currentLine > #self.bootLines then
        self.bootInitComplete = true
        self.visibleText = self.visibleText .. "\n\nS.C.R.A.P. NETWORK READY TO INITIALIZE"
        return
    end

    local line = self.bootLines[self.currentLine]
    self.visibleText = self.visibleText .. string.sub(line, self.currentChar, self.currentChar)

    self.currentChar = self.currentChar + 1

    if self.currentChar > #line then
        self.visibleText = self.visibleText .. "\n"
        self.currentLine = self.currentLine + 1
        self.totalLines = self.totalLines + 1
        self.currentChar = 1
        self.lastCharUpdate = getTimeInMillis() + self.lineDelay

        if self.autoScroll then
            self.scrollOffset = math.max(0, self.totalLines - self.maxVisibleLines)
        end
    end
end

---Renders the CRT screen with effects
function SCRAP_Terminal:renderCRTScreen()
    local currentTime = getTimeInMillis()
    local timeDiff = currentTime - self.lastRenderTime
    self.lastRenderTime = currentTime

    if self.crtEffectsEnabled then
        self.crtFlicker = self.crtFlicker + timeDiff * CONST.CRT.FLICKER_SPEED
        self.crtIntensity = 1.0 - (math.sin(self.crtFlicker) * CONST.CRT.FLICKER_INTENSITY)
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

    self:drawRectBorder(self.displayX, self.displayY, self.displayWidth, self.displayHeight, 0.2 * self.crtIntensity,
        0.4 * self.crtIntensity, 1 * self.crtIntensity, 1)

    if self.crtEffectsEnabled then
        local lineSpacing = 2
        for y = self.displayY, self.displayY + self.displayHeight, lineSpacing do
            self:drawRect(self.displayX, y, self.displayWidth, 1, CONST.CRT.SCAN_LINE_INTENSITY, 0, 0, 0)
        end
    end
end

---Renders text with scrolling support
---@param text string The text to render
function SCRAP_Terminal:renderText(text)
    if not text then return end

    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local textX = self.displayX + self.textPaddingX
    local textY = self.contentAreaY + self.textPaddingY

    local startLine = math.max(1, self.scrollOffset + 1)
    local endLine = math.min(startLine + self.maxVisibleLines - 1, #lines)

    local currentY = textY
    for i = startLine, endLine do
        self:drawText(lines[i], textX, currentY,
            CONST.COLORS.TEXT_DIM.r * self.crtIntensity,
            CONST.COLORS.TEXT_DIM.g * self.crtIntensity,
            CONST.COLORS.TEXT_DIM.b * self.crtIntensity,
            CONST.COLORS.TEXT_DIM.a,
            CONST.FONT.CODE
        )
        currentY = currentY + self.lineHeight
    end

    if #lines > self.maxVisibleLines then
        local scrollbarWidth = 10
        local scrollbarX = self.displayX + self.displayWidth - scrollbarWidth - 2
        local scrollbarFullHeight = self.contentAreaHeight
        local scrollbarHeight = scrollbarFullHeight * (self.maxVisibleLines / #lines)
        local scrollbarY = self.contentAreaY +
            (scrollbarFullHeight - scrollbarHeight) * (self.scrollOffset / (#lines - self.maxVisibleLines))

        self:drawRect(
            scrollbarX,
            self.contentAreaY,
            scrollbarWidth,
            scrollbarFullHeight,
            CONST.COLORS.SCROLLBAR_BG.a,
            CONST.COLORS.SCROLLBAR_BG.r,
            CONST.COLORS.SCROLLBAR_BG.g,
            CONST.COLORS.SCROLLBAR_BG.b
        )

        self:drawRect(
            scrollbarX,
            scrollbarY,
            scrollbarWidth,
            scrollbarHeight,
            CONST.COLORS.SCROLLBAR.a,
            CONST.COLORS.SCROLLBAR.r,
            CONST.COLORS.SCROLLBAR.g,
            CONST.COLORS.SCROLLBAR.b
        )
    end
end

---Renders the title bar with a title
---@param title string The title text
function SCRAP_Terminal:renderTitle(title)
    local textX = self.displayX + self.textPaddingX
    local textY = self.titleAreaY + (self.titleAreaHeight - getTextManager():MeasureStringY(CONST.FONT.CODE, title)) / 2

    self:drawRect(self.displayX, self.titleAreaY, self.displayWidth, self.titleAreaHeight, 0.5, 0, 0.2, 0.2)

    self:drawText(title, textX, textY,
        CONST.COLORS.TEXT.r * self.crtIntensity,
        CONST.COLORS.TEXT.g * self.crtIntensity,
        CONST.COLORS.TEXT.b * self.crtIntensity,
        CONST.COLORS.TEXT.a,
        CONST.FONT.CODE
    )

    self:drawRect(
        self.displayX,
        self.titleAreaY + self.titleAreaHeight - 1,
        self.displayWidth,
        1,
        0.5,
        CONST.COLORS.TEXT_DIM.r * self.crtIntensity,
        CONST.COLORS.TEXT_DIM.g * self.crtIntensity,
        CONST.COLORS.TEXT_DIM.b * self.crtIntensity
    )

    local closeButtonSize = 20
    local closeButtonX = self.displayX + self.displayWidth - closeButtonSize - 5
    local closeButtonY = self.titleAreaY + (self.titleAreaHeight - closeButtonSize) / 2

    self:drawRect(closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 0.2, 0.2, 0.2, 0.8)
    self:drawRectBorder(closeButtonX, closeButtonY, closeButtonSize, closeButtonSize,
        CONST.COLORS.BORDER.a,
        CONST.COLORS.BORDER.r * self.crtIntensity,
        CONST.COLORS.BORDER.g * self.crtIntensity,
        CONST.COLORS.BORDER.b * self.crtIntensity
    )

    local xChar = "X"
    local textX = closeButtonX + (closeButtonSize - getTextManager():MeasureStringX(CONST.FONT.MEDIUM, xChar)) / 2
    local textY = closeButtonY + (closeButtonSize - getTextManager():MeasureStringY(CONST.FONT.MEDIUM, xChar)) / 2

    self:drawText(xChar, textX, textY,
        CONST.COLORS.TEXT.r * self.crtIntensity,
        CONST.COLORS.TEXT.g * self.crtIntensity,
        CONST.COLORS.TEXT.b * self.crtIntensity,
        CONST.COLORS.TEXT.a,
        CONST.FONT.MEDIUM
    )
end

---Renders the footer bar with text
---@param text string The footer text
function SCRAP_Terminal:renderFooter(text)
    local textX = self.displayX + self.textPaddingX
    local textY = self.footerAreaY + (self.footerAreaHeight - getTextManager():MeasureStringY(CONST.FONT.CODE, text)) / 2

    self:drawRect(
        self.displayX,
        self.footerAreaY,
        self.displayWidth,
        self.footerAreaHeight,
        0.5, 0, 0.2, 0.2
    )

    self:drawRect(self.displayX, self.footerAreaY, self.displayWidth, 1, 0.5, CONST.COLORS.TEXT_DIM.r * self
        .crtIntensity, CONST.COLORS.TEXT_DIM.g * self.crtIntensity, CONST.COLORS.TEXT_DIM.b * self.crtIntensity)

    self:drawText(text, textX, textY,
        CONST.COLORS.TEXT_DIM.r * self.crtIntensity,
        CONST.COLORS.TEXT_DIM.g * self.crtIntensity,
        CONST.COLORS.TEXT_DIM.b * self.crtIntensity,
        CONST.COLORS.TEXT_DIM.a,
        CONST.FONT.CODE
    )
end

---Renders the menu buttons
function SCRAP_Terminal:renderButtons()
    local startX = self.displayX + self.displayWidth * 0.2
    local startY = self.displayY + self.lineHeight * 3
    local buttonWidth = self.displayWidth * 0.6

    for i, button in ipairs(self.buttons) do
        local y = startY + (i - 1) * (self.buttonHeight + self.buttonPadding)
        local isSelected = (i == self.selectedButton)

        local bgColor = isSelected and CONST.COLORS.BUTTON_SELECTED or CONST.COLORS.BUTTON_COLOR
        self:drawRect(startX, y, buttonWidth, self.buttonHeight, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

        self:drawRectBorder(startX, y, buttonWidth, self.buttonHeight,
            CONST.COLORS.BUTTON_BORDER.a,
            CONST.COLORS.BUTTON_BORDER.r * self.crtIntensity,
            CONST.COLORS.BUTTON_BORDER.g * self.crtIntensity,
            CONST.COLORS.BUTTON_BORDER.b * self.crtIntensity
        )

        local textWidth = getTextManager():MeasureStringX(CONST.FONT.CODE, button.text)
        local textX = startX + (buttonWidth - textWidth) / 2
        local textY = y + (self.buttonHeight - getTextManager():MeasureStringY(CONST.FONT.CODE, button.text)) / 2

        self:drawText(button.text, textX, textY,
            CONST.COLORS.TEXT.r * self.crtIntensity,
            CONST.COLORS.TEXT.g * self.crtIntensity,
            CONST.COLORS.TEXT.b * self.crtIntensity,
            CONST.COLORS.TEXT.a,
            CONST.FONT.CODE
        )
    end
end

---Activates the currently selected button
function SCRAP_Terminal:activateSelectedButton()
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
function SCRAP_Terminal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)

    if self.powerButtonX and self.powerButtonY and self.powerButtonWidth and self.powerButtonHeight then
        if x >= self.powerButtonX and x <= self.powerButtonX + self.powerButtonWidth and
            y >= self.powerButtonY and y <= self.powerButtonY + self.powerButtonHeight then
            if self.currentState == "powerOff" then
                self:changeState("boot")
            else
                self:changeState("powerOff")
            end
            return true
        end
    else
        local buttonRatioX = 759 / self.origTexWidth
        local buttonRatioY = 576 / self.origTexHeight
        local buttonRatioWidth = 27 / self.origTexWidth
        local buttonRatioHeight = 27 / self.origTexHeight

        local sizeMultiplier = 1

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

        if x >= powerButtonX and x <= powerButtonX + powerButtonWidth and
            y >= powerButtonY and y <= powerButtonY + powerButtonHeight then
            if self.currentState == "powerOff" then
                self:changeState("boot")
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

        if x >= closeButtonX and x <= closeButtonX + closeButtonSize and
            y >= closeButtonY and y <= closeButtonY + closeButtonSize then
            self:drawRect(closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 1, 0.2, 0.2, 0.5)
            self:playRandomKeySound()
            self:close()
            return true
        end

        if x >= self.displayX and x <= self.displayX + self.displayWidth and
            y >= self.displayY and y <= self.displayY + self.displayHeight then
            if x > self.displayX + self.displayWidth - 20 then
                local clickPos = (y - self.displayY) / self.displayHeight
                self.scrollOffset = math.floor(clickPos * (self.totalLines - self.maxVisibleLines))
                self.scrollOffset = math.max(0, math.min(self.totalLines - self.maxVisibleLines, self.scrollOffset))
                self.autoScroll = false
                self:playRandomKeySound()
                return true
            end

            if self.currentState == "mainMenu" or self.currentState == "settings" then
                local startX = self.displayX + self.displayWidth * 0.2
                local startY = self.displayY + self.lineHeight * 3
                local buttonWidth = self.displayWidth * 0.6

                for i, _ in ipairs(self.buttons) do
                    local buttonY = startY + (i - 1) * (self.buttonHeight + self.buttonPadding)

                    if x >= startX and x <= startX + buttonWidth and
                        y >= buttonY and y <= buttonY + self.buttonHeight then
                        self.selectedButton = i
                        self:activateSelectedButton()
                        self:playRandomKeySound()
                        return true
                    end
                end
            end
        end
    end
    return false
end

---Handles mouse wheel events
---@param del number Scroll delta
---@return boolean
function SCRAP_Terminal:onMouseWheel(del)
    -- If we're in a module state
    if self.currentState == "module" then
        local stateHandler = self.states[self.currentState]
        if stateHandler and stateHandler.onMouseWheel then
            if stateHandler.onMouseWheel(self, del) then
                return true
            end
        end
    end
    
    -- Default scrolling behavior
    self.autoScroll = false
    self.scrollOffset = math.max(0, math.min(self.totalLines - self.maxVisibleLines, self.scrollOffset - del))
    return true
end

---Handles key press events
---@param key number The key code
---@return boolean
function SCRAP_Terminal:onKeyPress(key)
    if key == CONST.KEYS.CLOSE then
        if self.currentState == "mainMenu" then
            self:close()
            return true
        elseif self.currentState ~= "boot" then
            self:changeState("mainMenu")
            return true
        end
    end

    if self.states[self.currentState] and self.states[self.currentState].onKeyPress then
        return self.states[self.currentState].onKeyPress(self, key)
    end

    return false
end

---Renders the terminal
function SCRAP_Terminal:render()
    ISPanel.render(self)

    if self.states[self.currentState] and self.states[self.currentState].render then
        self.states[self.currentState].render(self)
    end
end

---Updates the terminal state
function SCRAP_Terminal:update()
    if self.states[self.currentState] and self.states[self.currentState].update then
        self.states[self.currentState].update(self)
    end
end

---Creates a new terminal instance
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param playerObj IsoPlayer Player object
---@return SCRAP_Terminal
function SCRAP_Terminal:new(x, y, width, height, playerObj)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    TerminalSounds.reset()

    o.backgroundMusicId = nil

    o.crtMonitorTexture = getTexture("media/ui/Computer/SCRAP_CRT_Monitor_Panel.png")
    o.crtScreenTexture = getTexture("media/ui/Computer/SCRAP_CRT_Monitor_Screen.png")

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    o.origTexWidth = o.crtMonitorTexture:getWidthOrig()
    o.origTexHeight = o.crtMonitorTexture:getHeightOrig()
    local aspectRatio = o.origTexWidth / o.origTexHeight

    o.baseWidth = math.min(math.max(screenWidth * CONST.SCREEN_RATIO, CONST.MIN_WIDTH), CONST.MAX_WIDTH)
    o.baseHeight = o.baseWidth / aspectRatio

    if o.baseHeight > screenHeight * 0.8 then
        o.baseHeight = screenHeight * 0.8
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
    o.titleText = "S.C.R.A.P. TERMINAL"

    return o
end

---Opens the terminal panel for a specific player
---@param playerNum number The player number
function SCRAP_Terminal.openPanel(playerNum)
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local x = (screenWidth - CONST.MIN_WIDTH) / 2
    local y = (screenHeight - (CONST.MIN_WIDTH / CONST.ASPECT_RATIO)) / 2

    if SCRAP_Terminal.instance == nil then
        local window = SCRAP_Terminal:new(x, y, CONST.MIN_WIDTH, CONST.MIN_WIDTH / CONST.ASPECT_RATIO,
            getSpecificPlayer(playerNum))
        window:initialise()
        window:addToUIManager()
        SCRAP_Terminal.instance = window
    else
        SCRAP_Terminal.instance:close()
    end
end

---Register the terminal in the world context menu
---@param playerNum number Player number
---@param context ISContextMenu Context menu
---@param worldobjects table World objects
---@param test boolean Test flag
local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if not playerNum then return end

    local hasAccess = false
    if Globals.isSingleplayer then
        hasAccess = true
    elseif Globals.isClient then
        hasAccess = isAdmin()
    end

    if Globals.isDebug then hasAccess = true end

    if hasAccess then
        context:addOptionOnTop(
            "SCRAP_Terminal", worldobjects,
            function()
                SCRAP_Terminal.openPanel(playerNum)
            end
        )
    end
end

Events.OnFillWorldObjectContextMenu.Remove(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

---@class SCRAP_Terminal_API
SCRAP_Terminal.API = {}

---Registers a module with the terminal
---@param moduleName string Module name
---@param moduleData table Module data
function SCRAP_Terminal.API.registerModule(moduleName, moduleData)
    SCRAP_Terminal.registerModule(moduleName, moduleData)
end

---Adds a lore message to the Lore Database module
---@param title string Message title
---@param content string Message content
---@param date string|nil Optional date (defaults to current game date)
function SCRAP_Terminal.API.addLoreMessage(title, content, date)
    if SCRAP_Terminal.instance and SCRAP_Terminal.instance.activeModules["Lore Database"] then
        SCRAP_Terminal.instance.activeModules["Lore Database"]:addMessage(title, content, date)
    else
        if not SCRAP_Terminal._pendingLoreMessages then
            SCRAP_Terminal._pendingLoreMessages = {}
        end
        table.insert(SCRAP_Terminal._pendingLoreMessages, { title = title, content = content, date = date })
    end
end

---Sends an admin broadcast message
---@param title string Message title
---@param content string Message content
---@param sender string|nil Optional sender name (defaults to "SYSTEM")
---@return boolean Success
function SCRAP_Terminal.API.sendAdminBroadcast(title, content, sender)
    if not isAdmin() and not Globals.isDebug then return false end

    if SCRAP_Terminal.instance and SCRAP_Terminal.instance.activeModules["Admin Broadcast"] then
        return SCRAP_Terminal.instance.activeModules["Admin Broadcast"]:sendBroadcast(title, content, sender)
    else
        if not SCRAP_Terminal._pendingBroadcasts then
            SCRAP_Terminal._pendingBroadcasts = {}
        end
        table.insert(SCRAP_Terminal._pendingBroadcasts, { title = title, content = content, sender = sender })
        return true
    end
end

---Handles key press events globally
---@param key number Key code
local function onKeyPressed(key)
    if SCRAP_Terminal.instance then
        SCRAP_Terminal.instance:onKeyPress(key)
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

return SCRAP_Terminal
