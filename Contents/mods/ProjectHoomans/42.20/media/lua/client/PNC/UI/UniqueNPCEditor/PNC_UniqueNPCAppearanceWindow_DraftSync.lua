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
    local voiceID = "random"
    self.syncing = true
    selectData(self.outfitCombo, outfitID)
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
    selectData(self.voiceCombo, voiceID)
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
        selectData(self.skinModeCombo, skinTone)
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
    setLabelText(self.skinValue, skinToneLabel(skinTone))
    for _, row in ipairs(self.rows) do
        local policy = appearance.slots and appearance.slots[row.location]
            or { mode = "none" }
        selectData(row.policy, policy.mode)
        if policy.type then selectData(row.item, policy.type) end
        row.item:setEnabled(policy.mode == "item")
    end
    self.syncing = false
end

return Window
