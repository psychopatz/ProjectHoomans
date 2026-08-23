local Internal = PNC.Combat.Internal
local Inventory = PNC.Inventory

local function mirrorMagazine(weaponItem, count)
    if weaponItem and weaponItem.setCurrentAmmoCount then
        pcall(weaponItem.setCurrentAmmoCount, weaponItem, math.max(0, math.floor(tonumber(count) or 0)))
    end
end

local function updateMagazine(record, itemID, count, reason, weaponItem)
    local inv = record and record.inventory or nil
    local state = inv and inv.items and inv.items[itemID] or nil
    count = math.max(0, math.floor(tonumber(count) or 0))
    if state and tonumber(state.ammoCount) == count then
        mirrorMagazine(weaponItem, count)
        return true
    end
    if not Inventory or not Inventory.ApplyDelta
        or not Inventory.ApplyDelta(record, {
            { op = "update", itemID = itemID, ammoCount = count },
        }, reason or "combat_magazine")
    then
        return false
    end
    mirrorMagazine(weaponItem, count)
    return true
end

local function ensureMagazine(record, descriptor, weaponItem)
    local inv
    local itemID
    local state
    local count
    inv, itemID, state = Internal.PrimaryInventoryState(record, descriptor.fullType)
    if not inv or not itemID or not state then
        return nil, "equipped_weapon_inventory_missing"
    end
    count = state.ammoCount
    if count == nil then
        count = descriptor.capacity
        if not updateMagazine(record, itemID, count, "combat_magazine_init", weaponItem) then
            return nil, "magazine_init_failed"
        end
    else
        count = math.max(0, math.min(descriptor.capacity, math.floor(tonumber(count) or 0)))
        if tonumber(state.ammoCount) ~= count then
            if not updateMagazine(record, itemID, count, "combat_magazine_clamp", weaponItem) then
                return nil, "magazine_clamp_failed"
            end
        else
            mirrorMagazine(weaponItem, count)
        end
    end
    return {
        inventory = inv,
        itemID = itemID,
        item = state,
        count = count,
    }
end

local function looseAmmoEntries(inv, ammoType, weaponItemID)
    local ids = {}
    local id
    local item
    for id, item in pairs(inv and inv.items or {}) do
        if id ~= weaponItemID and item and Internal.SameItemType(item.type, ammoType) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids, function(left, right) return tostring(left) < tostring(right) end)
    return ids
end

local function countLooseAmmo(inv, ammoType, weaponItemID)
    local total = 0
    local ids = looseAmmoEntries(inv, ammoType, weaponItemID)
    local i
    local item
    for i = 1, #ids do
        item = inv.items[ids[i]]
        total = total + math.max(1, math.floor(tonumber(item and item.stack) or 1))
    end
    return total
end

Internal.MirrorMagazine = mirrorMagazine
Internal.UpdateMagazine = updateMagazine
Internal.EnsureMagazine = ensureMagazine
Internal.LooseAmmoEntries = looseAmmoEntries
Internal.CountLooseAmmo = countLooseAmmo
