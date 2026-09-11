local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Defaults = require
    "PsychopatzCore/Inventory/PsychopatzItemStateDefaults"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

Internal.ItemWeightCache = Internal.ItemWeightCache or {}
Internal.ItemCapacityCache = Internal.ItemCapacityCache or {}
Internal.ItemContainerProfileCache =
    Internal.ItemContainerProfileCache or {}
Internal.ItemFoodProfileCache = Internal.ItemFoodProfileCache or {}
Internal.ItemDefinitionStateCache = Internal.ItemDefinitionStateCache or {}
Internal.ItemDefinitionProfileCache = Internal.ItemDefinitionProfileCache or {}
Internal.FoodProfileProvider = Internal.FoodProfileProvider or nil

function Internal.normalizeItemWeightReduction(value)
    value = tonumber(value) or 0
    if value > 1 then value = value / 100 end
    return math.max(0, math.min(1, value))
end

function Internal.createItemProbe(fullType)
    local item
    local ok
    if PNC.Equipment and PNC.Equipment.CreateItem then
        ok, item = pcall(PNC.Equipment.CreateItem, fullType)
        if not ok then item = nil end
    end
    if not item and rawget(_G, "instanceItem") then
        ok, item = pcall(instanceItem, fullType)
        if not ok then item = nil end
    end
    if not item and rawget(_G, "InventoryItemFactory")
        and InventoryItemFactory.CreateItem
    then
        ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if not ok then item = nil end
    end
    if type(item) == "table"
        and not item.getActualWeight
        and item[1]
    then
        item = item[1]
    end
    return item
end

local function readContainerProfile(item, capacity, reduction, wearableSlot)
    if item and item.getMaxCapacity then
        capacity = tonumber(item:getMaxCapacity()) or capacity
    elseif item and item.getCapacity then
        capacity = tonumber(item:getCapacity()) or capacity
    end
    if item and item.getWeightReduction then
        reduction = Internal.normalizeItemWeightReduction(
            item:getWeightReduction()
        )
    end
    if item and item.canBeEquipped then
        wearableSlot = Internal.normalizeString(item:canBeEquipped())
    end
    return capacity, reduction, wearableSlot
end

local function readScriptProfile(fullType, capacity, reduction, wearableSlot)
    local scriptItem
    if not getScriptManager or not getScriptManager().getItem then
        return capacity, reduction, wearableSlot
    end
    scriptItem = getScriptManager():getItem(fullType)
    if capacity <= 0 and scriptItem and scriptItem.getCapacity then
        capacity = tonumber(scriptItem:getCapacity()) or capacity
    end
    if reduction <= 0 and scriptItem and scriptItem.getWeightReduction then
        reduction = Internal.normalizeItemWeightReduction(
            scriptItem:getWeightReduction()
        )
    end
    if not wearableSlot
        and scriptItem
        and scriptItem.getCanBeEquipped
    then
        wearableSlot = Internal.normalizeString(
            scriptItem:getCanBeEquipped()
        )
    end
    return capacity, reduction, wearableSlot
end

function Internal.getContainerProfile(fullType)
    local cached = Internal.ItemContainerProfileCache[fullType]
    local capacity = 0
    local reduction = 0
    local wearableSlot
    if cached ~= nil then return cached end
    capacity, reduction, wearableSlot = readContainerProfile(
        Internal.createItemProbe(fullType),
        capacity,
        reduction,
        wearableSlot
    )
    capacity, reduction, wearableSlot = readScriptProfile(
        fullType,
        capacity,
        reduction,
        wearableSlot
    )
    cached = {
        capacity = math.max(0, capacity),
        weightReduction = reduction,
        wearableSlot = wearableSlot,
    }
    Internal.ItemContainerProfileCache[fullType] = cached
    return cached
end

function Inventory.GetContainerProfile(fullType)
    local profile = Internal.getContainerProfile(fullType)
    return {
        capacity = profile.capacity,
        weightReduction = profile.weightReduction,
        wearableSlot = profile.wearableSlot,
    }
end

local function profileNumber(item, scriptItem, methodName)
    local value = Util.call(item, methodName)
    if value == nil then value = Util.call(scriptItem, methodName) end
    value = tonumber(value)
    return value
end

local function profileString(item, scriptItem, methodName)
    local value = Util.call(item, methodName)
    if value == nil then value = Util.call(scriptItem, methodName) end
    value = value and tostring(value) or nil
    return value ~= "" and value or nil
end

function Inventory.RegisterFoodProfileProvider(callback)
    Internal.FoodProfileProvider = type(callback) == "function"
        and callback or nil
    Internal.ItemFoodProfileCache = {}
end

function Internal.getFoodProfile(fullType)
    fullType = Internal.normalizeString(fullType)
    if not fullType then return nil end
    local cached = Internal.ItemFoodProfileCache[fullType]
    local provided
    local item
    local scriptItem
    local typeString
    local isFood
    if cached ~= nil then return cached end
    if Internal.FoodProfileProvider then
        local ok
        ok, provided = pcall(Internal.FoodProfileProvider, fullType)
        if ok and type(provided) == "table" then
            Internal.ItemFoodProfileCache[fullType] = provided
            return provided
        end
    end
    item = Internal.createItemProbe(fullType)
    scriptItem = getScriptManager and getScriptManager().getItem
        and getScriptManager():getItem(fullType) or nil
    typeString = tostring(Util.call(item, "getTypeString") or "")
    if typeString == "" then
        typeString = tostring(Util.call(scriptItem, "getTypeString") or "")
    end
    isFood = typeString:lower() == "food"
        or Util.call(item, "isFood") == true
        or Util.call(item, "IsFood") == true
        or item and item.isFood == true
        or Util.call(item, "getAge") ~= nil
    if not isFood then
        cached = { food = false, fullType = fullType }
    else
        cached = {
            food = true,
            fullType = fullType,
            offAge = profileNumber(item, scriptItem, "getOffAge"),
            offAgeMax = profileNumber(item, scriptItem, "getOffAgeMax"),
            replaceOnRotten = profileString(
                item, scriptItem, "getReplaceOnRotten"
            ),
        }
    end
    Internal.ItemFoodProfileCache[fullType] = cached
    return cached
end

function Inventory.GetFoodProfile(fullType)
    return Internal.getFoodProfile(fullType)
end

function Internal.getItemDefinitionProfile(fullType)
    local cached
    local item
    fullType = Internal.normalizeString(fullType)
    if not fullType then return nil end
    cached = Internal.ItemDefinitionProfileCache[fullType]
    if cached ~= nil then return cached or nil end
    item = Internal.createItemProbe(fullType)
    if not item then
        Internal.ItemDefinitionProfileCache[fullType] = false
        return nil
    end
    cached = Profiles.ClassifyNative(item)
    Internal.ItemDefinitionProfileCache[fullType] = cached
    return cached
end

function Inventory.GetItemDefinitionProfile(fullType)
    return Util.copy(Internal.getItemDefinitionProfile(fullType))
end

local function copyKnown(source, target, fields)
    local i
    local field
    local value
    for i = 1, #fields do
        field = fields[i]
        value = source and source[field]
        if value ~= nil then target[field] = Util.copy(value) end
    end
end

local function sameNumber(left, right)
    left, right = tonumber(left), tonumber(right)
    return left ~= nil and right ~= nil
        and math.abs(left - right) <= 0.000001
end

-- Build one immutable baseline from the PZ definition/probe.  Instance
-- records never store this table; it is cached by full type and used only to
-- remove or resolve deviations.
function Internal.getItemDefinitionState(fullType)
    fullType = Internal.normalizeString(fullType)
    local cached
    local item
    local state = {}
    local fluid
    local food
    local profile
    local capabilities
    local value
    if not fullType then return nil end
    cached = Internal.ItemDefinitionStateCache[fullType]
    if cached ~= nil then return cached end
    item = Internal.createItemProbe(fullType)
    if not item then
        Internal.ItemDefinitionStateCache[fullType] = false
        return nil
    end

    profile = Profiles.ClassifyNative(item)
    capabilities = profile.capabilities or {}

    if capabilities.condition then
        value = Util.call(item, "getConditionMax")
        if value ~= nil then state.condition = tonumber(value) end
    end
    if capabilities.uses then
        value = Util.call(item, "getUsedDelta")
        if value ~= nil then state.usedDelta = tonumber(value) end
    end

    if capabilities.fluid then fluid = Portable.CaptureFluid(item) end
    if fluid then
        copyKnown(fluid, state, {
            "fluidAmount", "fluidCapacity", "fluidPrimaryType",
            "fluidInputLocked", "fluidCanPlayerEmpty", "fluidRainCatcher",
            "fluids",
        })
    end

    profile = Internal.getFoodProfile(fullType)
    if capabilities.food and profile and profile.food == true then
        food = Portable.CaptureFood(item)
        copyKnown(food, state, {
            "age", "cooked", "burnt", "frozen", "freezingTime",
            "hungChange", "thirstChange", "dangerousUncooked", "poison",
            "poisonDetectionLevel", "poisonLevelForRecipe", "poisonPower",
            "rottenTime", "cookedInMicrowave", "tainted", "fertilized",
            "fertilizedTime", "heat", "lastCookMinute", "cookingTime",
        })
    end

    if capabilities.ammo then
        value = Util.call(item, "getCurrentAmmoCount")
        if value ~= nil then state.ammoCount = tonumber(value) end
        value = Util.call(item, "isRoundChambered")
        if value ~= nil then state.roundChambered = value == true end
        value = Util.call(item, "isJammed")
        if value ~= nil then state.jammed = value == true end
    end
    if capabilities.clothing then
        value = Util.call(item, "getWetness")
        if value ~= nil then state.wetness = tonumber(value) end
        value = Util.call(item, "getBloodlevel")
        if value == nil then value = Util.call(item, "getBloodLevel") end
        if value ~= nil then state.bloodLevel = tonumber(value) end
        value = Util.call(item, "getDirtiness")
        if value ~= nil then state.dirtyness = tonumber(value) end
    end

    if Internal.countMapEntries(state) <= 0 then
        Internal.ItemDefinitionStateCache[fullType] = false
        return nil
    end
    Internal.ItemDefinitionStateCache[fullType] = state
    return state
end

function Inventory.GetItemDefinitionState(fullType)
    return Util.copy(Internal.getItemDefinitionState(fullType))
end

-- Canonicalize incoming abstract state against the PZ baseline.  Zero and
-- false are retained when they differ; absent fields continue to mean the
-- default.  The old full-water seed is deliberately not recreated.
function Inventory.NormalizeItemState(item)
    local raw
    local delta
    local normalized
    local fullType
    local before
    local beforeUses
    local definition
    if type(item) ~= "table" then return false end
    fullType = Internal.normalizeItemType(item.type)
    raw = Internal.sanitizeItemState(item.itemState)
    beforeUses = item.uses
    if fullType == "Base.WaterBottle" and item.uses ~= nil
        and tonumber(item.uses) == 0
        and Internal.countMapEntries(raw) <= 0
    then
        raw.fluidAmount = 0
        item.uses = nil
    end
    definition = Internal.getItemDefinitionState(fullType)
    if definition then
        if sameNumber(item.uses, definition.usedDelta) then
            item.uses = nil
        end
        if sameNumber(item.cond, definition.condition) then
            item.cond = nil
        end
        if sameNumber(item.ammoCount, definition.ammoCount) then
            item.ammoCount = nil
        end
    end
    before = Util.canonical(raw)
    delta = Defaults.Diff(fullType, raw)
    normalized = Internal.sanitizeItemState(delta)
    if Internal.countMapEntries(normalized) <= 0 then
        item.itemState = nil
    else
        item.itemState = normalized
    end
    return before ~= Util.canonical(item.itemState or {})
        or beforeUses ~= item.uses
end

function Inventory.ResolveItemState(item)
    if type(item) ~= "table" then return {} end
    return Defaults.Effective(item)
end

Defaults.RegisterProvider(function(fullType)
    return Internal.getItemDefinitionState(fullType)
end, 1)

Profiles.RegisterProvider(function(fullType)
    return Internal.getItemDefinitionProfile(fullType)
end, 1)

function Internal.getItemWeight(fullType)
    local cached = Internal.ItemWeightCache[fullType]
    local item
    if cached ~= nil then return cached end
    cached = 0.1
    item = Internal.createItemProbe(fullType)
    if item and item.getActualWeight then
        cached = tonumber(item:getActualWeight()) or cached
    elseif item and item.getWeight then
        cached = tonumber(item:getWeight()) or cached
    elseif getScriptManager and getScriptManager().getItem then
        item = getScriptManager():getItem(fullType)
        if item and item.getActualWeight then
            cached = tonumber(item:getActualWeight()) or cached
        elseif item and item.getWeight then
            cached = tonumber(item:getWeight()) or cached
        end
    end
    Internal.ItemWeightCache[fullType] = math.max(0, cached)
    return Internal.ItemWeightCache[fullType]
end

function Internal.getItemCapacity(fullType)
    local cached = Internal.ItemCapacityCache[fullType]
    if cached ~= nil then return cached end
    Internal.ItemCapacityCache[fullType] =
        Internal.getContainerProfile(fullType).capacity
    return Internal.ItemCapacityCache[fullType]
end
