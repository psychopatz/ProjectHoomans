local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal
local Inventory = PNC.Inventory
local Skills = PNC.Skills

function Firearms.PrepareShot(record, weaponItem)
    local magazine
    local reason
    local roundsRequired
    magazine, reason = Firearms.GetMagazineState(record, weaponItem)
    if not magazine then return false, reason end
    if magazine.ammoNotRequired == true then
        return true, reason, magazine
    end
    roundsRequired = math.max(
        1,
        math.floor(tonumber(magazine.descriptor and magazine.descriptor.ammoPerShot) or 1)
    )
    if (tonumber(magazine.count) or 0) < roundsRequired then
        if magazine.unlimitedReserve == true
            or (tonumber(magazine.looseAmmo) or 0) > 0
        then
            return false, "reload_required", magazine
        end
        return false, "out_of_ammo", magazine
    end
    if not Internal.UpdateMagazine(
        record,
        magazine.itemID,
        magazine.count - roundsRequired,
        "combat_round_fired",
        weaponItem
    ) then
        return false, "ammo_update_failed", magazine
    end
    magazine.count = magazine.count - roundsRequired
    return true, "round_consumed", magazine
end

function Firearms.StartReload(record, zombie, target, weaponItem)
    local magazine
    local reason
    local descriptor
    local anim
    if record and record.runtime and record.runtime.attackAction then
        return false, "action_in_progress"
    end
    magazine, reason = Firearms.GetMagazineState(record, weaponItem)
    if not magazine then return false, reason end
    if magazine.ammoNotRequired == true then return false, "reload_not_required" end
    if magazine.count >= magazine.capacity then return false, "magazine_full" end
    if magazine.unlimitedReserve ~= true and magazine.looseAmmo <= 0 then
        return false, "out_of_ammo"
    end
    descriptor = magazine.descriptor
    anim = descriptor.reloadAnim
    if not Internal.buildAttackAction then
        return false, "action_service_unavailable"
    end
    if Internal.prepareAttackMovement then
        Internal.prepareAttackMovement(
            record,
            zombie,
            "reload_windup"
        )
    end
    Internal.buildAttackAction(record, target, "reload", "reload", anim, 0, "Reloading", {
        durationMs = descriptor.reloadDurationMs,
        hitDelayMs = descriptor.reloadDurationMs,
        weaponFullType = descriptor.fullType,
        ammoType = descriptor.ammoType,
        magazineCapacity = descriptor.capacity,
        syncEvent = "reload_start",
    })
    return true, "reload_started"
end

function Firearms.CompleteReload(record, zombie, action)
    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record, zombie)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    local state
    local reason
    local available
    local needed
    local loadCount
    local ops
    if not descriptor or not Internal.SameItemType(descriptor.fullType, action and action.weaponFullType) then
        return false, "weapon_changed_during_reload"
    end
    state, reason = Internal.EnsureMagazine(record, descriptor, weaponItem)
    if not state then return false, reason end
    needed = math.max(0, descriptor.capacity - state.count)
    if needed <= 0 then return true, "magazine_full" end
    if Firearms.HasUnlimitedReserve(record) then
        if not Internal.UpdateMagazine(
            record,
            state.itemID,
            descriptor.capacity,
            "combat_reload_unlimited_reserve",
            weaponItem
        ) then
            return false, "reload_magazine_update_failed"
        end
        if record and record.runtime then
            record.runtime.forceSyncEvent = "reload_finished"
        end
        if Skills and Skills.AddXP then
            Skills.AddXP(record, "Reloading", 2)
        end
        return true, "reload_complete_unlimited_reserve"
    end
    available = Internal.CountLooseAmmo(state.inventory, descriptor.ammoType, state.itemID)
    loadCount = math.min(needed, available)
    if loadCount <= 0 then return false, "out_of_ammo" end
    ops = Internal.BuildReloadOps(
        state.inventory,
        descriptor.ammoType,
        state.itemID,
        loadCount,
        state.count + loadCount
    )
    if not ops or not Inventory.ApplyDelta(record, ops, "combat_reload") then
        return false, "reload_inventory_update_failed"
    end
    Internal.MirrorMagazine(weaponItem, state.count + loadCount)
    if Skills and Skills.AddXP then
        Skills.AddXP(record, "Reloading", 2)
    end
    if record and record.runtime then
        record.runtime.forceSyncEvent = "reload_finished"
    end
    return true, loadCount < needed and "reload_partial" or "reload_complete"
end
