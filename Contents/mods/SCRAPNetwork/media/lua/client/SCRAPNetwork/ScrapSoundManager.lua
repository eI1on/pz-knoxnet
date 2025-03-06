---@class ScrapSoundManager
---@field private initialized boolean Whether the manager has been initialized
---@field private soundEmitter FMODSoundEmitter The sound emitter instance
---@field private activeSounds table<number, string> Map of active sound IDs to their file paths
---@field private loopedSounds table<number, boolean> Map of sounds that should be looped
---@field private soundTimestamps table<number, number> Map of when sounds were last started/restarted
---@field private originalSoundVolume number The original sound volume from the sound manager
---@field private soundVolume number|nil The temporary sound volume value when overridden
---@field private soundVolumes table<number, number> Map of sound IDs to their custom volumes
local ScrapSoundManager = {
    initialized = false,
    soundEmitter = FMODSoundEmitter.new(),
    activeSounds = {},
    loopedSounds = {},
    soundTimestamps = {},
    soundVolumes = {},
    originalSoundVolume = getSoundManager():getSoundVolume(),
    soundVolume = nil,
};

---Initializes the sound manager
---@return boolean success Whether initialization was successful
function ScrapSoundManager.init()
    if ScrapSoundManager.initialized then return false; end

    Events.OnTick.Add(ScrapSoundManager.update);
    ScrapSoundManager.initialized = true;

    local applyOptions = MainOptions.apply;
    ---@diagnostic disable-next-line: duplicate-set-field
    function MainOptions:apply(closeAfter)
        applyOptions(self, closeAfter);
        ScrapSoundManager.syncVolume();
    end

    return true;
end

---Sync the emitter volume with the global sound settings
function ScrapSoundManager.syncVolume()
    local soundManager = getSoundManager();
    local currentVolume = soundManager:getSoundVolume();

    ScrapSoundManager.soundEmitter:setVolumeAll(currentVolume);
    ScrapSoundManager.originalSoundVolume = currentVolume;
end

---Update function called on each game tick
function ScrapSoundManager.update()
    ScrapSoundManager.soundEmitter:tick();

    local soundsToRemove = {};
    local hasActiveSounds = false;
    local currentTime = getTimestampMs();

    for soundId, filePath in pairs(ScrapSoundManager.activeSounds) do
        if not ScrapSoundManager.soundEmitter:isPlaying(soundId) then
            if ScrapSoundManager.loopedSounds[soundId] then
                if currentTime - (ScrapSoundManager.soundTimestamps[soundId] or 0) > 50 then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local newSoundId = ScrapSoundManager.soundEmitter:playSoundImpl(filePath, false, nil)

                    if newSoundId then
                        if ScrapSoundManager.soundVolumes[soundId] then
                            ScrapSoundManager.soundEmitter:setVolume(newSoundId, ScrapSoundManager.soundVolumes[soundId])
                            ScrapSoundManager.soundVolumes[newSoundId] = ScrapSoundManager.soundVolumes[soundId]
                        end

                        table.insert(soundsToRemove, soundId)

                        ScrapSoundManager.activeSounds[newSoundId] = filePath
                        ScrapSoundManager.loopedSounds[newSoundId] = true
                        ScrapSoundManager.soundTimestamps[newSoundId] = currentTime
                        hasActiveSounds = true
                    end
                else
                    hasActiveSounds = true
                end
            else
                table.insert(soundsToRemove, soundId)
            end
        else
            hasActiveSounds = true
        end
    end

    for i = 1, #soundsToRemove do
        local soundId = soundsToRemove[i]
        ScrapSoundManager.activeSounds[soundId] = nil
        ScrapSoundManager.loopedSounds[soundId] = nil
        ScrapSoundManager.soundTimestamps[soundId] = nil
        ScrapSoundManager.soundVolumes[soundId] = nil
    end

    if not hasActiveSounds then
        ScrapSoundManager.restoreVolume()
    end
end

---Plays a sound once
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function ScrapSoundManager.playSound(file)
    if not file then return nil; end

    ---@diagnostic disable-next-line: param-type-mismatch
    local soundId = ScrapSoundManager.soundEmitter:playSoundImpl(file, false, nil);
    if soundId then
        ScrapSoundManager.activeSounds[soundId] = file
        ScrapSoundManager.soundTimestamps[soundId] = getTimestampMs()
    end
    return soundId;
end

---Plays a sound in a loop using custom loop implementation
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function ScrapSoundManager.playSoundLooped(file)
    if not file then return nil; end

    ---@diagnostic disable-next-line: param-type-mismatch
    local soundId = ScrapSoundManager.soundEmitter:playSoundImpl(file, false, nil);
    if soundId then
        ScrapSoundManager.activeSounds[soundId] = file
        ScrapSoundManager.loopedSounds[soundId] = true
        ScrapSoundManager.soundTimestamps[soundId] = getTimestampMs()
    end
    return soundId;
end

---Plays an ambient sound
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function ScrapSoundManager.playAmbientSound(file)
    if not file then return nil; end

    local soundId = ScrapSoundManager.soundEmitter:playAmbientSound(file);
    if soundId then
        ScrapSoundManager.activeSounds[soundId] = file
        ScrapSoundManager.soundTimestamps[soundId] = getTimestampMs()
    end
    return soundId;
end

---Plays an ambient sound in a loop using custom loop implementation
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function ScrapSoundManager.playAmbientLooped(file)
    if not file then return nil; end

    local soundId = ScrapSoundManager.soundEmitter:playAmbientSound(file);
    if soundId then
        ScrapSoundManager.activeSounds[soundId] = file
        ScrapSoundManager.loopedSounds[soundId] = true
        ScrapSoundManager.soundTimestamps[soundId] = getTimestampMs()
    end
    return soundId;
end

---Stops a specific sound by ID
---@param soundId number The sound ID to stop
---@return boolean success Whether the sound was stopped
function ScrapSoundManager.stopSound(soundId)
    if not soundId or not ScrapSoundManager.activeSounds[soundId] then return false; end

    ScrapSoundManager.soundEmitter:stopSoundLocal(soundId);
    ScrapSoundManager.activeSounds[soundId] = nil;
    ScrapSoundManager.loopedSounds[soundId] = nil;
    ScrapSoundManager.soundTimestamps[soundId] = nil;
    ScrapSoundManager.soundVolumes[soundId] = nil;
    return true;
end

---Stops a sound by its file path
---@param file string The sound file path
---@return boolean success Whether any sounds were stopped
function ScrapSoundManager.stopSoundByName(file)
    if not file then return false; end

    ScrapSoundManager.soundEmitter:stopSoundByName(file);

    local found = false
    for soundId, soundFile in pairs(ScrapSoundManager.activeSounds) do
        if soundFile == file then
            ScrapSoundManager.activeSounds[soundId] = nil;
            ScrapSoundManager.loopedSounds[soundId] = nil;
            ScrapSoundManager.soundTimestamps[soundId] = nil;
            ScrapSoundManager.soundVolumes[soundId] = nil;
            found = true
        end
    end

    return found;
end

---Stops all currently playing sounds
function ScrapSoundManager.stopAll()
    ScrapSoundManager.soundEmitter:stopAll();
    ScrapSoundManager.activeSounds = {};
    ScrapSoundManager.loopedSounds = {};
    ScrapSoundManager.soundTimestamps = {};
    ScrapSoundManager.soundVolumes = {};
end

---Sets the volume for a specific sound
---@param soundId number The sound ID
---@param volume number The volume (0.0 to 1.0)
---@return boolean success Whether the volume was set
function ScrapSoundManager.setSoundVolume(soundId, volume)
    if not soundId or not ScrapSoundManager.activeSounds[soundId] then return false; end

    if volume < 0 then volume = 0; end
    if volume > 1 then volume = 1; end

    ScrapSoundManager.soundEmitter:setVolume(soundId, volume);
    ScrapSoundManager.soundVolumes[soundId] = volume;
    return true;
end

---Sets the pitch for a specific sound
---@param soundId number The sound ID
---@param pitch number The pitch value
---@return boolean success Whether the pitch was set
function ScrapSoundManager.setPitch(soundId, pitch)
    if not soundId or not ScrapSoundManager.activeSounds[soundId] then return false; end

    ScrapSoundManager.soundEmitter:setPitch(soundId, pitch);
    return true;
end

---Sets the position for the sound emitter
---@param x number X coordinate
---@param y number Y coordinate
---@param z number Z coordinate
function ScrapSoundManager.setPosition(x, y, z)
    ScrapSoundManager.soundEmitter:setPos(x, y, z);
end

---Set the global sound volume
---@param value number The volume value (0.0 to 1.0)
function ScrapSoundManager.setVolume(value)
    if value < 0 then value = 0; end
    if value > 1 then value = 1; end

    local soundManager = getSoundManager();
    if not ScrapSoundManager.soundVolume then
        ScrapSoundManager.soundVolume = soundManager:getSoundVolume();
    end

    soundManager:setSoundVolume(value);
end

---Restore the original sound volume
function ScrapSoundManager.restoreVolume()
    local soundManager = getSoundManager();
    if ScrapSoundManager.soundVolume then
        soundManager:setSoundVolume(ScrapSoundManager.originalSoundVolume);
        ScrapSoundManager.soundVolume = nil;
    end
end

---Checks if a specific sound is playing
---@param soundId number The sound ID
---@return boolean isPlaying Whether the sound is playing
function ScrapSoundManager.isPlaying(soundId)
    if not soundId then return false; end
    return ScrapSoundManager.soundEmitter:isPlaying(soundId);
end

---Checks if a sound with the given name is playing
---@param file string The sound file path
---@return boolean isPlaying Whether any sound with this name is playing
function ScrapSoundManager.isPlayingByName(file)
    if not file then return false; end
    return ScrapSoundManager.soundEmitter:isPlaying(file);
end

---Gets all currently active sound IDs
---@return table<number, string> Map of sound IDs to file paths
function ScrapSoundManager.getActiveSounds()
    return ScrapSoundManager.activeSounds;
end

---Gets count of currently active sounds
---@return number count Number of active sounds
function ScrapSoundManager.getActiveSoundCount()
    local count = 0;
    for _ = 0, #ScrapSoundManager.activeSounds do
        count = count + 1;
    end
    return count;
end

Events.OnCreatePlayer.Add(ScrapSoundManager.init);

return ScrapSoundManager;
