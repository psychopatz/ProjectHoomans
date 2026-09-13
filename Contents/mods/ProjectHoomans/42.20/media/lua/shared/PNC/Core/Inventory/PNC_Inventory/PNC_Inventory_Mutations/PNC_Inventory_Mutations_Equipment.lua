local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function preserveWornItemVisual(record, inv, wornSlot)
    local itemID = wornSlot and inv and inv.worn
        and inv.worn[wornSlot] or nil
    local item = itemID and inv.items and inv.items[itemID] or nil
    local visual = record and record.equipment
        and record.equipment.wornVisuals
        and record.equipment.wornVisuals[wornSlot] or nil
    if item and visual and PNC.Equipment
        and PNC.Equipment.StoreVisualStateInItemState
    then
        PNC.Equipment.StoreVisualStateInItemState(item, visual)
    end
end

function Inventory.SetEquipped(record, slot, itemID, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
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

-- Water is a logical utility slot. It is deliberately not mirrored into the
-- hand loadout, so equipping a bottle never disarms the NPC's weapon.
function Inventory.SetWaterContainer(record, itemID, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local previousID
    local previous
    local item
    local oldSlot
    local op
    if not inv then return false, "inventory_unavailable" end
    itemID = Internal.normalizeString(itemID)
    item = itemID and inv.items[itemID] or nil
    if itemID and not item then return false, "item_not_found" end
    if itemID and Inventory.IsWaterContainer
        and not Inventory.IsWaterContainer(item)
    then
        return false, "item_not_water_container"
    end
    if item and (item.interactionLocked or item.wornSlot or item.attachedSlot) then
        return false, "item_not_available"
    end
    previousID = inv.equipped and inv.equipped.waterContainer or nil
    if previousID == itemID and (not item or item.equipSlot == "waterContainer") then
        return true, "unchanged"
    end
    previous = previousID and inv.items[previousID] or nil
    if previous and previous.equipSlot == "waterContainer" then
        previous.equipSlot = nil
    end
    oldSlot = item and item.equipSlot or nil
    if oldSlot and inv.equipped[oldSlot] == itemID then
        inv.equipped[oldSlot] = nil
    end
    if item then item.equipSlot = "waterContainer" end
    inv.equipped.waterContainer = itemID
    op = Internal.buildOperation("equip", {
        slot = "waterContainer",
        itemID = itemID,
        previousItemID = previousID,
        oldSlot = oldSlot,
    })
    Internal.bumpRevision(record, { op }, reason or "equip_water_container")
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true, item and "equipped_water_container" or "water_container_cleared"
end

function Inventory.ClearWaterContainer(record, reason)
    return Inventory.SetWaterContainer(record, nil,
        reason or "unequip_water_container")
end

function Inventory.SetWorn(record, itemID, wornSlot, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local item
    local previousItemID
    local previous
    local oldSlot
    local op
    local ops = {}
    if not inv then return false, "inventory_unavailable" end
    itemID = Internal.normalizeString(itemID)
    wornSlot = Internal.normalizeString(wornSlot)
    item = itemID and inv.items[itemID] or nil
    if itemID and not item then return false, "item_not_found" end
    if itemID and not wornSlot then return false, "worn_slot_missing" end

    preserveWornItemVisual(record, inv, wornSlot)

    if item then
        if item.container ~= "root" then
            Internal.setItemContainer(inv, item, "root")
            ops[#ops + 1] = Internal.buildOperation("move", {
                itemID = item.id,
                to = "root",
            })
        end
        oldSlot = item.wornSlot
        preserveWornItemVisual(record, inv, oldSlot)
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
    ops[#ops + 1] = op
    Internal.bumpRevision(record, ops, reason or "inventory_wear")
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true, item and "worn" or "removed"
end

function Inventory.ClearWorn(record, itemID, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local item = inv and inv.items
        and inv.items[Internal.normalizeString(itemID)] or nil
    if not item then return false, "item_not_found" end
    if not item.wornSlot then return true, "unchanged" end
    return Inventory.SetWorn(
        record,
        nil,
        item.wornSlot,
        reason or "inventory_unwear"
    )
end

return Inventory
