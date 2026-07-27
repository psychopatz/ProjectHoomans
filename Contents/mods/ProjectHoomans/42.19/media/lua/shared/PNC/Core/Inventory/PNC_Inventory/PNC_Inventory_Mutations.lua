--[[
    PNC Inventory Mutations
    Validated add/move/remove/update operations and revision logging.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function applyAddOperation(record, inv, op)
    local item
    if type(op.item) ~= "table" then
        return nil
    end
    item = Internal.createItem(record, inv, op.item)
    if not item then
        return nil
    end
    return Internal.buildOperation("add", {
        item = Internal.itemToPayload(item),
        container = item.container,
    })
end

local function applyMoveOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local destination = Internal.normalizeString(op.to)
    local item
    if not itemID or not destination then
        return nil
    end
    item = inv.items[op.itemID]
    if not item or not Internal.setItemContainer(inv, item, op.to) then
        return nil
    end
    return Internal.buildOperation("move", {
        itemID = item.id,
        to = item.container,
    })
end

local function applyRemoveOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    if not itemID or not inv.items[op.itemID] or not Internal.removeItemByID(inv, op.itemID) then
        return nil
    end
    return Internal.buildOperation("remove", { itemID = op.itemID })
end

local function applyUpdateOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local item = itemID and inv.items[op.itemID] or nil
    if not item then
        return nil
    end
    if op.stack ~= nil then
        item.stack = math.max(1, math.floor(tonumber(op.stack) or item.stack or 1))
    end
    if op.uses ~= nil then
        item.uses = tonumber(op.uses)
    end
    if op.cond ~= nil then
        item.cond = tonumber(op.cond)
    end
    if op.ammoCount ~= nil then
        item.ammoCount = math.max(0, math.floor(tonumber(op.ammoCount) or item.ammoCount or 0))
    end
    return Internal.buildOperation("update", {
        itemID = item.id,
        stack = item.stack,
        uses = item.uses,
        cond = item.cond,
        ammoCount = item.ammoCount,
    })
end

local function applyInventoryOperation(record, inv, op)
    if type(op) ~= "table" then
        return nil
    end
    if op.op == "add" then
        return applyAddOperation(record, inv, op)
    end
    if op.op == "move" then
        return applyMoveOperation(inv, op)
    end
    if op.op == "remove" then
        return applyRemoveOperation(inv, op)
    end
    if op.op == "update" then
        return applyUpdateOperation(inv, op)
    end
    return nil
end

function Inventory.ApplyDelta(record, ops, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local appliedOps = {}
    local applied
    local i
    if type(ops) ~= "table" then
        return false, {}
    end
    for i = 1, #ops do
        applied = applyInventoryOperation(record, inv, ops[i])
        if applied then
            appliedOps[#appliedOps + 1] = applied
        end
    end
    if #appliedOps <= 0 then
        return false, {}
    end
    Internal.bumpRevision(record, appliedOps, reason)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true, appliedOps
end

local function addedWeight(spec)
    if type(spec) ~= "table" or not Internal.normalizeString(spec.type) then
        return nil
    end
    return Internal.getItemWeight(spec.type)
        * math.max(1, math.floor(tonumber(spec.stack) or tonumber(spec.uses) or 1))
end

function Inventory.CanAccept(record, specs)
    local inv = Inventory.EnsureRecordInventory(record)
    local weightState = Inventory.GetWeightState(record)
    local incomingWeight = 0
    local incomingCapacity = 0
    local weight
    local index
    if not inv or type(specs) ~= "table" or #specs < 1 then
        return false, "items_missing"
    end
    for index = 1, #specs do
        weight = addedWeight(specs[index])
        if not weight then
            return false, "invalid_item_spec"
        end
        incomingWeight = incomingWeight + weight
        incomingCapacity = incomingCapacity
            + math.max(0, tonumber(specs[index].maxWeight) or 0)
    end
    if (tonumber(weightState.usedWeight) or 0) + incomingWeight
        > (tonumber(weightState.maxWeight) or 0) + incomingCapacity
    then
        return false, "no_capacity"
    end
    return true, "accepted", incomingWeight
end

function Inventory.AddItems(record, specs, containerID, reason)
    local canAccept, acceptReason = Inventory.CanAccept(record, specs)
    local ops = {}
    local index
    local spec
    if not canAccept then
        return false, acceptReason, {}
    end
    containerID = Internal.normalizeString(containerID) or "root"
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
    if not applied then
        return false, "add_failed", {}
    end
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

function Inventory.SetEquipped(record, slot, itemID, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local previousID
    local previous
    local item
    local op
    local oldSlot
    slot = Internal.normalizeString(slot)
    if slot ~= "primary" and slot ~= "secondary" and slot ~= "bag" then
        return false, "invalid_equip_slot"
    end
    if not inv then return false, "inventory_unavailable" end
    itemID = Internal.normalizeString(itemID)
    item = itemID and inv.items[itemID] or nil
    if itemID and not item then return false, "item_not_found" end
    previousID = inv.equipped and inv.equipped[slot] or nil
    if previousID == itemID then return true, "unchanged" end
    previous = previousID and inv.items[previousID] or nil
    if previous then previous.equipSlot = nil end
    oldSlot = item and item.equipSlot or nil
    if oldSlot and oldSlot ~= slot and inv.equipped[oldSlot] == itemID then
        inv.equipped[oldSlot] = nil
    end
    if item then item.equipSlot = slot end
    inv.equipped[slot] = itemID
    op = Internal.buildOperation("equip", {
        slot = slot,
        itemID = itemID,
        previousItemID = previousID,
        oldSlot = oldSlot,
    })
    Internal.bumpRevision(record, { op }, reason or ("equip_" .. slot))
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true, item and ("equipped_" .. slot) or (slot .. "_cleared")
end

function Inventory.EquipPrimary(record, itemID, reason)
    return Inventory.SetEquipped(record, "primary", itemID, reason)
end

function Inventory.SetWorn(record, itemID, wornSlot, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local item
    local previousItemID
    local previous
    local oldSlot
    local op
    if not inv then return false, "inventory_unavailable" end
    itemID = Internal.normalizeString(itemID)
    wornSlot = Internal.normalizeString(wornSlot)
    item = itemID and inv.items[itemID] or nil
    if itemID and not item then return false, "item_not_found" end
    if itemID and not wornSlot then return false, "worn_slot_missing" end

    if item then
        oldSlot = item.wornSlot
        if oldSlot and inv.worn[oldSlot] == itemID then
            inv.worn[oldSlot] = nil
        end
        previousItemID = inv.worn[wornSlot]
        previous = previousItemID and inv.items[previousItemID] or nil
        if previous then previous.wornSlot = nil end
        inv.worn[wornSlot] = itemID
        item.wornSlot = wornSlot
    else
        previousItemID = inv.worn[wornSlot]
        previous = previousItemID and inv.items[previousItemID] or nil
        if previous then previous.wornSlot = nil end
        inv.worn[wornSlot] = nil
    end

    op = Internal.buildOperation("wear", {
        slot = wornSlot,
        itemID = itemID,
        previousItemID = previousItemID,
        oldSlot = oldSlot,
    })
    Internal.bumpRevision(record, { op }, reason or "inventory_wear")
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true, item and "worn" or "removed"
end

function Inventory.ClearWorn(record, itemID, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local item = inv and inv.items and inv.items[Internal.normalizeString(itemID)] or nil
    if not item then return false, "item_not_found" end
    if not item.wornSlot then return true, "unchanged" end
    return Inventory.SetWorn(record, nil, item.wornSlot, reason or "inventory_unwear")
end
