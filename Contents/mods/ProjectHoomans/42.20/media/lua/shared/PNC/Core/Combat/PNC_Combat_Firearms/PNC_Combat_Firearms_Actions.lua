local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal
local Inventory = PNC.Inventory
local Skills = PNC.Skills

function Firearms.PrepareShot(record, weaponItem, existingMagazine)
    local magazine
    local reason
    local roundsRequired
    if type(existingMagazine) == "table"
        and (existingMagazine.ammoNotRequired == true
            or existingMagazine.itemID ~= nil)
    then
        magazine = existingMagazine
        reason = existingMagazine.ammoNotRequired == true
            and "ammo_not_required" or "magazine_ready"
    else
        magazine, reason = Firearms.GetMagazineState(record, weaponItem, {
            skipLooseAmmoWhenLoaded = true,
        })
    end
    if not magazine then return false, reason end
    if magazine.ammoNotRequired == true then
        return true, reason, magazine
    end
    roundsRequired = math.max(
        1,
        math.floor(tonumber(magazine.descriptor and magazine.descriptor.ammoPerShot) or 1)
    )
    if (tonumber(magazine.count) or 0) < roundsRequired then
        if magazine.unlimitedReserve ~= true and magazine.looseAmmo == nil then
            magazine.looseAmmo = Internal.CountLooseAmmo(
                record and record.inventory,
                magazine.ammoType,
                magazine.itemID
            )
        end
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

local function isIncrementalReloadDescriptor(descriptor)
    if type(descriptor) ~= "table" then return false end
    local fam = tostring(descriptor.reloadFamily or "")
    if fam == "shotgun" or fam == "dbshotgun" or fam == "revolver" then
        return true
    end
    if descriptor.rackAfterShoot == true and (tonumber(descriptor.capacity) or 0) <= 10 then
        return true
    end
    return false
end

local function insertSingleRound(record, zombie, weaponItem, descriptor)
    local state, reason = Internal.EnsureMagazine(record, descriptor, weaponItem)
    if not state then return false, reason, nil end
    if state.count >= descriptor.capacity then
        return false, "magazine_full", state.count
    end
    if Firearms.HasUnlimitedReserve(record) then
        local newCount = state.count + 1
        if not Internal.UpdateMagazine(
            record,
            state.itemID,
            newCount,
            "combat_reload_step_unlimited",
            weaponItem
        ) then
            return false, "reload_magazine_update_failed", state.count
        end
        return true, "round_inserted", newCount
    end
    local available = Internal.CountLooseAmmo(state.inventory, descriptor.ammoType, state.itemID)
    if (tonumber(available) or 0) <= 0 then
        return false, "out_of_ammo", state.count
    end
    local newCount = state.count + 1
    local ops = Internal.BuildReloadOps(
        state.inventory,
        descriptor.ammoType,
        state.itemID,
        1,
        newCount
    )
    if not ops or not Inventory.ApplyDelta(record, ops, "combat_reload_step") then
        return false, "reload_inventory_update_failed", state.count
    end
    Internal.MirrorMagazine(weaponItem, newCount)
    return true, "round_inserted", newCount
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
    local startCount = math.max(0, tonumber(magazine.count) or 0)
    local capacity = math.max(1, tonumber(descriptor.capacity) or 1)
    local needed = math.max(1, capacity - startCount)
    local roundsToLoad = magazine.unlimitedReserve == true
        and needed
        or math.max(1, math.min(needed, tonumber(magazine.looseAmmo) or 0))
    local targetCount = math.min(capacity, startCount + roundsToLoad)
    local incremental = isIncrementalReloadDescriptor(descriptor)
    local reloadDurationMs = tonumber(descriptor.reloadDurationMs) or 1850
    local perRoundMs = 0
    if incremental then
        local reloadLevel = Skills and Skills.GetLevel
            and math.max(0, math.min(10, tonumber(Skills.GetLevel(record, "Reloading")) or 0))
            or 0
        perRoundMs = math.max(280, math.floor(460 * (1.0 - reloadLevel * 0.03)))
        reloadDurationMs = math.max(perRoundMs + 80, math.min(3400, roundsToLoad * perRoundMs + 120))
    end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    Internal.buildAttackAction(record, target, "reload", "reload", anim, 0, "Reloading", {
        durationMs = reloadDurationMs,
        hitDelayMs = reloadDurationMs,
        weaponFullType = descriptor.fullType,
        ammoType = descriptor.ammoType,
        ammoPerShot = tonumber(descriptor.ammoPerShot) or 1,
        magazineCapacity = capacity,
        reloadStartCount = startCount,
        reloadCurrentCount = startCount,
        reloadTargetCount = targetCount,
        reloadIncremental = incremental,
        reloadPerRoundMs = perRoundMs,
        reloadNextInsertAt = incremental and (now + perRoundMs) or 0,
        reloadProgress = 0,
        syncEvent = "reload_start",
    })
    local callouts = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if callouts and type(callouts.TryEmitReloadCallout) == "function" then
        callouts.TryEmitReloadCallout(record, target, now)
    end
    return true, "reload_started"
end

function Firearms.StepReload(record, zombie, action, target, now)
    if type(action) ~= "table" or action.attackType ~= "reload" then
        return false, nil
    end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local startedAt = tonumber(action.startedAt) or now
    local finishAt = tonumber(action.finishAt) or (startedAt + 1)
    action.reloadProgress = math.max(0, math.min(1, (now - startedAt) / math.max(1, finishAt - startedAt)))

    if action.reloadIncremental ~= true then
        local bucket = math.floor(action.reloadProgress * 4)
        if bucket > (tonumber(action.reloadProgressBucket) or 0) and bucket < 4 then
            action.reloadProgressBucket = bucket
            if record and record.runtime then
                record.runtime.forceSyncEvent = "reload_progress"
            end
        end
        return false, "reloading"
    end

    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record, zombie)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    if not descriptor or not Internal.SameItemType(descriptor.fullType, action.weaponFullType) then
        return true, "weapon_changed_during_reload"
    end

    local targetCount = tonumber(action.reloadTargetCount) or descriptor.capacity
    local perRoundMs = math.max(220, tonumber(action.reloadPerRoundMs) or 420)
    local nextInsertAt = tonumber(action.reloadNextInsertAt) or (startedAt + perRoundMs)
    local insertedAny = false
    while now >= nextInsertAt and (tonumber(action.reloadCurrentCount) or 0) < targetCount do
        local ok, stepReason, newCount = insertSingleRound(record, zombie, weaponItem, descriptor)
        if not ok then
            if stepReason == "out_of_ammo" and (tonumber(action.reloadCurrentCount) or 0) > (tonumber(action.reloadStartCount) or 0) then
                if record and record.runtime then
                    record.runtime.forceSyncEvent = "reload_finished"
                end
                return true, "reload_partial_out_of_ammo"
            end
            if stepReason == "magazine_full" then
                action.reloadCurrentCount = descriptor.capacity
                return true, "magazine_full"
            end
            return false, stepReason
        end
        action.reloadCurrentCount = newCount
        insertedAny = true
        nextInsertAt = nextInsertAt + perRoundMs
    end
    action.reloadNextInsertAt = nextInsertAt
    if insertedAny and record and record.runtime then
        record.runtime.forceSyncEvent = "reload_progress"
        if Skills and Skills.AddXP then
            Skills.AddXP(record, "Reloading", 0.5)
        end
    end

    local curLoaded = tonumber(action.reloadCurrentCount) or 0
    if curLoaded >= targetCount then
        if record and record.runtime then
            record.runtime.forceSyncEvent = "reload_finished"
        end
        return true, "reload_complete_incremental"
    end

    -- Failsafe-only partial-load firing: as long as the NPC has ammo and
    -- stamina, they complete a normal full reload. Only cut reload short as a
    -- failsafe if they are completely exhausted with rounds already loaded.
    local ammoPerShot = math.max(1, tonumber(action.ammoPerShot) or 1)
    if curLoaded >= ammoPerShot then
        local staminaRatio = PNC.Stamina and type(PNC.Stamina.GetRatio) == "function"
            and tonumber(PNC.Stamina.GetRatio(record)) or 1
        if staminaRatio <= 0.08 then
            if record and record.runtime then
                record.runtime.forceSyncEvent = "reload_finished"
            end
            return true, "reload_partial_exhausted"
        end
    end

    return false, "reloading"
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
