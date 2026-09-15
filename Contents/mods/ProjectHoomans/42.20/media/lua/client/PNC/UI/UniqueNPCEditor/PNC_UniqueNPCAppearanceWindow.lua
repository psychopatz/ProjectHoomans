require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"
require "RadioCom/ISUIRadio/ISSliderPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_AudioDebugModel"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
pcall(require, "PNC/Core/Identity/PNC_Identity_Appearance")

PNC = PNC or {}
PNC.UniqueNPCAppearanceUI = PNC.UniqueNPCAppearanceUI or {}

local AppearanceUI = PNC.UniqueNPCAppearanceUI
local Model = PNC.UniqueNPCEditorModel
local Appearance = PNC.Identity and PNC.Identity.Appearance
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local AudioDebug = PNC.AudioDebug

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

local function setLabelText(label, value)
    value = tostring(value or "")
    if UI.SetLabelText then
        UI.SetLabelText(label, value)
    elseif label and label.setName then
        label:setName(value)
    end
end

local function setControlEnabled(control, enabled)
    if not control then return end
    if control.setEnabled then
        control:setEnabled(enabled == true)
    elseif control.setEnable then
        control:setEnable(enabled == true)
    end
end

ISPNCUniqueNPCAppearanceScrollPanel = ISPanel:derive(
    "ISPNCUniqueNPCAppearanceScrollPanel")

function ISPNCUniqueNPCAppearanceScrollPanel:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCUniqueNPCAppearanceScrollPanel:createChildren()
    ISPanel.createChildren(self)
    self:setScrollChildren(true)
    self:addScrollBars()
end

function ISPNCUniqueNPCAppearanceScrollPanel:onResize()
    if self.vscroll then
        local scrollWidth = self.vscroll.getWidth
            and self.vscroll:getWidth() or self.vscroll.width or 13
        self.vscroll:setX(math.max(0, self.width - scrollWidth))
        self.vscroll:setHeight(self.height)
    end
end

function ISPNCUniqueNPCAppearanceScrollPanel:onMouseWheel(delta)
    local current = self.getYScroll and tonumber(self:getYScroll()) or 0
    local maximum = math.max(0,
        (tonumber(self.contentHeight) or 0) - (tonumber(self.height) or 0))
    if self.setYScroll then
        self:setYScroll(math.max(-maximum, math.min(0,
            current + (tonumber(delta) or 0) * 32)))
    end
    return true
end

function ISPNCUniqueNPCAppearanceScrollPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function ISPNCUniqueNPCAppearanceScrollPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end

local function tr(key, fallback)
    return PNC.Translation.GetKey(key, fallback or key)
end

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function comboData(combo)
    local selected = combo and combo.selected or 0
    local option = combo and combo.options and combo.options[selected]
    return option and option.data or nil
end

local function selectData(combo, value)
    local found = false
    if value ~= nil and combo and combo.selectData then
        combo:selectData(value)
        for _, option in ipairs(combo.options or {}) do
            if option.data == value then
                found = true
                break
            end
        end
        if not found and combo.addOptionWithData then
            combo:addOptionWithData(
                tr("UI_PNC_UniqueNPCEditor_Unavailable", "Unavailable: ")
                    .. tostring(value), value)
            combo:selectData(value)
        end
    end
    if combo and combo.selected == 0 and combo.options and combo.options[1] then
        combo.selected = 1
    end
end

local function listValues(value)
    local output = {}
    if type(value) == "table" then
        for _, entry in ipairs(value) do output[#output + 1] = entry end
    elseif value and value.size and value.get then
        for index = 0, value:size() - 1 do
            output[#output + 1] = value:get(index)
        end
    end
    return output
end

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function voiceOptions(isFemale)
    local output = {}
    local raw
    local values
    local bodyType = isFemale and 1 or 2
    if type(getAllVoiceStyles) == "function" then
        local ok
        ok, raw = pcall(getAllVoiceStyles)
        if not ok then raw = nil end
    end
    values = listValues(raw)
    for _, style in ipairs(values) do
        local prefix = call(style, "getPrefix")
        local name = call(style, "getName")
        local styleBodyType = tonumber(call(style, "getBodyTypeDefault"))
        local styleType = tonumber(call(style, "getVoiceType")) or 0
        if prefix and (styleBodyType == nil or styleBodyType == bodyType) then
            output[#output + 1] = {
                id = #output + 1,
                label = tostring(name or prefix),
                prefix = tostring(prefix),
                voiceType = math.max(0, math.min(3, math.floor(styleType))),
            }
        end
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    if #output == 0 and AudioDebug and AudioDebug.GetVoiceStyles then
        for _, style in ipairs(AudioDebug.GetVoiceStyles() or {}) do
            if tostring(style.prefix or "") ~= ""
                and (tonumber(style.bodyTypeDefault) == nil
                    or tonumber(style.bodyTypeDefault) == bodyType)
            then
                output[#output + 1] = {
                    id = #output + 1,
                    label = tostring(style.name or style.prefix),
                    prefix = tostring(style.prefix),
                    voiceType = math.max(0, math.min(3,
                        math.floor(tonumber(style.voiceType) or 0))),
                }
            end
        end
    end
    for index, option in ipairs(output) do option.id = index end
    return output
end

-- The base-game character creator exposes five skin texture choices.  The
-- color values are only the swatches shown by its picker; the actual visual
-- state is the gender-specific HumanVisual skin texture/index.
local SKIN_TONES = {
    { id = "tone:1", label = "Tone 1", color = { r = 1.00, g = 0.91, b = 0.72 } },
    { id = "tone:2", label = "Tone 2", color = { r = 0.98, g = 0.79, b = 0.49 } },
    { id = "tone:3", label = "Tone 3", color = { r = 0.80, g = 0.65, b = 0.45 } },
    { id = "tone:4", label = "Tone 4", color = { r = 0.54, g = 0.38, b = 0.25 } },
    { id = "tone:5", label = "Tone 5", color = { r = 0.36, g = 0.25, b = 0.14 } },
}

local function skinToneOptions(isFemale)
    local output = {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
    }
    for _, tone in ipairs(SKIN_TONES) do
        output[#output + 1] = {
            id = tone.id,
            label = tr("UI_PNC_UniqueNPCEditor_SkinTone_" ..
                string.sub(tone.id, 6), tone.label),
        }
    end
    return output
end

local function skinToneFromTexture(texture)
    local value = tostring(texture or "")
    local number = tonumber(string.match(value, "Body0(%d+)$"))
    if number and number >= 1 and number <= #SKIN_TONES then
        return "tone:" .. tostring(number)
    end
    return "random"
end

local function skinTextureForTone(value, isFemale)
    local number = tonumber(string.match(tostring(value or ""), "^tone:(%d+)$"))
    if not number or number < 1 or number > #SKIN_TONES then return nil end
    return (isFemale and "FemaleBody" or "MaleBody")
        .. string.format("%02d", number)
end

local function skinToneColor(value)
    for _, tone in ipairs(SKIN_TONES) do
        if tone.id == value then return tone.color end
    end
    return { r = 0.65, g = 0.50, b = 0.40 }
end

local function skinToneLabel(value)
    if value == "random" then
        return tr("UI_PNC_UniqueNPCEditor_Random", "Random")
    end
    if value == "legacy" then
        return tr("UI_PNC_UniqueNPCEditor_LegacySkin",
            "Legacy custom tone (select a native tone to replace)")
    end
    for _, tone in ipairs(SKIN_TONES) do
        if tone.id == value then
            return tr("UI_PNC_UniqueNPCEditor_SkinTone_" ..
                string.sub(tone.id, 6), tone.label)
        end
    end
    return tostring(value or "")
end

local function labelFor(location)
    return tr("UI_ClothingType_" .. tostring(location), tostring(location))
end

local function locations()
    local output = {}
    local seen = {}
    local group = BodyLocations and BodyLocations.getGroup
        and BodyLocations.getGroup("Human") or nil
    if group and group.size then
        for index = 0, group:size() - 1 do
            local location = group:getLocationByIndex(index)
            local id = location and location.getId and tostring(location:getId()) or nil
            if id and id ~= "Wound" and id ~= "ZedDmg" and not seen[id] then
                seen[id] = true
                output[#output + 1] = id
            end
        end
    end
    table.sort(output, function(left, right)
        return string.lower(labelFor(left)) < string.lower(labelFor(right))
    end)
    return output
end

local function itemOptions(location)
    local output = {}
    local values
    local ok
    if type(getAllItemsForBodyLocation) ~= "function" then return output end
    ok, values = pcall(getAllItemsForBodyLocation, location)
    if not ok or type(values) ~= "table" then return output end
    for _, fullType in ipairs(values) do
        fullType = tostring(fullType)
        local scriptItem = ScriptManager and ScriptManager.instance
            and ScriptManager.instance:FindItem(fullType) or nil
        output[#output + 1] = {
            id = fullType,
            label = scriptItem and scriptItem.getDisplayName
                and tostring(scriptItem:getDisplayName()) or fullType,
        }
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function addOptions(combo, values)
    combo.options = {}
    combo.selected = 0
    for _, option in ipairs(values or {}) do
        combo:addOptionWithData(option.label, option.id)
    end
end

local function runtimeItemFor(draft, slot)
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    if not inventory then return nil end
    for _, item in pairs(inventory.items or {}) do
        if item and tostring(item.wornSlot or "") == tostring(slot) then
            return item
        end
    end
    return nil
end

local function conflictWithDraft(window, location)
    local appearance = Appearance.Normalize(window.draft.appearance)
    for otherLocation, policy in pairs(appearance.slots or {}) do
        if tostring(otherLocation) ~= tostring(location)
            and policy.mode == "item" and policy.type
            and Appearance.AreExclusive
            and Appearance.AreExclusive(location,
                policy.wornSlot or otherLocation)
        then
            return tostring(otherLocation)
        end
    end
    return nil
end

ISPNCUniqueNPCAppearanceWindow = ISPanel:derive(
    "ISPNCUniqueNPCAppearanceWindow")

function ISPNCUniqueNPCAppearanceWindow:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCUniqueNPCAppearanceWindow:createChildren()
    ISPanel.createChildren(self)
    self.rows = {}
    self.topControls = {}
    self.voiceStyles = {}
    self.voiceEvents = {}
    self.syncing = false
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
    self:buildOutfitOptions()
    self:buildVoiceOptions()
    for _, location in ipairs(locations()) do self:addLocationRow(location) end
    self:syncFromDraft()
end

function ISPNCUniqueNPCAppearanceWindow:buildVoiceOptions()
    self.voiceStyles = voiceOptions(self.draft and self.draft.isFemale == true)
    local options = {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
    }
    for _, style in ipairs(self.voiceStyles) do
        options[#options + 1] = { id = style.id, label = style.label }
    end
    addOptions(self.voiceCombo, options)
    self.voiceEvents = AudioDebug and AudioDebug.GetVoiceEvents
        and AudioDebug.GetVoiceEvents() or {}
    local eventOptions = {}
    for _, event in ipairs(self.voiceEvents) do
        eventOptions[#eventOptions + 1] = {
            id = event.suffix,
            label = tostring(event.suffix) .. " ("
                .. tostring(event.category or "Voice") .. ")",
        }
    end
    addOptions(self.voiceSampleCombo, eventOptions)
    selectData(self.voiceSampleCombo, "ShoutHey")
end

function ISPNCUniqueNPCAppearanceWindow:buildOutfitOptions()
    local options = {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllOutfits) == "function" then
        local female = self.draft and self.draft.isFemale == true
        local ok, values = pcall(getAllOutfits, female)
        if ok and values and values.size then
            for index = 0, values:size() - 1 do
                local id = tostring(values:get(index))
                options[#options + 1] = { id = "named:" .. id, label = id }
            end
        end
    end
    addOptions(self.outfitCombo, options)
end

function ISPNCUniqueNPCAppearanceWindow:refreshGenderOptions()
    local survivor = self.draft and self.draft.identity
        and self.draft.identity.survivor or nil
    local tone = survivor and skinToneFromTexture(survivor.skinTexture)
        or "random"
    if survivor and tone ~= "random" and tone ~= "legacy" then
        -- HumanVisual texture names are gender-specific. Preserve the
        -- selected native tone when the General tab changes gender.
        survivor.skinTexture = skinTextureForTone(tone,
            self.draft.isFemale == true)
    end
    addOptions(self.skinModeCombo,
        skinToneOptions(self.draft and self.draft.isFemale == true))
    self:buildOutfitOptions()
    self:buildVoiceOptions()
    self:syncFromDraft()
end

function ISPNCUniqueNPCAppearanceWindow:addLocationRow(location)
    local row = { location = location, label = labelFor(location) }
    row.labelControl = ISLabel:new(0, 0, 24, row.label,
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    row.labelControl:initialise()
    self.content:addChild(row.labelControl)
    row.policy = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onPolicyChanged)
    row.policy:initialise()
    row.policy.bodyLocation = location
    addOptions(row.policy, {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
        { id = "item", label = tr("UI_PNC_UniqueNPCEditor_Selected", "Selected item") },
    })
    self.content:addChild(row.policy)
    row.item = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onItemChanged)
    row.item:initialise()
    row.item.bodyLocation = location
    addOptions(row.item, itemOptions(location))
    self.content:addChild(row.item)
    row.runtimeItem = runtimeItemFor(self.draft, location)
    self.rows[#self.rows + 1] = row
end

function ISPNCUniqueNPCAppearanceWindow:policy(location)
    local appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(self.draft and self.draft.appearance) or {}
    return appearance.slots and appearance.slots[location]
        or { mode = "random" }
end

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

function ISPNCUniqueNPCAppearanceWindow:markChanged()
    self.draft.appearanceAuthored = self.draft.appearanceAuthored or {}
    self.draft.appearanceAuthored.appearance = true
    self.draft._dirty = true
    if self.parentEditor and self.parentEditor.onAppearanceChanged then
        self.parentEditor:onAppearanceChanged()
    end
end

function ISPNCUniqueNPCAppearanceWindow:onPolicyChanged(combo)
    local location = combo and combo.bodyLocation
    if not location then return end
    local mode = comboData(combo) or "random"
    local appearance = Appearance.Normalize(self.draft.appearance)
    local previous = appearance.slots[location]
    local spec = { mode = mode }
    if mode == "item" then
        local item = runtimeItemFor(self.draft, location)
        local currentType = previous and previous.type
            or item and item.type
        spec.type = currentType
        spec.wornSlot = location
        spec.itemState = item and copy(item.itemState)
            or previous and copy(previous.itemState) or nil
        if not spec.type then
            mode = "none"
            spec.mode = mode
        end
    end
    if mode == "item" then
        local conflict = conflictWithDraft(self, location)
        if conflict then
            if self.parentEditor and self.parentEditor.setStatus then
                self.parentEditor:setStatus(
                    tr("UI_PNC_UniqueNPCEditor_ClothingConflict",
                        "Clothing conflicts with ") .. conflict)
            end
            self:syncFromDraft()
            return
        end
    end
    appearance.slots[location] = spec
    if mode == "item" or mode == "none" then
        -- A per-slot decision is more specific than a full named outfit.
        -- Keep the saved definition unambiguous and prevent the native preset
        -- from reintroducing clothing the author removed.
        appearance.outfit = { mode = "none" }
    end
    self.draft.appearance = appearance
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onItemChanged(combo)
    local location = combo and combo.bodyLocation
    local fullType = comboData(combo)
    if not location or not fullType then return end
    local conflict = conflictWithDraft(self, location)
    if conflict then
        if self.parentEditor and self.parentEditor.setStatus then
            self.parentEditor:setStatus(
                tr("UI_PNC_UniqueNPCEditor_ClothingConflict",
                    "Clothing conflicts with ") .. conflict)
        end
        self:syncFromDraft()
        return
    end
    local appearance = Appearance.Normalize(self.draft.appearance)
    local previous = appearance.slots[location] or {}
    local item = runtimeItemFor(self.draft, location)
    appearance.slots[location] = {
        mode = "item",
        type = fullType,
        wornSlot = location,
        itemState = item and item.type == fullType
            and copy(item.itemState) or copy(previous.itemState),
    }
    appearance.outfit = { mode = "none" }
    self.draft.appearance = appearance
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onOutfitChanged(combo)
    local value = comboData(combo) or "random"
    local appearance = Appearance.Normalize(self.draft.appearance)
    if string.sub(tostring(value), 1, 6) == "named:" then
        appearance.outfit = { mode = "item",
            id = string.sub(tostring(value), 7) }
    else
        appearance.outfit = { mode = tostring(value) }
    end
    self.draft.appearance = appearance
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:setVoiceDraft(profile)
    if not profile then return end
    self.draft.identity = self.draft.identity or { survivor = {} }
    self.draft.identity.survivor = self.draft.identity.survivor or {}
    self.draft.identity.survivor.voice = profile.prefix
    self.draft.identity.survivor.voicePrefix = profile.prefix
    self.draft.identity.survivor.voiceType = profile.voiceType
    self.draft.identity.survivor.voicePitch = profile.pitch
    local appearance = Appearance.Normalize(self.draft.appearance)
    appearance.voice = {
        mode = "item",
        prefix = profile.prefix,
        type = profile.voiceType,
        pitch = profile.pitch,
    }
    self.draft.appearance = appearance
end

function ISPNCUniqueNPCAppearanceWindow:onVoiceChanged(combo)
    if self.syncing then return end
    local selected = comboData(combo)
    if selected == "random" or selected == nil then
        local appearance = Appearance.Normalize(self.draft.appearance)
        appearance.voice = { mode = "random" }
        self.draft.appearance = appearance
        local survivor = self.draft.identity
            and self.draft.identity.survivor or nil
        if survivor then
            survivor.voice = nil
            survivor.voicePrefix = nil
            survivor.voiceType = nil
            survivor.voicePitch = nil
        end
        self.draft.appearanceAuthored.voice = true
        self.draft.appearanceAuthored.voicePrefix = true
        self.draft.appearanceAuthored.voiceType = true
        self.draft.appearanceAuthored.voicePitch = true
        self:markChanged()
        return
    end
    local style = self.voiceStyles and self.voiceStyles[tonumber(selected)] or nil
    if not style then return end
    self:setVoiceDraft({
        prefix = style.prefix,
        voiceType = style.voiceType,
        pitch = tonumber(self.draft.identity
            and self.draft.identity.survivor
            and self.draft.identity.survivor.voicePitch) or 0,
    })
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onVoicePitchChanged(value)
    if self.syncing then return end
    local appearance = Appearance.Normalize(self.draft.appearance)
    local voice = appearance.voice or {}
    if voice.mode ~= "item" then return end
    local pitch = math.max(-100, math.min(100, math.floor(tonumber(value) or 0)))
    voice.pitch = pitch
    appearance.voice = voice
    self.draft.appearance = appearance
    self.draft.identity.survivor.voicePitch = pitch
    if self.voicePitchValue and self.voicePitchValue.setName then
        self.voicePitchValue:setName(tostring(pitch))
    end
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onVoiceSampleChanged(combo)
    -- The sample is preview-only and never changes the authored definition.
end

function ISPNCUniqueNPCAppearanceWindow:onSkinModeChanged(combo)
    if self.syncing then return end
    local mode = comboData(combo) or "random"
    if mode == "legacy" then
        -- Legacy RGB values are still accepted when loading old drafts, but
        -- cannot be authored by this editor because the game stores skin as
        -- a texture/index choice.
        self:syncFromDraft()
        return
    end
    local survivor = self.draft.identity.survivor
    local texture = skinTextureForTone(mode, self.draft.isFemale == true)
    survivor.skinTexture = texture
    survivor.skinColor = nil
    self.draft.appearanceAuthored.skinTexture = true
    self.draft.appearanceAuthored.skinColor = true
    self:syncFromDraft()
    self:markChanged()
end

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

function ISPNCUniqueNPCAppearanceWindow:onResponsiveLayout()
    local scale = self.uiScale or 1
    local margin = Layout.Pixels(8, scale)
    local rect = {
        x = margin, y = margin,
        width = math.max(1, self.width - margin * 2),
        height = math.max(1, self.height - margin * 2),
    }
    local top = Layout.Flow(self.topControls, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = scale, minWidth = 90, gap = 6 })
    local contentY = top.bottom + Layout.Pixels(8, scale)
    local contentHeight = math.max(120,
        rect.y + rect.height - contentY)
    Layout.SetBounds(self.content, rect.x, contentY,
        rect.width, contentHeight)
    local rowHeight = Layout.Pixels(29, scale)
    local labelWidth = Layout.Pixels(150, scale)
    local gap = Layout.Pixels(6, scale)
    local policyWidth = Layout.Pixels(150, scale)
    local scrollWidth = self.content.vscroll and
        (self.content.vscroll.getWidth and self.content.vscroll:getWidth()
            or self.content.vscroll.width) or Layout.Pixels(18, scale)
    local innerWidth = math.max(Layout.Pixels(360, scale),
        rect.width - scrollWidth - gap)
    local itemX = labelWidth + policyWidth + gap * 2
    local itemWidth = math.max(Layout.Pixels(120, scale),
        innerWidth - labelWidth - policyWidth - gap * 2)
    local y = 8
    Layout.SetBounds(self.outfitLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.outfitCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voiceLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voiceCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voiceSampleLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voiceSampleCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voicePitchLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voicePitch, labelWidth + gap, y,
        math.max(Layout.Pixels(100, scale),
            innerWidth - labelWidth - gap - Layout.Pixels(46, scale)), rowHeight)
    Layout.SetBounds(self.voicePitchValue, innerWidth - Layout.Pixels(40, scale),
        y, Layout.Pixels(36, scale), rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.skinLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.skinModeCombo, labelWidth + gap, y,
        Layout.Pixels(180, scale), rowHeight)
    Layout.SetBounds(self.skinSwatch,
        labelWidth + gap + Layout.Pixels(192, scale), y,
        Layout.Pixels(29, scale), rowHeight)
    Layout.SetBounds(self.skinValue,
        labelWidth + gap + Layout.Pixels(230, scale), y,
        math.max(Layout.Pixels(120, scale),
            innerWidth - labelWidth - Layout.Pixels(230, scale)),
        rowHeight)
    y = y + rowHeight + gap
    for _, row in ipairs(self.rows) do
        Layout.SetBounds(row.labelControl, 0, y, labelWidth, rowHeight)
        Layout.SetBounds(row.policy, labelWidth + gap, y, policyWidth, rowHeight)
        Layout.SetBounds(row.item, itemX, y, itemWidth, rowHeight)
        y = y + rowHeight
    end
    self.content.contentHeight = math.max(contentHeight, y + rowHeight + gap)
    self.content:setScrollHeight(self.content.contentHeight)
    self.content.maxScroll = math.max(0,
        self.content.contentHeight - self.content.height)
    if self.content.vscroll then
        local barWidth = self.content.vscroll.getWidth
            and self.content.vscroll:getWidth() or self.content.vscroll.width or 16
        self.content.vscroll:setX(self.content.width - barWidth)
        self.content.vscroll:setHeight(self.content.height)
    end
    if self.content.onResize then self.content:onResize() end
end

function ISPNCUniqueNPCAppearanceWindow:render()
    ISPanel.render(self)
    if self.content then
        self.content:setScrollHeight(self.content.contentHeight or 0)
        self.content.maxScroll = math.max(0,
            (self.content.contentHeight or 0) - (self.content.height or 0))
        if self.content.getYScroll and self.content.setYScroll then
            self.content:setYScroll(math.max(-self.content.maxScroll,
                math.min(0, self.content:getYScroll())))
        end
    end
end

function ISPNCUniqueNPCAppearanceWindow:new(x, y, width, height, options)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

function AppearanceUI.Open(editor)
    if editor and editor.showTab then
        return editor:showTab("Appearance")
    end
    return nil
end

return AppearanceUI
