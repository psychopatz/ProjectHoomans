PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Equipment.IsAttackMode(record)
    return Internal.isAttackMode(record)
end

function Equipment.ApplyCombatState(zombie, record, attackMode, force)
    local equipment
    local descriptor
    local ok
    local attachedReason
    local handsReason
    local handStateCurrent
    local workPresentation
    local workHeld
    local primaryFullType

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end
    record.runtime = record.runtime or {}
    attackMode = attackMode == true
    workPresentation = Equipment.ResolveWorkPresentation
        and Equipment.ResolveWorkPresentation(record) or nil
    workHeld = workPresentation and workPresentation.held == true
    equipment = Equipment.EnsureRecordEquipment(record)
    primaryFullType = equipment.primaryFullType
    if not attackMode and workHeld and workPresentation
        and workPresentation.fullType
    then
        primaryFullType = workPresentation.fullType
    end
    descriptor = Internal.buildWeaponDescriptor(primaryFullType, false)
    handStateCurrent = Internal.isPrimaryHandStateCurrent(
        zombie,
        descriptor,
        attackMode or workHeld
    )
    if force ~= true
        and record.runtime.equipmentAttackModeApplied == attackMode
        and record.runtime.equipmentPresentationRevision == Equipment.PRESENTATION_REVISION
        and handStateCurrent ~= false
    then
        return true, "unchanged"
    end

    descriptor = Internal.buildWeaponDescriptor(primaryFullType, true)
    ok, attachedReason, handsReason = Internal.applyCombatPresentation(
        zombie, record, equipment, descriptor, attackMode or workHeld
    )
    Visuals.RefreshModel(zombie)
    return ok, tostring(attachedReason) .. "|" .. tostring(handsReason)
end

function Equipment.EnsureCombatHands(zombie, record, options)
    local equipment
    local descriptor
    local current
    local ok
    local reason
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record, options)
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, false)
    current = Internal.isPrimaryHandStateCurrent(zombie, descriptor, true)
    if current == true then
        return true, "unchanged"
    end
    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, reason = Internal.applyHands(
        zombie,
        record,
        equipment,
        descriptor,
        true
    )
    record.runtime = record.runtime or {}
    record.runtime.equipmentAttackModeApplied = true
    record.runtime.equipmentPresentationRevision =
        Equipment.PRESENTATION_REVISION
    Visuals.RefreshModel(zombie)
    return ok, reason
end

-- Work tools are a presentation concern separate from combat stance. Jobs
-- use this entry point so a rod, axe, or construction tool is visibly held
-- while combat can still replace it through ApplyCombatState.
function Equipment.EnsureWorkHands(zombie, record, options)
    options = type(options) == "table" and options or {}
    options.forceHeld = true
    return Equipment.EnsureCombatHands(zombie, record, options)
end

function Equipment.ResolveWeaponMode(fullType)
    return Internal.buildWeaponDescriptor(fullType, false).resolvedMode
end

local function temporaryFallbackRange(reason)
    local const = PNC.Const or {}
    if reason == "friendly_fire_risk" then
        return tonumber(const.MIXED_MELEE_FALLBACK_RANGE) or 4.0
    end
    return tonumber(const.MIXED_MELEE_SWITCH_RANGE) or 2.4
end

local function clearTemporaryFallback(runtime)
    runtime.weaponFallbackTemporary = nil
    runtime.weaponFallbackFromID = nil
    runtime.weaponFallbackToID = nil
    runtime.weaponFallbackRange = nil
end

function Equipment.ActivateMeleeFallback(record, zombie, fallbackReason)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local currentID = inv and inv.equipped and inv.equipped.primary or nil
    local currentType = currentID and inv.items and inv.items[currentID]
        and inv.items[currentID].type
        or nil
    local candidates = {}
    local itemID
    local state
    local descriptor
    local selectedID
    local ok
    local reason
    local temporary
    fallbackReason = tostring(fallbackReason or "out_of_ammo")
    temporary = fallbackReason == "mixed_close"
        or fallbackReason == "friendly_fire_risk"
    if not record or not inv or not Inventory.EquipPrimary then
        return false, "inventory_fallback_unavailable"
    end
    for itemID, state in pairs(inv.items or {}) do
        if itemID ~= currentID and state
            and (state.cond == nil or tonumber(state.cond) == nil or tonumber(state.cond) > 0)
        then
            descriptor = Internal.buildWeaponDescriptor(state.type, false)
            if descriptor.hasWeapon == true and descriptor.resolvedMode == "melee" then
                candidates[#candidates + 1] = {
                    id = itemID,
                    reserve = state.templateKey == "tmpl:weapon:reserve" and 0 or 1,
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.reserve ~= right.reserve then return left.reserve < right.reserve end
        return tostring(left.id) < tostring(right.id)
    end)
    selectedID = candidates[1] and candidates[1].id or nil
    if Equipment.AcquirePrimaryLease then
        ok, reason = Equipment.AcquirePrimaryLease(
            record, "combat", selectedID, {
                priority = "COMBAT",
                reason = selectedID and "combat_melee_fallback"
                    or "combat_shove_fallback",
                replaceEqual = true,
            })
    else
        ok, reason = Inventory.EquipPrimary(
            record,
            selectedID,
            selectedID and "combat_melee_fallback" or "combat_shove_fallback"
        )
    end
    if not ok then return false, reason end
    record.runtime = record.runtime or {}
    if temporary then
        record.runtime.weaponFallbackTemporary = true
        record.runtime.weaponFallbackFromID = currentID
        record.runtime.weaponFallbackToID = selectedID
        record.runtime.weaponFallbackRange = temporaryFallbackRange(fallbackReason)
    else
        clearTemporaryFallback(record.runtime)
        record.weaponMode = "melee"
    end
    record.runtime.weaponFallbackFrom = currentType
    record.runtime.weaponFallbackReason = fallbackReason
    record.runtime.forceSyncEvent = selectedID
        and "weapon_fallback_melee"
        or "weapon_fallback_shove"
    record.runtime.equipmentDescribeCache = nil
    if zombie then
        Equipment.ApplyCombatState(zombie, record, true, true)
    end
    return true, selectedID and "switched_to_melee" or "switched_to_shove"
end

function Equipment.RestoreRangedFallback(record, zombie)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local runtime = record and record.runtime or nil
    local currentID
    local fallbackID
    local sourceItem
    local descriptor
    local ok
    local reason
    if not record or not inv or not runtime
        or runtime.weaponFallbackTemporary ~= true
    then
        return false, "no_temporary_melee_fallback"
    end
    currentID = inv.equipped and inv.equipped.primary or nil
    fallbackID = runtime.weaponFallbackToID
    if currentID ~= fallbackID then
        clearTemporaryFallback(runtime)
        return false, "temporary_fallback_interrupted"
    end
    sourceItem = runtime.weaponFallbackFromID
        and inv.items
        and inv.items[runtime.weaponFallbackFromID]
        or nil
    descriptor = sourceItem
        and Internal.buildWeaponDescriptor(sourceItem.type, false)
        or nil
    if not sourceItem or not descriptor
        or descriptor.hasUsableFirearm ~= true
    then
        clearTemporaryFallback(runtime)
        return false, "ranged_fallback_unavailable"
    end
    if Equipment.ReleasePrimaryLease then
        ok, reason = Equipment.ReleasePrimaryLease(record, "combat", {
            reason = "combat_ranged_restore",
        })
    else
        ok, reason = Inventory.EquipPrimary(
            record,
            runtime.weaponFallbackFromID,
            "combat_ranged_restore"
        )
    end
    if not ok then return false, reason end
    clearTemporaryFallback(runtime)
    runtime.weaponFallbackFrom = nil
    runtime.weaponFallbackReason = nil
    runtime.forceSyncEvent = "weapon_restore_ranged"
    runtime.equipmentDescribeCache = nil
    if zombie then
        Equipment.ApplyCombatState(zombie, record, true, true)
    end
    return true, "switched_to_ranged"
end
