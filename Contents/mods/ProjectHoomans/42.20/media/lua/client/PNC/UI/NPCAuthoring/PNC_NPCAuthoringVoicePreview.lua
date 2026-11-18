-- Actorless preview, following vanilla CharacterCreationMain's UI emitter.
-- This object owns one sound handle; it never stops other UI/game sounds.
PNC.NPCAuthoringVoicePreview = PNC.NPCAuthoringVoicePreview or {}
local Preview = PNC.NPCAuthoringVoicePreview

function Preview.New()
    return setmetatable({ handle = 0 }, { __index = Preview })
end

function Preview:Stop()
    if self.emitter and self.handle ~= 0 then self.emitter:stopSound(self.handle) end
    self.handle = 0
end

function Preview:Play(profile, suffix)
    self:Stop()
    local manager = getSoundManager and getSoundManager()
    if not manager or not manager.getUIEmitter or not manager.playUISound then
        return false, "audio_unavailable"
    end
    self.emitter = manager:getUIEmitter()
    if not self.emitter or not profile or not profile.prefix then return false, "audio_unavailable" end
    local name = tostring(profile.prefix) .. tostring(suffix or "ShoutHey")
    if GameSounds and not GameSounds.isKnownSound(name) then return false, "voice_event_unavailable" end
    self.handle = manager:playUISound(name) or 0
    if self.handle == 0 then return false, "voice_play_failed" end
    self.emitter:setParameterValueByName(self.handle, "CharacterVoicePitch", tonumber(profile.pitch) or 0)
    self.emitter:setParameterValueByName(self.handle, "CharacterVoiceType", tonumber(profile.voiceType) or 0)
    self.emitter:tick()
    return true
end

return Preview
