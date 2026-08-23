local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal

function Firearms.BuildDebugState(record)
    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    local inv
    local itemID
    local item
    local count
    if not descriptor or not descriptor.ammoType or descriptor.ammoType == "" then
        return nil
    end
    inv, itemID, item = Internal.PrimaryInventoryState(record, descriptor.fullType)
    if not inv or not itemID or not item then return nil end
    count = item.ammoCount
    if count == nil then count = descriptor.capacity end
    count = math.max(0, math.min(descriptor.capacity, math.floor(tonumber(count) or 0)))
    return {
        count = count,
        capacity = descriptor.capacity,
        ammoType = descriptor.ammoType,
        reloadFamily = descriptor.reloadFamily,
        reloadActive = record and record.runtime and record.runtime.attackAction
            and record.runtime.attackAction.attackType == "reload"
            or false,
        unlimitedReserve = Firearms.HasUnlimitedReserve(record),
        reserveCount = Firearms.HasUnlimitedReserve(record)
            and nil
            or Internal.CountLooseAmmo(inv, descriptor.ammoType, itemID),
    }
end
