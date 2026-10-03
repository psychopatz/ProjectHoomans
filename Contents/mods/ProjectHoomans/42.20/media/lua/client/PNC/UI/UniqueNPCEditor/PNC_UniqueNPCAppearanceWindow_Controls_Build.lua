local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local UI = Internal.UI
local tr = Internal.tr
local skinToneOptions = Internal.skinToneOptions
local locations = Internal.locations
local itemOptions = Internal.itemOptions
local runtimeItemFor = Internal.runtimeItemFor
local addOptions = Internal.addOptions

local function initializeAppearanceState(self)
    ISPanel.createChildren(self)
    self.rows = {}
    self.topControls = {}
    self.voiceStyles = {}
    self.voiceEvents = {}
    self.syncing = false
end

local function buildAppearanceTopControls(self)
    self.randomizeButton = UI.CreateButton(self, {
        id = "randomize", title = tr("UI_PNC_UniqueNPCEditor_Randomize", "RANDOMIZE"),
        target = self, onclick = ISPNCUniqueNPCAppearanceWindow.onAction,
        variant = "selected",
    })
    self.playVoiceButton = UI.CreateButton(self, {
        id = "playVoice", title = tr("UI_PNC_UniqueNPCEditor_PlayVoice", "PLAY VOICE"),
        target = self, onclick = ISPNCUniqueNPCAppearanceWindow.onAction,
        variant = "primary",
    })
    self.stopVoiceButton = UI.CreateButton(self, {
        id = "stopVoice", title = tr("UI_PNC_UniqueNPCEditor_StopVoice", "STOP VOICE"),
        target = self, onclick = ISPNCUniqueNPCAppearanceWindow.onAction,
        variant = "quiet",
    })
    self.topControls = {
        self.randomizeButton, self.playVoiceButton, self.stopVoiceButton,
    }
    self.content = ISPNCUniqueNPCAppearanceScrollPanel:new(0, 0, 1, 1)
    self.content:initialise()
    self.content:instantiate()
    self:addChild(self.content)
end

local function buildAppearanceVoiceControls(self)
    self.outfitLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_Outfit", "Outfit"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.outfitLabel:initialise()
    self.content:addChild(self.outfitLabel)
    self.outfitCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onOutfitChanged)
    self.outfitCombo:initialise()
    self.content:addChild(self.outfitCombo)

    self.voiceLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_VoiceStyle", "Voice style"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.voiceLabel:initialise()
    self.content:addChild(self.voiceLabel)
    self.voiceCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onVoiceChanged)
    self.voiceCombo:initialise()
    self.content:addChild(self.voiceCombo)

    self.voiceSampleLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_VoiceSample", "Voice sample"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.voiceSampleLabel:initialise()
    self.content:addChild(self.voiceSampleLabel)
    self.voiceSampleCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onVoiceSampleChanged)
    self.voiceSampleCombo:initialise()
    self.content:addChild(self.voiceSampleCombo)

    self.voicePitchLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_VoicePitch", "Voice pitch"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.voicePitchLabel:initialise()
    self.content:addChild(self.voicePitchLabel)
    self.voicePitch = ISSliderPanel:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onVoicePitchChanged)
    self.voicePitch:initialise()
    self.voicePitch:instantiate()
    self.voicePitch:setValues(-100, 100, 1, 10)
    self.content:addChild(self.voicePitch)
    self.voicePitchValue = ISLabel:new(0, 0, 24, "0",
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.voicePitchValue:initialise()
    self.content:addChild(self.voicePitchValue)
end

local function buildAppearanceSkinControls(self)
    self.skinLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_SkinColor", "Skin color"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.skinLabel:initialise()
    self.content:addChild(self.skinLabel)
    self.skinModeCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onSkinModeChanged)
    self.skinModeCombo:initialise()
    self.content:addChild(self.skinModeCombo)
    addOptions(self.skinModeCombo, skinToneOptions(
        self.draft and self.draft.isFemale == true))
    self.skinSwatch = ISPanel:new(0, 0, 1, 1)
    self.skinSwatch:initialise()
    self.skinSwatch.backgroundColor = { r = 0.65, g = 0.5, b = 0.4, a = 1 }
    self.skinSwatch.borderColor = { r = 0.75, g = 0.75, b = 0.75, a = 1 }
    self.content:addChild(self.skinSwatch)
    self.skinValue = ISLabel:new(0, 0, 24, "",
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.skinValue:initialise()
    self.content:addChild(self.skinValue)
end

local function finishAppearanceControls(self)
    self:buildOutfitOptions()
    self:buildVoiceOptions()
    for _, location in ipairs(locations()) do self:addLocationRow(location) end
    self:syncFromDraft()
end

function ISPNCUniqueNPCAppearanceWindow:createChildren()
    ISPanel.createChildren(self)
    initializeAppearanceState(self)
    buildAppearanceTopControls(self)
    buildAppearanceVoiceControls(self)
    buildAppearanceSkinControls(self)
    finishAppearanceControls(self)
end


