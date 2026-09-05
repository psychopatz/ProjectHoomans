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
    local voicePrefix
    local dynamicSuffixes
    local i
    if not zombie then return false end
    if zombie.getDescriptor then
        descriptor = zombie:getDescriptor()
        if descriptor and descriptor.getVoicePrefix then
            voicePrefix = descriptor:getVoicePrefix()
        end
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
    -- Build 42 can add the Sprinter infix, and fall damage uses the cached
    -- IsoGameCharacter hurt sound rather than the descriptor prefix.  Stop
    -- the currently selected native channels before changing the prefix and
    -- replace the cached hurt channel with the same intentionally silent
    -- prefix so a landing cannot reintroduce a zombie moan.
    dynamicSuffixes = {
        "VoiceA", "VoiceB", "VoiceC",
        "SprinterVoiceA", "SprinterVoiceB", "SprinterVoiceC",
        "Hurt", "Attack", "Bite", "Eating", "Idle", "Death",
    }
    if voicePrefix and voicePrefix ~= "" then
        for i = 1, #dynamicSuffixes do
            emitter:stopSoundByName(voicePrefix .. dynamicSuffixes[i])
        end
    end
    if zombie.getVoiceSoundName then
        emitter:stopSoundByName(zombie:getVoiceSoundName())
    end
    if zombie.getBiteSoundName then
        emitter:stopSoundByName(zombie:getBiteSoundName())
    end
    if zombie.getHurtSound then
        emitter:stopSoundByName(zombie:getHurtSound())
    end
    if zombie.setHurtSound then
        zombie:setHurtSound("NotAZombieHurt")
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
