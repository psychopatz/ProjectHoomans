--[[
    PNC Behavior Combat
    Encapsulates combat engagement flow so job handlers can hand off an active
    target without owning melee, ranged, and retreat state sequencing.
]]

PNC = PNC or {}
PNC.BehaviorCombat = PNC.BehaviorCombat or {}

local BehaviorCombat = PNC.BehaviorCombat
local Core = PNC.Core
local Const = PNC.Const
local Combat = PNC.Combat
local Equipment = PNC.Equipment
local Tactics = PNC.CombatTactics
local Common = PNC.BehaviorCommon
local PathService = PNC.PathService

local function holdRangedAim(record, zombie, target)
    local timings = Combat and Combat.Internal and Combat.Internal.ATTACK_TIMINGS or nil
    local leaseMs = timings and timings.ranged and timings.ranged.duration or 620
    Common.HaltMovement(record, zombie, "ranged_aim")
    if Combat and Combat.FaceTarget then
        Combat.FaceTarget(record, zombie, target, leaseMs, "ranged_aim")
    end
end

local function logBlocked(record, lane, reason)
    local runtime
    local state
    local key
    local now
    local repeatMs
    if not record then
        return
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    state = runtime.combatBlockedLog or {}
    runtime.combatBlockedLog = state
    key = tostring(lane or "combat") .. "|" .. tostring(reason or "unknown")
    now = Core.Now()
    repeatMs = tonumber(Const.COMBAT_BLOCK_LOG_REPEAT_MS) or 5000
    if state.key == key and (now - (tonumber(state.at) or 0)) < repeatMs then
        return
    end
    state.key = key
    state.at = now
    Core.LogRecordDebug(
        record,
        "NPC " .. tostring(record.id) .. " " .. tostring(lane or "combat") .. " blocked=" .. tostring(reason)
    )
end

local function holdRangedAction(record, zombie, target, reason, mode, weaponStatus)
    if reason ~= "reload_started" and reason ~= "reloading" then
        return false
    end
    holdRangedAim(record, zombie, target)
    Common.SetCombatDebug(record, target, "reloading", mode, weaponStatus)
    return true
end

local function activateRangedFallback(record, zombie, target, reason, weaponStatus)
    local switched
    local fallbackReason
    if reason ~= "out_of_ammo" then return false end
    if Equipment and Equipment.ActivateMeleeFallback then
        switched, fallbackReason = Equipment.ActivateMeleeFallback(record, zombie)
    end
    if switched then
        if Tactics and Tactics.ClearRetreatState then
            Tactics.ClearRetreatState(record)
        end
        Common.SetCombatDebug(
            record,
            target,
            fallbackReason or "switched_to_shove",
            "melee",
            fallbackReason == "switched_to_melee"
                and "melee_fallback"
                or "barehand_fallback"
        )
        return true
    end
    Common.SetCombatDebug(record, target, fallbackReason or reason, "ranged", weaponStatus)
    return false
end

function BehaviorCombat.TickEngage(record, zombie, target)
    local dist = math.sqrt(tonumber(target and target.distSq or 0) or 0)
    local equipmentInfo = Equipment.Describe(record)
    local effectiveMode = equipmentInfo.combatModeResolved
    local previousWeaponStatus = record.runtime.weaponStatus
    local attacked
    local reason
    local actionActive
    local repositioned
    local repositionReason
    local shouldApproach
    local approachStopDistance
    local approachMode

    if Equipment.ApplyCombatState and zombie then
        Equipment.ApplyCombatState(zombie, record, true)
    end
    Common.SetCombatDebug(record, target, "engaging_" .. tostring(target.kind or "unknown"), effectiveMode, equipmentInfo.weaponStatus)

    if PathService and PathService.IsTraversalActive and PathService.IsTraversalActive(record, zombie) then
        Common.SetCombatDebug(record, target, "traversal_active", effectiveMode, equipmentInfo.weaponStatus)
        return
    end

    if equipmentInfo.weaponStatus ~= previousWeaponStatus then
        Core.LogRecordDebug(record, "NPC " .. tostring(record.id) .. " weapon state=" .. tostring(equipmentInfo.weaponStatus))
    end

    if Combat and Combat.PumpAttackAction then
        actionActive, reason = Combat.PumpAttackAction(record, zombie)
        if actionActive then
            Common.HaltMovement(record, zombie)
            Common.SetCombatDebug(record, target, reason or "attack_in_progress", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
    end

    if target.visible == false or target.visibilityKind == "clearthroughwindow" then
        Common.MoveRecord(
            record,
            zombie,
            target.x,
            target.y,
            target.z,
            Common.ResolveCombatApproachMode(dist, "walk"),
            0.75,
            target.visible == false and "investigating_last_seen" or "approaching_visible_window"
        )
        Common.SetCombatDebug(
            record,
            target,
            target.visible == false and "investigating_last_seen" or "approaching_visible_window",
            effectiveMode,
            equipmentInfo.weaponStatus
        )
        return
    end

    if (effectiveMode == "ranged" or effectiveMode == "mixed")
        and Tactics
        and Tactics.MaintainRangedSpacing
    then
        repositioned, repositionReason = Tactics.MaintainRangedSpacing(
            record,
            zombie,
            target
        )
        if repositioned then
            Common.SetCombatDebug(
                record,
                target,
                repositionReason or "ranged_disengage",
                effectiveMode,
                equipmentInfo.weaponStatus
            )
            return
        end
    end

    if effectiveMode == "ranged"
        and Tactics
        and Tactics.TryReposition
        and target.kind == "zombie"
        and dist < (tonumber(Const.RANGED_MIN_STANDOFF) or 2.2)
    then
        repositioned, repositionReason = Tactics.TryReposition(record, zombie, target, effectiveMode, "target_too_close", equipmentInfo)
        if repositioned then
            Common.SetCombatDebug(record, target, repositionReason or "maintaining_range", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
    end

    if effectiveMode == "melee" then
        attacked, reason = Combat.TryMelee(record, zombie, target)
        if attacked then
            if Tactics and Tactics.ClearRetreatState then
                Tactics.ClearRetreatState(record)
            end
            Common.HaltMovement(record, zombie)
            Common.SetCombatDebug(record, target, "attacking_melee", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        if Tactics and Tactics.ResolveMeleeApproach then
            shouldApproach, approachStopDistance, approachMode = Tactics.ResolveMeleeApproach(record, dist)
        else
            shouldApproach, approachStopDistance, approachMode = reason == "target_out_of_range", Const.MELEE_RANGE, "run"
        end
        if reason == "target_out_of_range" or (shouldApproach and dist > Const.MELEE_RANGE) then
            Common.MoveRecord(
                record,
                zombie,
                target.x,
                target.y,
                target.z,
                Common.ResolveCombatApproachMode(dist, approachMode or "run"),
                approachStopDistance or Const.MELEE_RANGE,
                "closing_to_melee"
            )
            Common.SetCombatDebug(record, target, "closing_to_melee", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        if Tactics and Tactics.TryReposition then
            repositioned, repositionReason = Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
        else
            repositioned, repositionReason = false, nil
        end
        if repositioned then
            Common.SetCombatDebug(record, target, repositionReason or "melee_kiting", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        Common.SetCombatDebug(record, target, reason, effectiveMode, equipmentInfo.weaponStatus)
        logBlocked(record, "melee", reason)
        return
    end

    if effectiveMode == "ranged" then
        if dist <= Const.RANGED_RANGE then
            holdRangedAim(record, zombie, target)
        end
        attacked, reason = Combat.TryRanged(record, zombie, target)
        if attacked then
            if Tactics and Tactics.ClearRetreatState then
                Tactics.ClearRetreatState(record)
            end
            Common.HaltMovement(record, zombie)
            Common.SetCombatDebug(record, target, "attacking_ranged", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        if holdRangedAction(record, zombie, target, reason, effectiveMode, equipmentInfo.weaponStatus) then
            return
        end
        if activateRangedFallback(
            record,
            zombie,
            target,
            reason,
            equipmentInfo.weaponStatus
        ) then
            return
        end
        if reason == "target_out_of_range" then
            Common.MoveRecord(
                record,
                zombie,
                target.x,
                target.y,
                target.z,
                Common.ResolveCombatApproachMode(dist, "run"),
                Const.RANGED_RANGE * 0.8,
                "closing_to_range"
            )
            Common.SetCombatDebug(record, target, "closing_to_range", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        if Tactics and Tactics.TryReposition then
            repositioned, repositionReason = Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
        else
            repositioned, repositionReason = false, nil
        end
        if repositioned then
            Common.SetCombatDebug(record, target, repositionReason or "maintaining_range", effectiveMode, equipmentInfo.weaponStatus)
            return
        end
        Common.SetCombatDebug(record, target, reason, effectiveMode, equipmentInfo.weaponStatus)
        logBlocked(record, "ranged", reason)
        return
    end

    if dist <= Const.MELEE_RANGE * 1.1 then
        attacked, reason = Combat.TryMelee(record, zombie, target)
        if attacked then
            if Tactics and Tactics.ClearRetreatState then
                Tactics.ClearRetreatState(record)
            end
            Common.HaltMovement(record, zombie)
            Common.SetCombatDebug(record, target, "attacking_melee", "mixed", equipmentInfo.weaponStatus)
            return
        end
        if Tactics and Tactics.TryReposition then
            repositioned, repositionReason = Tactics.TryReposition(record, zombie, target, "melee", reason, equipmentInfo)
        else
            repositioned, repositionReason = false, nil
        end
        if repositioned then
            Common.SetCombatDebug(record, target, repositionReason or "melee_kiting", "mixed", equipmentInfo.weaponStatus)
            return
        end
        Common.SetCombatDebug(record, target, reason, "mixed", equipmentInfo.weaponStatus)
        logBlocked(record, "mixed melee", reason)
        return
    end

    if dist <= Const.RANGED_RANGE then
        holdRangedAim(record, zombie, target)
    end
    attacked, reason = Combat.TryRanged(record, zombie, target)
    if attacked then
        if Tactics and Tactics.ClearRetreatState then
            Tactics.ClearRetreatState(record)
        end
        Common.HaltMovement(record, zombie)
        Common.SetCombatDebug(record, target, "attacking_ranged", "mixed", equipmentInfo.weaponStatus)
        return
    end
    if holdRangedAction(record, zombie, target, reason, "mixed", equipmentInfo.weaponStatus) then
        return
    end
    if activateRangedFallback(
        record,
        zombie,
        target,
        reason,
        equipmentInfo.weaponStatus
    ) then
        return
    end
    if reason == "target_out_of_range" then
        Common.MoveRecord(
            record,
            zombie,
            target.x,
            target.y,
            target.z,
            Common.ResolveCombatApproachMode(dist, "run"),
            Const.RANGED_RANGE * 0.85,
            "closing_to_range"
        )
        Common.SetCombatDebug(record, target, "closing_to_range", "mixed", equipmentInfo.weaponStatus)
        return
    end
    if Tactics and Tactics.TryReposition then
        repositioned, repositionReason = Tactics.TryReposition(record, zombie, target, "ranged", reason, equipmentInfo)
    else
        repositioned, repositionReason = false, nil
    end
    if repositioned then
        Common.SetCombatDebug(record, target, repositionReason or "maintaining_range", "mixed", equipmentInfo.weaponStatus)
        return
    end
    Common.SetCombatDebug(record, target, reason, "mixed", equipmentInfo.weaponStatus)
    logBlocked(record, "mixed ranged", reason)
end
