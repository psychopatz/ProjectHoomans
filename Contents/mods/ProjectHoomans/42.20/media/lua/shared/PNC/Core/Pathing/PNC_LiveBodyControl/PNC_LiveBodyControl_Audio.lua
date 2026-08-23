-- Zombie-voice suppression without interrupting intentional NPC sounds.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core
local VOICE_SOUNDS = {
    "FemaleZombieVoiceA",
    "FemaleZombieVoiceB",
    "FemaleZombieVoiceC",
    "MaleZombieVoiceA",
    "MaleZombieVoiceB",
    "MaleZombieVoiceC",
}

Internal.SUPPRESSION_AUDIO_COOLDOWN_MS = 250

function LiveBodyControl.StopEmitter(zombie)
    local emitter
    if not zombie or not zombie.getEmitter then return false end
    emitter = zombie:getEmitter()
    if not emitter or not emitter.stopAll then return false end
    emitter:stopAll()
    return true
end

function LiveBodyControl.SuppressZombieSounds(zombie)
    local descriptor
    local emitter
    local i
    if not zombie then return false end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.setVoicePrefix then
            descriptor:setVoicePrefix("NotAZombie")
        end
    end
    emitter = zombie.getEmitter and zombie:getEmitter() or nil
    if not emitter or not emitter.stopSoundByName then
        return descriptor ~= nil
    end
    for i = 1, #VOICE_SOUNDS do
        emitter:stopSoundByName(VOICE_SOUNDS[i])
    end
    return true
end

function LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    if not lane then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if (now - (tonumber(lane.lastSuppressAudioAt) or 0))
        < Internal.SUPPRESSION_AUDIO_COOLDOWN_MS
    then
        return false
    end
    if not LiveBodyControl.SuppressZombieSounds(zombie) then return false end
    lane.lastSuppressAudioAt = now
    return true
end
