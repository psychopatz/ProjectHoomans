local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function addedWeight(spec)
    if type(spec) ~= "table" or not Internal.normalizeString(spec.type) then
        return nil
    end
    return Internal.getItemWeight(spec.type)
        * math.max(1,
            math.floor(tonumber(spec.stack) or 1))
end

local function resolveHardCapacity(record, weightState)
    local hardMultiplier = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY_MULTIPLIER) or 3
    local baseHardCap = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY)
    local multiplier = Internal.resolveCapacityMultiplier
        and Internal.resolveCapacityMultiplier() or 1.0
    local bonus = Internal.resolveCapacityBonus
        and Internal.resolveCapacityBonus(record) or 0
    local scaledMax = (tonumber(weightState and weightState.maxWeight) or 0)
        * hardMultiplier
    if baseHardCap then
        local scaledHardCap = (baseHardCap + bonus) * multiplier
        return math.max(scaledHardCap, scaledMax)
    end
    return scaledMax
end

function Inventory.CanAccept(record, specs, containerID, options)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local weightState = Inventory.GetWeightState(record)
    if not inv or type(specs) ~= "table" or #specs < 1 then
        return false, "items_missing"
    end
    local plan, planReason = Internal.planContainerPlacement(
        inv, specs, containerID, options
    )
    if not plan then return false, planReason end
    local hardLimit = resolveHardCapacity(record, weightState)
    if (tonumber(weightState.usedWeight) or 0)
        + (tonumber(plan.effectiveAddedWeight) or 0)
        > hardLimit
    then
        return false, "no_capacity"
    end
    return true, "accepted", plan.rawAddedWeight, plan
end

function Inventory.AddItems(record, specs, containerID, reason, options)
    options = type(options) == "table" and options or {}
    local canAccept, acceptReason, _, plan = Inventory.CanAccept(
        record,
        specs,
        containerID,
        options
    )
    local ops = {}
    local index
    local spec
    if not canAccept then return false, acceptReason, {} end
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    for index = 1, #specs do
        local destID = plan and plan.assignments and plan.assignments[index]
            or Internal.normalizeString(containerID) or "root"
        if not inv.containers[destID] then
            return false, "container_not_found", {}
        end
        spec = {}
        for key, value in pairs(specs[index]) do spec[key] = value end
        spec.container = destID
        ops[#ops + 1] = { op = "add", item = spec }
    end
    local applied, appliedOps = Inventory.ApplyDelta(
        record,
        ops,
        reason or "inventory_add"
    )
    if not applied then return false, "add_failed", {} end
    if Inventory.ReconcileWaterContainer then
        Inventory.ReconcileWaterContainer(record)
    end
    local itemIDs = {}
    local hasWearableBag = false
    for index = 1, #appliedOps do
        local added = appliedOps[index].item
        if added and added.id then
            itemIDs[#itemIDs + 1] = added.id
            if added.bagContainer and added.wearableSlot then
                hasWearableBag = true
            end
        end
    end
    if hasWearableBag
        and options.autoEquipBags ~= false
        and Inventory.ReconcileBestBags
    then
        Inventory.ReconcileBestBags(
            record,
            (reason or "inventory_add") .. "_auto_equip_bag",
            { candidateIDs = itemIDs }
        )
    end
    return true, "added", itemIDs
end

function Inventory.RemoveItems(record, itemIDs, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local ops = {}
    local seen = {}
    local index
    local itemID
    if not inv or type(itemIDs) ~= "table" or #itemIDs < 1 then
        return false, "items_missing"
    end
    for index = 1, #itemIDs do
        itemID = Internal.normalizeString(itemIDs[index])
        if not itemID or seen[itemID] or not inv.items[itemID] then
            return false, "item_not_found"
        end
        seen[itemID] = true
        ops[#ops + 1] = { op = "remove", itemID = itemID }
    end
    if not Inventory.ApplyDelta(record, ops, reason or "inventory_remove") then
        return false, "remove_failed"
    end
    if Inventory.ReconcileWaterContainer then
        Inventory.ReconcileWaterContainer(record)
    end
    return true, "removed"
end

return Inventory
