-- Actorless preview, following vanilla CharacterCreationMain's UI emitter.
-- This object owns one sound handle; it never stops other UI/game sounds.
PNC.NPCAuthoringVoicePreview = PNC.NPCAuthoringVoicePreview or {}
local Preview = PNC.NPCAuthoringVoicePreview
local menuUsers = 0

function Preview.New()
    return setmetatable({ handle = 0 }, { __index = Preview })
end

function Preview:Stop()
    if self.emitter and self.handle ~= 0 then self.emitter:stopSound(self.handle) end
    self.handle = 0
    if self.menuManager then
        menuUsers = math.max(0, menuUsers - 1)
        if menuUsers == 0 and MainScreen and MainScreen.instance and not MainScreen.instance.inGame then
            self.menuManager:setMusicState("MainMenu")
        end
        self.menuManager = nil
    end
end

function Preview:Update()
    if self.handle ~= 0 and self.emitter and self.emitter.isPlaying and not self.emitter:isPlaying(self.handle) then self:Stop() end
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
    local menu = MainScreen and MainScreen.instance and not MainScreen.instance.inGame
    if menu and manager.setMusicState then
        manager:setMusicState("InGame") -- same FMOD routing as native PLAYDEMOVOICE
        self.menuManager = manager; menuUsers = menuUsers + 1
    end
    if menu and manager.resumeSoundAndMusic then manager:resumeSoundAndMusic() end
    self.handle = manager:playUISound(name) or 0
    if self.handle == 0 then self:Stop(); return false, "voice_play_failed" end
    if menu and self.emitter.setPos then self.emitter:setPos(0, 0, 0) end
    self.emitter:setParameterValueByName(self.handle, "CharacterVoicePitch", tonumber(profile.pitch) or 0)
    self.emitter:setParameterValueByName(self.handle, "CharacterVoiceType", tonumber(profile.voiceType) or 0)
    self.emitter:tick()
    return true
end

return Preview
