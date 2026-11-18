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
        id = "randomize", title = tr("UI_PNC_Authoring_RandomizeLook", "Randomize look"),
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
    self.topControls = { self.playVoiceButton, self.stopVoiceButton }
    local random = PNC.NPCAuthoringFields.CanRandomize(self)
    self.randomizeButton:setVisible(random)
    if random then table.insert(self.topControls, 1, self.randomizeButton) end
    if not self.integrated and self.parentEditor and self.parentEditor.presentationMode == "companion" then
        self.advancedClothingButton = UI.CreateButton(self, {
            id = "advancedClothing",
            title = tr("UI_PNC_NPCAuthoring_AdvancedClothing",
                "ADVANCED CLOTHING OVERRIDES"),
            target = self,
            onclick = ISPNCUniqueNPCAppearanceWindow.onAction,
            variant = "quiet",
        })
        self.topControls[#self.topControls + 1] = self.advancedClothingButton
    end
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
    for _, event in ipairs({ "onMouseUp", "onMouseUpOutside" }) do
        local original = self.voicePitch[event]
        self.voicePitch[event] = function(slider, x, y)
            if original then original(slider, x, y) end
            self:commitPendingVoice()
        end
    end
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
    if self.integrated then
        self.hairColorLabel = ISLabel:new(0, 0, 24,
            tr("UI_PNC_NPCAuthoring_HairColor", "Hair color"), 0.72, 0.78, 0.84, 1, UIFont.Small, true)
        self.hairColorLabel:initialise()
        self.content:addChild(self.hairColorLabel)
        self.hairColorCombo = ISComboBox:new(0, 0, 1, 24, self,
            ISPNCUniqueNPCAppearanceWindow.onHairColorChanged)
        self.hairColorCombo:initialise()
        self.content:addChild(self.hairColorCombo)
        self.hairPalette = {
            { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
            { id = "black", label = tr("UI_PNC_Authoring_Black", "Black"), r = 0.08, g = 0.06, b = 0.05 },
            { id = "brown", label = tr("UI_PNC_Authoring_Brown", "Brown"), r = 0.30, g = 0.19, b = 0.10 },
            { id = "blond", label = tr("UI_PNC_Authoring_Blond", "Blond"), r = 0.78, g = 0.65, b = 0.35 },
            { id = "red", label = tr("UI_PNC_Authoring_Red", "Red"), r = 0.55, g = 0.16, b = 0.08 },
            { id = "gray", label = tr("UI_PNC_Authoring_Gray", "Gray"), r = 0.55, g = 0.55, b = 0.55 },
            { id = "white", label = tr("UI_PNC_Authoring_White", "White"), r = 0.90, g = 0.90, b = 0.85 },
        }
        addOptions(self.hairColorCombo, self.hairPalette)
    end
end

local function buildAppearanceIdentityControls(self)
    self.hairLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_Hair", "Hair style"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.hairLabel:initialise()
    self.content:addChild(self.hairLabel)
    self.hairCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onHairChanged)
    self.hairCombo:initialise()
    self.content:addChild(self.hairCombo)

    self.beardLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_UniqueNPCEditor_Beard", "Beard"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.beardLabel:initialise()
    self.content:addChild(self.beardLabel)
    self.beardCombo = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onBeardChanged)
    self.beardCombo:initialise()
    self.content:addChild(self.beardCombo)
end

local function buildAdvancedLabel(self)
    self.advancedLabel = ISLabel:new(0, 0, 24,
        tr("UI_PNC_NPCAuthoring_AdvancedClothing",
            "ADVANCED CLOTHING OVERRIDES"),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    self.advancedLabel:initialise()
    self.content:addChild(self.advancedLabel)
end

local function finishAppearanceControls(self)
    self:buildOutfitOptions()
    self:buildVoiceOptions()
    self:refreshHairBeardOptions()
    if not self.integrated then
        for _, location in ipairs(locations()) do self:addLocationRow(location) end
    end
    if self.syncAdvancedVisibility then self:syncAdvancedVisibility() end
    self:syncFromDraft()
end

function ISPNCUniqueNPCAppearanceWindow:createChildren()
    ISPanel.createChildren(self)
    initializeAppearanceState(self)
    self.advancedVisible = not (self.parentEditor
        and self.parentEditor.presentationMode == "companion")
    buildAppearanceTopControls(self)
    buildAppearanceVoiceControls(self)
    buildAppearanceSkinControls(self)
    buildAppearanceIdentityControls(self)
    buildAdvancedLabel(self)
    finishAppearanceControls(self)
end


