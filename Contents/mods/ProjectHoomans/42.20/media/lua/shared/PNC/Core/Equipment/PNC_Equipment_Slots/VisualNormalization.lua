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
    local tint
    if type(itemState) ~= "table" then return nil end
    if itemState.visualFullType ~= nil
        and tostring(itemState.visualFullType)
            ~= tostring(fullType or "")
    then
        return nil
    end
    if itemState.visualTintR ~= nil
        and itemState.visualTintG ~= nil
        and itemState.visualTintB ~= nil
    then
        tint = {
            r = tonumber(itemState.visualTintR) or 1,
            g = tonumber(itemState.visualTintG) or 1,
            b = tonumber(itemState.visualTintB) or 1,
        }
    end
    if itemState.visualBaseTexture == nil
        and itemState.visualTextureChoice == nil
        and itemState.visualDecal == nil
        and itemState.visualModelIndex == nil
        and itemState.visualColorR == nil
        and itemState.visualColorG == nil
        and itemState.visualColorB == nil
        and tint == nil
    then
        return nil
    end
    return {
        fullType = fullType and tostring(fullType) or nil,
        baseTexture = tonumber(itemState.visualBaseTexture),
        textureChoice = tonumber(itemState.visualTextureChoice),
        decal = itemState.visualDecal
            and tostring(itemState.visualDecal) or nil,
        tint = tint,
        modelIndex = tonumber(itemState.visualModelIndex),
        customColor = itemState.visualCustomColor == true,
        color = itemState.visualColorR ~= nil
            and itemState.visualColorG ~= nil
            and itemState.visualColorB ~= nil
            and {
                r = tonumber(itemState.visualColorR) or 1,
                g = tonumber(itemState.visualColorG) or 1,
                b = tonumber(itemState.visualColorB) or 1,
            }
            or nil,
    }
end

function Equipment.StoreVisualStateInItemState(item, visualState)
    local state
    local tint
    if type(item) ~= "table" or type(visualState) ~= "table" then
        return false
    end
    item.itemState = type(item.itemState) == "table"
        and item.itemState or {}
    state = item.itemState
    tint = visualState.tint
    state.visualFullType = visualState.fullType
        and tostring(visualState.fullType)
        or item.type and tostring(item.type)
        or nil
    state.visualBaseTexture = tonumber(visualState.baseTexture)
    state.visualTextureChoice = tonumber(visualState.textureChoice)
    state.visualDecal = visualState.decal
        and tostring(visualState.decal) or nil
    state.visualTintR = tint and tonumber(tint.r) or nil
    state.visualTintG = tint and tonumber(tint.g) or nil
    state.visualTintB = tint and tonumber(tint.b) or nil
    state.visualModelIndex = tonumber(visualState.modelIndex)
    state.visualCustomColor = visualState.customColor == true
        and true or nil
    state.visualColorR = visualState.color
        and tonumber(visualState.color.r) or nil
    state.visualColorG = visualState.color
        and tonumber(visualState.color.g) or nil
    state.visualColorB = visualState.color
        and tonumber(visualState.color.b) or nil
    return true
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

