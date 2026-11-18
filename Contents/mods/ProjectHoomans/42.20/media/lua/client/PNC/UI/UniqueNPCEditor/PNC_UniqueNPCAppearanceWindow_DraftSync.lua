-- Draft-to-control synchronization for the Unique NPC appearance window.

local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local Appearance = Internal.Appearance
local clamp = Internal.clamp
local setLabelText = Internal.setLabelText
local setControlEnabled = Internal.setControlEnabled
local tr = Internal.tr
local selectData = Internal.selectData
local skinToneFromTexture = Internal.skinToneFromTexture
local skinToneColor = Internal.skinToneColor
local skinToneLabel = Internal.skinToneLabel

function ISPNCUniqueNPCAppearanceWindow:syncFromDraft()
    local appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(self.draft and self.draft.appearance) or {}
    local outfit = appearance.outfit or { mode = "random" }
    local outfitID = outfit.mode == "item" and outfit.id
        and "named:" .. tostring(outfit.id) or outfit.mode
    local survivor = self.draft and self.draft.identity
        and self.draft.identity.survivor or {}
    local voice = appearance.voice or { mode = "random" }
    local voicePrefix = survivor.voicePrefix or survivor.voice
        or voice.prefix
    local voiceType = tonumber(survivor.voiceType or voice.type)
    local voicePitch = tonumber(survivor.voicePitch or voice.pitch) or 0
    setLabelText(self.voicePitchLabel, tr("UI_PNC_UniqueNPCEditor_VoicePitch", "Voice pitch") .. ": " .. math.floor(voicePitch))
    local voiceID = "random"
    self.syncing = true
    PNC.NPCAuthoringFields.Select(self, self.outfitCombo, outfitID)
    local explicitVoice = voicePrefix ~= nil
        or voiceType ~= nil or survivor.voicePitch ~= nil
    if (voice.mode == "item" or explicitVoice) and voicePrefix then
        for _, style in ipairs(self.voiceStyles or {}) do
            if style.prefix == tostring(voicePrefix)
                and (voiceType == nil or style.voiceType == voiceType)
            then
                voiceID = style.id
                break
            end
        end
        if voiceID == "random" then
            for _, style in ipairs(self.voiceStyles or {}) do
                if style.prefix == tostring(voicePrefix) then
                    voiceID = style.id
                    break
                end
            end
        end
    end
    PNC.NPCAuthoringFields.Select(self, self.voiceCombo, voiceID)
    if self.voicePitch and self.voicePitch.setCurrentValue then
        self.voicePitch:setCurrentValue(
            math.max(-100, math.min(100, math.floor(voicePitch))), true)
    end
    if self.voicePitchValue and self.voicePitchValue.setName then
        self.voicePitchValue:setName(tostring(math.floor(voicePitch)))
    end
    local voiceEnabled = voice.mode == "item" or explicitVoice
    setControlEnabled(self.voicePitch, voiceEnabled)
    local skinTone = skinToneFromTexture(survivor.skinTexture)
    if survivor.skinColor and skinTone == "random" then
        -- Preserve definitions written by the previous RGB editor.  They are
        -- displayed as legacy data until the author chooses a native tone.
        skinTone = "legacy"
        if self.skinModeCombo and self.skinModeCombo.addOptionWithData then
            local hasLegacy = false
            for _, option in ipairs(self.skinModeCombo.options or {}) do
                if option.data == "legacy" then
                    hasLegacy = true
                    break
                end
            end
            if not hasLegacy then
                self.skinModeCombo:addOptionWithData(
                    tr("UI_PNC_UniqueNPCEditor_LegacySkin",
                        "Legacy custom tone (select a native tone to replace)"),
                    "legacy")
            end
            selectData(self.skinModeCombo, "legacy")
        end
    else
        PNC.NPCAuthoringFields.Select(self, self.skinModeCombo, skinTone)
    end
    if self.skinSwatch then
        local swatch = survivor.skinColor or skinToneColor(skinTone)
        self.skinSwatch.backgroundColor = {
            r = clamp(swatch.r, 0, 1),
            g = clamp(swatch.g, 0, 1),
            b = clamp(swatch.b, 0, 1),
            a = 1,
        }
    end
    local skinEditable = true
    local skinSource
    if self.parentEditor and self.parentEditor.presentationMode == "companion"
        and self.parentEditor.fieldCapability
    then
        local skin = self.parentEditor:fieldCapability("appearance.skinTexture")
        local skinColor = self.parentEditor:fieldCapability("appearance.skinColor")
        skinEditable = skin and skin.editable ~= false
            and skinColor and skinColor.editable ~= false
        skinSource = skin and skin.sourceLabel or skinColor and skinColor.sourceLabel
    end
    if self.skinModeCombo then
        if self.skinModeCombo.setEnabled then
            self.skinModeCombo:setEnabled(skinEditable == true)
        end
        self.skinModeCombo:setVisible(true)
    end
    local skinText = skinToneLabel(skinTone)
    setLabelText(self.skinValue, skinText)
    if self.hairCombo then PNC.NPCAuthoringFields.Select(self, self.hairCombo, survivor.hairModel) end
    if self.beardCombo then PNC.NPCAuthoringFields.Select(self, self.beardCombo, survivor.beardModel) end
    if self.beardCombo and self.beardCombo.setEnabled then
        self.beardCombo:setEnabled(self.draft and self.draft.isFemale ~= true)
    end
    if self.hairColorCombo then
        local color = survivor.hairColor
        local id = color and "custom" or "random"
        for _, option in ipairs(self.hairPalette) do
            if color and option.r and math.abs(color.r - option.r) < 0.001
                and math.abs(color.g - option.g) < 0.001 and math.abs(color.b - option.b) < 0.001
            then id = option.id end
        end
        PNC.NPCAuthoringFields.Options(self, self.hairColorCombo, self.hairPalette, id)
        PNC.NPCAuthoringFields.Select(self, self.hairColorCombo, id)
        local capability = self.parentEditor:fieldCapability("appearance.hairColor")
        setControlEnabled(self.hairColorCombo, capability.editable ~= false)
    end
    for _, row in ipairs(self.rows) do
        local policy = appearance.slots and appearance.slots[row.location]
            or { mode = "none" }
        PNC.NPCAuthoringFields.Select(self, row.policy, policy.mode)
        if policy.type then selectData(row.item, policy.type) end
        row.item:setEnabled(policy.mode == "item")
    end
    if self.integrated and self.parentEditor then
        for control, id in pairs({
            skinModeCombo = "appearance.skinTexture", hairCombo = "appearance.hairModel",
            beardCombo = "appearance.beardModel", hairColorCombo = "appearance.hairColor",
            voiceCombo = "appearance.voice", voicePitch = "appearance.voicePitch",
        }) do
            if self[control] then PNC.NPCAuthoringFields.Lock(self.parentEditor,
                self[control], id, self.content) end
        end
    end
    if self.syncAdvancedVisibility then self:syncAdvancedVisibility() end
    self.syncing = false
end

return Window
