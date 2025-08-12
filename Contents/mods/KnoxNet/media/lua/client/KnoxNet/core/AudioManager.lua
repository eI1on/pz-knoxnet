---@class AudioManager
---@field private initialized boolean Whether the manager has been initialized
---@field private soundEmitter FMODSoundEmitter The sound emitter instance
---@field private activeSounds table<number, string> Map of active sound IDs to their file paths
---@field private loopedSounds table<number, boolean> Map of sounds that should be looped
---@field private soundTimestamps table<number, number> Map of when sounds were last started/restarted
---@field private originalSoundVolume number The original sound volume from the sound manager
---@field private soundVolume number|nil The temporary sound volume value when overridden
---@field private soundVolumes table<number, number> Map of sound IDs to their custom volumes
local AudioManager = {
	initialized = false,
	soundEmitter = FMODSoundEmitter.new(),
	activeSounds = {},
	loopedSounds = {},
	soundTimestamps = {},
	soundVolumes = {},
	originalSoundVolume = getSoundManager():getSoundVolume(),
	soundVolume = nil,
}

---Initializes the sound manager
---@return boolean success Whether initialization was successful
function AudioManager.init()
	if AudioManager.initialized then
		return false
	end

	Events.OnTick.Add(AudioManager.update)
	AudioManager.initialized = true

	local applyOptions = MainOptions.apply
	---@diagnostic disable-next-line: duplicate-set-field
	function MainOptions:apply(closeAfter)
		applyOptions(self, closeAfter)
		AudioManager.syncVolume()
	end

	return true
end

---Sync the emitter volume with the global sound settings
function AudioManager.syncVolume()
	local soundManager = getSoundManager()
	local currentVolume = soundManager:getSoundVolume()

	AudioManager.soundEmitter:setVolumeAll(currentVolume)
	AudioManager.originalSoundVolume = currentVolume
end

---Update function called on each game tick
function AudioManager.update()
	AudioManager.soundEmitter:tick()

	local soundsToRemove = {}
	local hasActiveSounds = false
	local currentTime = getTimestampMs()

	for soundId, filePath in pairs(AudioManager.activeSounds) do
		if not AudioManager.soundEmitter:isPlaying(soundId) then
			if AudioManager.loopedSounds[soundId] then
				if currentTime - (AudioManager.soundTimestamps[soundId] or 0) > 50 then
					---@diagnostic disable-next-line: param-type-mismatch
					local newSoundId = AudioManager.soundEmitter:playSoundImpl(filePath, false, nil)

					if newSoundId then
						if AudioManager.soundVolumes[soundId] then
							AudioManager.soundEmitter:setVolume(newSoundId, AudioManager.soundVolumes[soundId])
							AudioManager.soundVolumes[newSoundId] = AudioManager.soundVolumes[soundId]
						end

						table.insert(soundsToRemove, soundId)

						AudioManager.activeSounds[newSoundId] = filePath
						AudioManager.loopedSounds[newSoundId] = true
						AudioManager.soundTimestamps[newSoundId] = currentTime
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
		AudioManager.activeSounds[soundId] = nil
		AudioManager.loopedSounds[soundId] = nil
		AudioManager.soundTimestamps[soundId] = nil
		AudioManager.soundVolumes[soundId] = nil
	end

	if not hasActiveSounds then
		AudioManager.restoreVolume()
	end
end

---Plays a sound once
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function AudioManager.playSound(file)
	if not file then
		return nil
	end

	---@diagnostic disable-next-line: param-type-mismatch
	local soundId = AudioManager.soundEmitter:playSoundImpl(file, false, nil)
	if soundId then
		AudioManager.activeSounds[soundId] = file
		AudioManager.soundTimestamps[soundId] = getTimestampMs()
	end
	return soundId
end

---Plays a sound in a loop using custom loop implementation
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function AudioManager.playSoundLooped(file)
	if not file then
		return nil
	end

	---@diagnostic disable-next-line: param-type-mismatch
	local soundId = AudioManager.soundEmitter:playSoundImpl(file, false, nil)
	if soundId then
		AudioManager.activeSounds[soundId] = file
		AudioManager.loopedSounds[soundId] = true
		AudioManager.soundTimestamps[soundId] = getTimestampMs()
	end
	return soundId
end

---Plays an ambient sound
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function AudioManager.playAmbientSound(file)
	if not file then
		return nil
	end

	local soundId = AudioManager.soundEmitter:playAmbientSound(file)
	if soundId then
		AudioManager.activeSounds[soundId] = file
		AudioManager.soundTimestamps[soundId] = getTimestampMs()
	end
	return soundId
end

---Plays an ambient sound in a loop using custom loop implementation
---@param file string The sound file path
---@return number|nil soundId The sound ID or nil if failed
function AudioManager.playAmbientLooped(file)
	if not file then
		return nil
	end

	local soundId = AudioManager.soundEmitter:playAmbientSound(file)
	if soundId then
		AudioManager.activeSounds[soundId] = file
		AudioManager.loopedSounds[soundId] = true
		AudioManager.soundTimestamps[soundId] = getTimestampMs()
	end
	return soundId
end

---Stops a specific sound by ID
---@param soundId number The sound ID to stop
---@return boolean success Whether the sound was stopped
function AudioManager.stopSound(soundId)
	if not soundId or not AudioManager.activeSounds[soundId] then
		return false
	end

	AudioManager.soundEmitter:stopSoundLocal(soundId)
	AudioManager.activeSounds[soundId] = nil
	AudioManager.loopedSounds[soundId] = nil
	AudioManager.soundTimestamps[soundId] = nil
	AudioManager.soundVolumes[soundId] = nil
	return true
end

---Stops a sound by its file path
---@param file string The sound file path
---@return boolean success Whether any sounds were stopped
function AudioManager.stopSoundByName(file)
	if not file then
		return false
	end

	AudioManager.soundEmitter:stopSoundByName(file)

	local found = false
	for soundId, soundFile in pairs(AudioManager.activeSounds) do
		if soundFile == file then
			AudioManager.activeSounds[soundId] = nil
			AudioManager.loopedSounds[soundId] = nil
			AudioManager.soundTimestamps[soundId] = nil
			AudioManager.soundVolumes[soundId] = nil
			found = true
		end
	end

	return found
end

function AudioManager.stopAll()
	AudioManager.soundEmitter:stopAll()
	AudioManager.activeSounds = {}
	AudioManager.loopedSounds = {}
	AudioManager.soundTimestamps = {}
	AudioManager.soundVolumes = {}
end

---Sets the volume for a specific sound
---@param soundId number The sound ID
---@param volume number The volume (0.0 to 1.0)
---@return boolean success Whether the volume was set
function AudioManager.setSoundVolume(soundId, volume)
	if not soundId or not AudioManager.activeSounds[soundId] then
		return false
	end

	if volume < 0 then
		volume = 0
	end
	if volume > 1 then
		volume = 1
	end

	AudioManager.soundEmitter:setVolume(soundId, volume)
	AudioManager.soundVolumes[soundId] = volume
	return true
end

---Sets the pitch for a specific sound
---@param soundId number The sound ID
---@param pitch number The pitch value
---@return boolean success Whether the pitch was set
function AudioManager.setPitch(soundId, pitch)
	if not soundId or not AudioManager.activeSounds[soundId] then
		return false
	end

	AudioManager.soundEmitter:setPitch(soundId, pitch)
	return true
end

---Sets the position for the sound emitter
---@param x number X coordinate
---@param y number Y coordinate
---@param z number Z coordinate
function AudioManager.setPosition(x, y, z)
	AudioManager.soundEmitter:setPos(x, y, z)
end

---Set the global sound volume
---@param value number The volume value (0.0 to 1.0)
function AudioManager.setVolume(value)
	if value < 0 then
		value = 0
	end
	if value > 1 then
		value = 1
	end

	local soundManager = getSoundManager()
	if not AudioManager.soundVolume then
		AudioManager.soundVolume = soundManager:getSoundVolume()
	end

	soundManager:setSoundVolume(value)
end

function AudioManager.restoreVolume()
	local soundManager = getSoundManager()
	if AudioManager.soundVolume then
		soundManager:setSoundVolume(AudioManager.originalSoundVolume)
		AudioManager.soundVolume = nil
	end
end

---Checks if a specific sound is playing
---@param soundId number The sound ID
---@return boolean isPlaying Whether the sound is playing
function AudioManager.isPlaying(soundId)
	if not soundId then
		return false
	end
	return AudioManager.soundEmitter:isPlaying(soundId)
end

---Checks if a sound with the given name is playing
---@param file string The sound file path
---@return boolean isPlaying Whether any sound with this name is playing
function AudioManager.isPlayingByName(file)
	if not file then
		return false
	end
	return AudioManager.soundEmitter:isPlaying(file)
end

---Gets all currently active sound IDs
---@return table<number, string> Map of sound IDs to file paths
function AudioManager.getActiveSounds()
	return AudioManager.activeSounds
end

---Gets count of currently active sounds
---@return number count Number of active sounds
function AudioManager.getActiveSoundCount()
	local count = 0
	for _ = 0, #AudioManager.activeSounds do
		count = count + 1
	end
	return count
end

Events.OnCreatePlayer.Add(AudioManager.init)

return AudioManager
