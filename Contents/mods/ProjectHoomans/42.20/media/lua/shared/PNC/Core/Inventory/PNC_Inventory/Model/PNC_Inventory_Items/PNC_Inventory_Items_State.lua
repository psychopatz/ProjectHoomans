local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local SCALAR_FIELDS = {
    "condition",
    "headCondition",
    "quality",
    "haveBeenRepaired",
    "usedDelta",
    "favorite",
    "customName",
    "ammoCount",
    "fluidAmount",
    "fluidType",
    "fluidPrimaryType",
    "fluidCapacity",
    "fluidInputLocked",
    "fluidCanPlayerEmpty",
    "fluidRainCatcher",
    "age",
    "cooked",
    "burnt",
    "frozen",
    "freezingTime",
    "hungChange",
    "thirstChange",
    "dangerousUncooked",
    "poison",
    "poisonDetectionLevel",
    "poisonLevelForRecipe",
    "poisonPower",
    "rottenTime",
    "cookedInMicrowave",
    "tainted",
    "fertilized",
    "fertilizedTime",
    "heat",
    "lastCookMinute",
    "cookingTime",
    "foodLastAgedHours",
    "foodCreatedAtHours",
    "roundChambered",
    "jammed",
    "wetness",
    "bloodLevel",
    "dirtyness",
    "visualBaseTexture",
    "visualTextureChoice",
    "visualDecal",
    "visualTintR",
    "visualTintG",
    "visualTintB",
    "visualFullType",
    "visualModelIndex",
    "visualCustomColor",
    "visualColorR",
    "visualColorG",
    "visualColorB",
}

function Internal.boundedItemStateString(value)
    local limit
    local output
    if value == nil then return nil end
    output = tostring(value)
    limit = tonumber(PNC.Const
        and PNC.Const.INVENTORY_ITEM_STATE_MAX_STRING_LENGTH) or 1024
    if #output > limit then
        output = string.sub(output, 1, limit)
    end
    return output
end

function Internal.sanitizeItemStateScalar(value)
    local kind = type(value)
    if kind == "string" then
        return Internal.boundedItemStateString(value)
    end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil
        end
        return value
    end
    if kind == "boolean" then return value end
    return nil
end

local function collectSortedModData(raw)
    local entries = {}
    local key
    local value
    for key, value in pairs(raw or {}) do
        entries[#entries + 1] = {
            key = tostring(key),
            value = value,
        }
    end
    table.sort(entries, function(left, right)
        return left.key < right.key
    end)
    return entries
end

local function copyModData(raw)
    local output = {}
    local entries = collectSortedModData(raw)
    local maxKeys = tonumber(PNC.Const
        and PNC.Const.INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS) or 64
    local copied = 0
    local i
    local entry
    local value
    for i = 1, #entries do
        if copied >= maxKeys then break end
        entry = entries[i]
        value = Internal.sanitizeItemStateScalar(entry.value)
        if value ~= nil then
            output[Internal.boundedItemStateString(entry.key)] = value
            copied = copied + 1
        end
    end
    return copied > 0 and output or nil
end

local function copyFluidEntries(raw)
    local output = {}
    local maxEntries = 8
    local i
    local entry
    local fluidType
    local amount
    if type(raw) ~= "table" then return nil end
    for i = 1, math.min(#raw, maxEntries) do
        entry = raw[i]
        if type(entry) == "table" then
            fluidType = Internal.boundedItemStateString(entry.type)
            amount = Internal.sanitizeItemStateScalar(entry.amount)
            if fluidType and fluidType ~= "" and amount and amount >= 0 then
                output[#output + 1] = { type = fluidType, amount = amount }
            end
        end
    end
    return #output > 0 and output or nil
end

function Internal.sanitizeItemState(raw)
    local output = {}
    local i
    local field
    local value
    if type(raw) ~= "table" then return output end
    for i = 1, #SCALAR_FIELDS do
        field = SCALAR_FIELDS[i]
        value = Internal.sanitizeItemStateScalar(raw[field])
        if value ~= nil then output[field] = value end
    end
    if type(raw.modData) == "table" then
        output.modData = copyModData(raw.modData)
    end
    output.fluids = copyFluidEntries(raw.fluids)
    return output
end

function Internal.sanitizeNetworkItemState(raw, item)
    local exclude = {}
    item = type(item) == "table" and item or {}
    if item.cond ~= nil then exclude.condition = true end
    if item.uses ~= nil then exclude.usedDelta = true end
    if item.fav == true then exclude.favorite = true end
    if item.customName ~= nil then exclude.customName = true end
    if item.ammoCount ~= nil then exclude.ammoCount = true end
    return Portable.ProjectNetworkState(raw, {
        exclude = exclude, fullType = item.type,
    })
end

function Inventory.SanitizeItemState(raw)
    return Internal.sanitizeItemState(raw)
end
