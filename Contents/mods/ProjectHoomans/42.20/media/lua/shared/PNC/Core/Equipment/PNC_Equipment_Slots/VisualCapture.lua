PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

local function readVisualValue(visual, methodName, ...)
    local method
    local ok
    local value
    if not visual then return nil end
    method = visual[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, visual, ...)
    return ok and value or nil
end

function Internal.VisualStateSignature(state)
    local tint = state and state.tint or {}
    local color = state and state.color or {}
    return table.concat({
        tostring(state and state.fullType or ""),
        tostring(state and state.baseTexture or ""),
        tostring(state and state.textureChoice or ""),
        tostring(state and state.decal or ""),
        tostring(tint.r or ""),
        tostring(tint.g or ""),
        tostring(tint.b or ""),
        tostring(state and state.modelIndex or ""),
        tostring(state and state.customColor == true),
        tostring(color.r or ""),
        tostring(color.g or ""),
        tostring(color.b or ""),
    }, ":")
end

function Equipment.CaptureItemVisualState(item, fullType)
    local visual
    local clothingItem
    local tint
    local modelIndex
    local customColor
    local color
    if not item then return nil end
    visual = item.getVisual and item:getVisual() or nil
    clothingItem = item.getClothingItem
        and item:getClothingItem() or nil
    tint = visual and readVisualValue(
        visual, "getTint", clothingItem
    ) or nil
    modelIndex = item.getModelIndex
        and tonumber(item:getModelIndex()) or nil
    customColor = item.isCustomColor
        and item:isCustomColor() == true or false
    if item.getColorRed
        and item.getColorGreen
        and item.getColorBlue
    then
        color = {
            r = tonumber(item:getColorRed()),
            g = tonumber(item:getColorGreen()),
            b = tonumber(item:getColorBlue()),
        }
    end
    return {
        fullType = fullType
            or item.getFullType
                and tostring(item:getFullType())
            or nil,
        baseTexture = visual and tonumber(readVisualValue(
            visual, "getBaseTexture"
        )) or nil,
        textureChoice = visual and tonumber(readVisualValue(
            visual, "getTextureChoice"
        )) or nil,
        decal = visual and readVisualValue(
            visual, "getDecal", clothingItem
        ) or nil,
        tint = tint and {
            r = tonumber(tint:getRedFloat()),
            g = tonumber(tint:getGreenFloat()),
            b = tonumber(tint:getBlueFloat()),
        } or nil,
        modelIndex = modelIndex,
        customColor = customColor,
        color = color,
    }
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

