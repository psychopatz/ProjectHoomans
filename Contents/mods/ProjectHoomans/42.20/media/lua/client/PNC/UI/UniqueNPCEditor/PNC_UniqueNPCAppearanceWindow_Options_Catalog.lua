local AppearanceUI = PNC.UniqueNPCAppearanceUI
local Internal = AppearanceUI.Internal or {}
local Appearance = Internal.Appearance
local AudioDebug = Internal.AudioDebug
local tr = Internal.tr
local listValues = Internal.listValues

local function voiceOptions(isFemale)
    local output = {}
    local raw
    local values
    local bodyType = isFemale and 1 or 2
    if type(getAllVoiceStyles) == "function" then
        raw = getAllVoiceStyles()
    end
    values = listValues(raw)
    for _, style in ipairs(values) do
        local prefix = style:getPrefix()
        local name = style:getName()
        local styleBodyType = tonumber(style:getBodyTypeDefault())
        local styleType = tonumber(style:getVoiceType()) or 0
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



Internal.voiceOptions = voiceOptions
Internal.skinToneOptions = skinToneOptions
Internal.skinTextureForTone = skinTextureForTone
Internal.skinToneFromTexture = skinToneFromTexture
Internal.skinToneColor = skinToneColor
Internal.skinToneLabel = skinToneLabel
Internal.locations = locations
Internal.labelFor = labelFor
Internal.itemOptions = itemOptions
Internal.addOptions = addOptions
Internal.runtimeItemFor = runtimeItemFor
Internal.conflictWithDraft = conflictWithDraft
AppearanceUI.Internal = Internal
