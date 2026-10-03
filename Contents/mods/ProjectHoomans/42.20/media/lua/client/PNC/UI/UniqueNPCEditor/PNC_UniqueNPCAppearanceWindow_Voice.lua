local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local Model = Internal.Model
local AudioDebug = Internal.AudioDebug
local Appearance = Internal.Appearance
local tr = Internal.tr
local comboData = Internal.comboData

function ISPNCUniqueNPCAppearanceWindow:voiceProfile()
    local survivor = self.draft.identity
        and self.draft.identity.survivor or {}
    local appearance = Appearance.Normalize(self.draft.appearance)
    local voice = appearance.voice or {}
    local prefix = survivor.voicePrefix or survivor.voice or voice.prefix
    if prefix then
        return {
            prefix = tostring(prefix),
            voiceType = tonumber(survivor.voiceType or voice.type) or 0,
            pitch = tonumber(survivor.voicePitch or voice.pitch) or 0,
        }
    end
    if PNC.NPCVoice and PNC.NPCVoice.GetProfile then
        return PNC.NPCVoice.GetProfile({
            identitySeed = self.draft.previewSeed,
            isFemale = self.draft.isFemale == true,
        }, AudioDebug and AudioDebug.GetCurrentPlayer
            and AudioDebug.GetCurrentPlayer() or nil)
    end
    return nil
end

function ISPNCUniqueNPCAppearanceWindow:onPlayVoice()
    local player = AudioDebug and AudioDebug.GetCurrentPlayer
        and AudioDebug.GetCurrentPlayer() or nil
    local suffix = comboData(self.voiceSampleCombo) or "ShoutHey"
    local profile = self:voiceProfile()
    local handle
    local reason
    if not player or not AudioDebug or not AudioDebug.PlayDialogue then
        if self.parentEditor and self.parentEditor.setStatus then
            self.parentEditor:setStatus(
                tr("UI_PNC_UniqueNPCEditor_VoiceUnavailable",
                    "Voice preview unavailable"))
        end
        return
    end
    handle, reason = AudioDebug.PlayDialogue(player,
        { suffix = tostring(suffix) }, profile)
    if handle and handle ~= 0 then
        if self.parentEditor and self.parentEditor.setStatus then
            self.parentEditor:setStatus(
                tr("UI_PNC_UniqueNPCEditor_VoicePlaying",
                    "Playing voice preview"))
        end
    else
        if self.parentEditor and self.parentEditor.setStatus then
            self.parentEditor:setStatus(
                tostring(reason or "voice preview failed"))
        end
    end
end

function ISPNCUniqueNPCAppearanceWindow:onStopVoice()
    local player = AudioDebug and AudioDebug.GetCurrentPlayer
        and AudioDebug.GetCurrentPlayer() or nil
    if player and AudioDebug and AudioDebug.StopDialogue then
        AudioDebug.StopDialogue(player)
    end
end

function ISPNCUniqueNPCAppearanceWindow:onAction(button)
    local action = button and button.internal or ""
    if action == "randomize" then
        self.draft.previewSeed = nil
        Model.Randomize(self.draft)
        self:markChanged()
    elseif action == "playVoice" then
        self:onPlayVoice()
    elseif action == "stopVoice" then
        self:onStopVoice()
    end
end

