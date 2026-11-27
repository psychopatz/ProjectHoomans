-- Build 42 clothing-ripping rules for world-item bandage provisioning.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}
PNC.WorldItemContext.RipRules = PNC.WorldItemContext.RipRules or {}

local RipRules = PNC.WorldItemContext.RipRules

local FABRIC_RECIPES = {
    cotton = {
        outputType = "Base.RippedSheets",
        outputCount = 2,
        requiresScissors = false,
        usableForBandage = true,
    },
    denim = {
        outputType = "Base.DenimStrips",
        outputCount = 2,
        requiresScissors = true,
        usableForBandage = true,
    },
    leather = {
        outputType = "Base.LeatherStrips",
        outputCount = 2,
        requiresScissors = true,
        usableForBandage = true,
    },
}

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    if not ok then return nil end
    return value
end

local function isClothingObject(item, categoryStr)
    if instanceof then
        local ok, result = pcall(instanceof, item, "Clothing")
        if ok and result == true then return true end
    end
    return safeCall(item, "IsClothing") == true
        or (type(item) == "table" and item.isClothing == true)
        or categoryStr == "clothing"
end

function RipRules.InspectRippable(item, fullType, categoryStr, options)
    local favorite = safeCall(item, "isFavorite") == true
        or (type(item) == "table" and item.favorite == true)
    if favorite then return nil end
    local allowEquipped = type(options) == "table"
        and (options.allowEquipped == true or options.sourceType == "corpse")
    if not allowEquipped and safeCall(item, "isEquipped") == true then return nil end

    local fabricRaw = safeCall(item, "getFabricType")
        or (type(item) == "table" and item.fabricType) or nil
    local fabricKey = fabricRaw and string.lower(tostring(fabricRaw)) or nil

    local recipe = nil
    if isClothingObject(item, categoryStr) and fabricKey and FABRIC_RECIPES[fabricKey] then
        recipe = FABRIC_RECIPES[fabricKey]
    elseif fullType == "Base.Sheet" then
        recipe = {
            outputType = "Base.RippedSheets",
            outputCount = 4,
            requiresScissors = false,
            usableForBandage = true,
        }
        fabricKey = "cotton"
    end
    if not recipe then return nil end

    local dirtyness = tonumber(safeCall(item, "getDirtyness")) or 0
    local blood = tonumber(safeCall(item, "getBloodlevel"))
        or tonumber(safeCall(item, "getBloodLevel")) or 0
    return {
        canRip = true,
        fabricType = fabricKey,
        outputType = recipe.outputType,
        outputCount = recipe.outputCount,
        requiresScissors = recipe.requiresScissors == true,
        usableForBandage = recipe.usableForBandage == true,
        clean = dirtyness <= 0.1 and blood <= 0.1,
    }
end

return RipRules
