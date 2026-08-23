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

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end
    record.runtime = record.runtime or {}
    attackMode = attackMode == true
    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, false)
    handStateCurrent = Internal.isPrimaryHandStateCurrent(
        zombie,
        descriptor,
        attackMode
    )
    if force ~= true
        and record.runtime.equipmentAttackModeApplied == attackMode
        and record.runtime.equipmentPresentationRevision == Equipment.PRESENTATION_REVISION
        and handStateCurrent ~= false
    then
        return true, "unchanged"
    end

    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, attachedReason, handsReason = Internal.applyCombatPresentation(zombie, record, equipment, descriptor, attackMode)
    Visuals.RefreshModel(zombie)
    return ok, tostring(attachedReason) .. "|" .. tostring(handsReason)
end

function Equipment.EnsureCombatHands(zombie, record)
    local equipment
    local descriptor
    local current
    local ok
    local reason
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
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

function Equipment.ResolveWeaponMode(fullType)
    return Internal.buildWeaponDescriptor(fullType, false).resolvedMode
end

function Equipment.ActivateMeleeFallback(record, zombie)
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
    ok, reason = Inventory.EquipPrimary(
        record,
        selectedID,
        selectedID and "combat_melee_fallback" or "combat_shove_fallback"
    )
    if not ok then return false, reason end
    record.weaponMode = "melee"
    record.runtime = record.runtime or {}
    record.runtime.weaponFallbackFrom = currentType
    record.runtime.weaponFallbackReason = "out_of_ammo"
    record.runtime.forceSyncEvent = selectedID
        and "weapon_fallback_melee"
        or "weapon_fallback_shove"
    record.runtime.equipmentDescribeCache = nil
    if zombie then
        Equipment.ApplyCombatState(zombie, record, true, true)
    end
    return true, selectedID and "switched_to_melee" or "switched_to_shove"
end
