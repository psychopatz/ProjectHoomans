local Inventory = PNC.Inventory
local Internal = Inventory.Internal

Internal.ItemWeightCache = Internal.ItemWeightCache or {}
Internal.ItemCapacityCache = Internal.ItemCapacityCache or {}
Internal.ItemContainerProfileCache =
    Internal.ItemContainerProfileCache or {}

function Internal.normalizeItemWeightReduction(value)
    value = tonumber(value) or 0
    if value > 1 then value = value / 100 end
    return math.max(0, math.min(1, value))
end

function Internal.createItemProbe(fullType)
    local item
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table"
            and not item.getActualWeight
            and item[1]
        then
            item = item[1]
        end
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
