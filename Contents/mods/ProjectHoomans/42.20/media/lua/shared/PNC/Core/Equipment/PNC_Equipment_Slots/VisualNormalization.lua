local VisualState = require "PsychopatzCore/Inventory/PsychopatzItemVisualState"

PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

local function normalizeVisualColor(source)
    if type(source) ~= "table" then
        return nil
    end
    return {
        r = tonumber(source.r) or 1,
        g = tonumber(source.g) or 1,
        b = tonumber(source.b) or 1,
    }
end

function Internal.NormalizeVisualState(source, fullType)
    local state = type(source) == "table" and source or nil
    if not state or not fullType
        or (
            state.fullType ~= nil
            and tostring(state.fullType) ~= tostring(fullType)
        )
    then
        return nil
    end
    return {
        fullType = tostring(fullType),
        baseTexture = tonumber(state.baseTexture),
        hue = tonumber(state.hue),
        textureChoice = tonumber(state.textureChoice),
        decal = Internal.NormalizeString(state.decal),
        tint = normalizeVisualColor(state.tint),
        modelIndex = tonumber(state.modelIndex),
        customColor = state.customColor == true,
        color = normalizeVisualColor(state.color),
    }
end

function Internal.NormalizeWornVisualMap(source, worn)
    local output = {}
    local location
    local state
    local fullType
    if type(source) ~= "table" then
        return output
    end
    for rawLocation, rawState in pairs(source) do
        location = Internal.NormalizeBodyLocation(rawLocation)
        state = type(rawState) == "table" and rawState or nil
        fullType = location and worn[location] or nil
        output[location] = Internal.NormalizeVisualState(state, fullType)
    end
    return output
end

function Equipment.VisualStateFromItemState(itemState, fullType)
    local state = VisualState.Read(itemState, fullType)
    if not state then return nil end
    state.customColor = state.customColor == true
    state.tint = normalizeVisualColor(state.tint)
    state.color = normalizeVisualColor(state.color)
    return state
end

function Equipment.StoreVisualStateInItemState(item, visualState)
    if type(item) ~= "table" or type(visualState) ~= "table" then return false end
    item.itemState = type(item.itemState) == "table" and item.itemState or {}
    return VisualState.Write(item.itemState, visualState, item.type)
end
