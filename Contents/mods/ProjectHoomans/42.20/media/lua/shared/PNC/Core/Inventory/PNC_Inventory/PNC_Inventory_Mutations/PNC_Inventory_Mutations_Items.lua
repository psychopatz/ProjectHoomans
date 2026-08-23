local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function addedWeight(spec)
    if type(spec) ~= "table" or not Internal.normalizeString(spec.type) then
        return nil
    end
    return Internal.getItemWeight(spec.type)
        * math.max(1,
            math.floor(tonumber(spec.stack) or tonumber(spec.uses) or 1))
end

function Inventory.CanAccept(record, specs, containerID)
    local inv = Inventory.EnsureRecordInventory(record)
    local weightState = Inventory.GetWeightState(record)
    local incomingWeight = 0
    local destination
    local destinationWeight
    local destinationMax
    local owner
    local destinationReduction = 0
    local hardMultiplier = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY_MULTIPLIER) or 3
    local hardCapacity = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY)
    local weight
    local index
    if not inv or type(specs) ~= "table" or #specs < 1 then
        return false, "items_missing"
    end
    containerID = Internal.normalizeString(containerID) or "root"
    destination = inv.containers[containerID]
    if not destination then return false, "container_not_found" end
    for index = 1, #specs do
        weight = addedWeight(specs[index])
        if not weight then return false, "invalid_item_spec" end
        incomingWeight = incomingWeight + weight
    end

    if containerID ~= "root" then
        destinationWeight = Internal.getContainerRawWeight(inv, containerID) or 0
        destinationMax = math.max(0, tonumber(destination.maxWeight) or 0)
        if destinationMax <= 0
            or destinationWeight + incomingWeight > destinationMax
        then
            return false, "container_full"
        end
        for _, candidate in pairs(inv.items or {}) do
            if candidate.bagContainer == containerID then
                owner = candidate
                break
            end
        end
        if owner and owner.wornSlot and inv.worn[owner.wornSlot] == owner.id then
            destinationReduction = math.max(0,
                math.min(1, tonumber(owner.weightReduction) or 0))
        end
    end

    if (tonumber(weightState.usedWeight) or 0)
        + (incomingWeight * (1 - destinationReduction))
        > (hardCapacity
            or ((tonumber(weightState.maxWeight) or 0) * hardMultiplier))
    then
        return false, "no_capacity"
    end
    return true, "accepted", incomingWeight
end

function Inventory.AddItems(record, specs, containerID, reason)
    containerID = Internal.normalizeString(containerID) or "root"
    local canAccept, acceptReason = Inventory.CanAccept(
        record,
        specs,
        containerID
    )
    local ops = {}
    local index
    local spec
    if not canAccept then return false, acceptReason, {} end
    local inv = Inventory.EnsureRecordInventory(record)
    if not inv.containers[containerID] then
        return false, "container_not_found", {}
    end
    for index = 1, #specs do
        spec = {}
        for key, value in pairs(specs[index]) do spec[key] = value end
        spec.container = containerID
        ops[#ops + 1] = { op = "add", item = spec }
    end
    local applied, appliedOps = Inventory.ApplyDelta(
        record,
        ops,
        reason or "inventory_add"
    )
    if not applied then return false, "add_failed", {} end
    local itemIDs = {}
    for index = 1, #appliedOps do
        if appliedOps[index].item and appliedOps[index].item.id then
            itemIDs[#itemIDs + 1] = appliedOps[index].item.id
        end
    end
    return true, "added", itemIDs
end

function Inventory.RemoveItems(record, itemIDs, reason)
    local inv = Inventory.EnsureRecordInventory(record)
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
    return true, "removed"
end

return Inventory
