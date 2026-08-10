local Resolution = PNC.CombatResolution
local Inventory = PNC.Inventory

local function equippedInventoryItem(record)
    local inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    local itemID = inv and inv.equipped and inv.equipped.primary or nil
    return inv, itemID, itemID and inv.items and inv.items[itemID] or nil
end

function Resolution.ConsumeAmmo(record, weaponItem)
    local firearms = PNC.Firearms
    local inv
    local ammoType
    local itemID
    local item
    if firearms and firearms.PrepareShot then
        return firearms.PrepareShot(record, weaponItem)
    end
    if not Resolution.IsAmmoConsumptionEnabled()
        or not record
        or not (
            record.recruited == true
            or record.ownerOnlineID ~= nil
            or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "")
        )
    then
        return true, "ammo_disabled"
    end
    ammoType = weaponItem and weaponItem.getAmmoType and weaponItem:getAmmoType() or nil
    if not ammoType or ammoType == "" then
        return true, "ammo_not_required"
    end
    inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    if not inv then
        return false, "inventory_unavailable"
    end
    for itemID, item in pairs(inv.items or {}) do
        if item and item.type == ammoType then
            if (tonumber(item.stack) or 1) > 1 then
                Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, stack = item.stack - 1 }}, "combat_ammo")
            else
                Inventory.ApplyDelta(record, {{ op = "remove", itemID = itemID }}, "combat_ammo")
            end
            return true, "ammo_consumed"
        end
    end
    return false, "out_of_ammo"
end

function Resolution.ApplyWeaponConditionLoss(record, weaponItem)
    local inv
    local itemID
    local item
    local condition
    local lowerChance
    if not Resolution.IsWeaponConditionEnabled() or not weaponItem then
        return false
    end
    inv, itemID, item = equippedInventoryItem(record)
    if not inv or not itemID or not item then
        return false
    end
    lowerChance = weaponItem.getConditionLowerChance and tonumber(weaponItem:getConditionLowerChance()) or 1
    lowerChance = math.max(1, math.floor(lowerChance or 1))
    if ZombRand and ZombRand(lowerChance) ~= 0 then
        return false
    end
    condition = tonumber(item.cond)
        or (weaponItem.getCondition and tonumber(weaponItem:getCondition()))
        or (weaponItem.getConditionMax and tonumber(weaponItem:getConditionMax()))
        or 1
    condition = math.max(0, condition - 1)
    return Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, cond = condition }}, "combat_condition") == true
end

return Resolution
