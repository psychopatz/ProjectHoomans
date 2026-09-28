local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal

function Firearms.BuildDebugState(record)
    local runtime = record and record.runtime or nil
    local inventory = record and record.inventory or nil
    local equipment = record and record.equipment or nil
    local action = runtime and runtime.attackAction or nil
    local cacheKey = tostring(inventory and inventory.revision or 0)
        .. "|" .. tostring(equipment and equipment.primaryFullType or "")
        .. "|" .. tostring(record and record.weaponMode or "")
        .. "|" .. tostring(record and record.recruited == true)
        .. "|" .. tostring(record and record.ownerOnlineID or "")
        .. "|" .. tostring(record and record.ownerUsername or "")
        .. "|" .. tostring(action and action.attackType or "")
    if runtime
        and runtime.firearmDebugCacheValid == true
        and runtime.firearmDebugCacheKey == cacheKey
    then
        return runtime.firearmDebugCache
    end
    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    local inv
    local itemID
    local item
    local count
    if not descriptor or not descriptor.ammoType or descriptor.ammoType == "" then
        if runtime then
            runtime.firearmDebugCacheKey = cacheKey
            runtime.firearmDebugCache = nil
            runtime.firearmDebugCacheValid = true
        end
        return nil
    end
    inv, itemID, item = Internal.PrimaryInventoryState(record, descriptor.fullType)
    if not inv or not itemID or not item then
        if runtime then
            runtime.firearmDebugCacheKey = cacheKey
            runtime.firearmDebugCache = nil
            runtime.firearmDebugCacheValid = true
        end
        return nil
    end
    count = item.ammoCount
    if count == nil then count = descriptor.capacity end
    count = math.max(0, math.min(descriptor.capacity, math.floor(tonumber(count) or 0)))
    local state = {
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
    if runtime then
        runtime.firearmDebugCacheKey = cacheKey
        runtime.firearmDebugCache = state
        runtime.firearmDebugCacheValid = true
    end
    return state
end
