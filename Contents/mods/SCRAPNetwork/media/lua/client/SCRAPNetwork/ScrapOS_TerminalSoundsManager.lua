local ScrapSoundManager = require("SCRAPNetwork/ScrapSoundManager")

local TerminalSounds = {}
TerminalSounds = {
    activeSounds = {},

    reset = function()
        TerminalSounds.activeSounds = {}
    end,

    playUISound = function(soundName)
        getSoundManager():playUISound(soundName)
    end,

    playLoopedSound = function(soundName)
        for id, info in pairs(TerminalSounds.activeSounds) do
            if info.name == soundName then
                ScrapSoundManager.stopSound(id)
                TerminalSounds.activeSounds[id] = nil
            end
        end

        local soundId = ScrapSoundManager.playSoundLooped(soundName)
        if soundId then
            TerminalSounds.activeSounds[soundId] = { name = soundName, type = "looped" }
        end
        return soundId
    end,

    playSound = function(soundName)
        local soundId = ScrapSoundManager.playSound(soundName)
        if soundId then
            TerminalSounds.activeSounds[soundId] = { name = soundName, type = "single" }
        end
        return soundId
    end,

    stopSound = function(soundId)
        if soundId and TerminalSounds.activeSounds[soundId] then
            ScrapSoundManager.stopSound(soundId)
            TerminalSounds.activeSounds[soundId] = nil
            return true
        end
        return false
    end,

    stopAllSounds = function()
        for soundId, _ in pairs(TerminalSounds.activeSounds) do
            ScrapSoundManager.stopSound(soundId)
        end
        TerminalSounds.activeSounds = {}
    end
}

return TerminalSounds;