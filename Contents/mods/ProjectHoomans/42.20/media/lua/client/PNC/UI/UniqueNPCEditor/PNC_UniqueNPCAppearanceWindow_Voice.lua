require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringVoicePreview"
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
    if not self.draft then return end
    self:commitPendingVoice()
    self.voicePreview = self.voicePreview or PNC.NPCAuthoringVoicePreview.New()
    local ok = self.voicePreview:Play(self:voiceProfile(), comboData(self.voiceSampleCombo) or "ShoutHey")
    if self.parentEditor then
        self.parentEditor:setStatus(tr(ok and "UI_PNC_UniqueNPCEditor_VoicePlaying"
            or "UI_PNC_UniqueNPCEditor_VoiceUnavailable", ok and "Playing voice preview" or "Voice preview unavailable"))
    end
end

function ISPNCUniqueNPCAppearanceWindow:onStopVoice()
    if self.voicePreview then self.voicePreview:Stop() end
end

function ISPNCUniqueNPCAppearanceWindow:onAction(button)
    local action = button and button.internal or ""
    if action == "randomize" then
        if self.parentEditor and self.parentEditor.presentationAdapter
            and self.parentEditor.invokeWorkflow
        then
            -- Companion Randomize is a session operation.  Do not mutate a
            -- local resolved draft and accidentally leave the canonical seed
            -- unchanged.
            if self.parentEditor:pullForm() == false then return end
            self.parentEditor:invokeWorkflow("randomize")
            return
        end
        self.draft.previewSeed = nil
        Model.Randomize(self.draft)
        self:markChanged()
    elseif action == "playVoice" then
        self:onPlayVoice()
    elseif action == "stopVoice" then
        self:onStopVoice()
    elseif action == "advancedClothing" then
        self.advancedVisible = not (self.advancedVisible == true)
        self:syncAdvancedVisibility()
        if self.onResponsiveLayout then self:onResponsiveLayout() end
    end
end

