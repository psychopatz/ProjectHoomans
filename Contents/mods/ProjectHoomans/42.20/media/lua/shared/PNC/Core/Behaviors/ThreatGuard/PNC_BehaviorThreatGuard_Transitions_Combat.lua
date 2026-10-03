local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Const = PNC.Const or {}
local Companion = PNC.BehaviorCompanion
local Common = PNC.BehaviorCommon
local Scenes = PNC.AnimationScenes
local Tactics = PNC.CombatTactics
local preserveTravelConversationScene =
    Internal.PreserveTravelConversationScene
local releaseCombatScene = Internal.ReleaseCombatScene
local alertTargetKey = Internal.AlertTargetKey
local releaseAlertScene = Internal.ReleaseAlertScene

function Internal.CanAttackTarget(record, target)
    if not record or not target then return false end
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        == tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    if target.kind == "zombie" and record.hostility
        and record.hostility.attackZombies == false
    then
        return false
    end
    return true
end

function Internal.AlertTarget(record, zombie, state, target)
    local runtime = record.runtime or {}
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local key = alertTargetKey(target)
    local changed = state.alertTargetKey ~= key
        or state.phase ~= "alerted"
    record.runtime = runtime
    releaseAlertScene(record, zombie, now)
    state.phase = "alerted"
    state.target = target
    record.activeBehavior = "CombatGuard:alerted"
    state.alertTargetKey = key
    if changed then
        Common.SetCombatTarget(record, target, "threat_guard_alert")
        if Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "threat_guard_alert")
        end
        if PNC.Combat and PNC.Combat.FaceTarget then
            PNC.Combat.FaceTarget(
                record,
                zombie,
                target,
                500,
                "threat_guard_alert"
            )
        end
        Common.SetCombatDebug(
            record,
            target,
            "proximity_alert",
            "none",
            "alerted"
        )
        Internal.LogTransition("alert", record, zombie, state, target,
            "alert_only")
        runtime.threatGuardAlertFaceAt = now + 500
    elseif PNC.Combat and PNC.Combat.FaceTarget
        and now >= (tonumber(runtime.threatGuardAlertFaceAt) or 0)
    then
        -- Keep the actor oriented toward a remembered threat without
        -- reissuing movement holds, combat-target writes, or debug payload
        -- changes every server behavior tick.
        PNC.Combat.FaceTarget(
            record,
            zombie,
            target,
            500,
            "threat_guard_alert_refresh"
        )
        runtime.threatGuardAlertFaceAt = now + 500
    end
    return true
end

function Internal.ClearState(record, zombie, reason)
    local runtime = record.runtime or {}
    local state = runtime.threatGuard
    if Common and Common.ClearCombatTarget then
        Common.ClearCombatTarget(record, reason or "threat_guard_exit", zombie)
    end
    runtime.threatGuard = nil
    if state and tonumber(state.nextScanAt) ~= nil then
        runtime.threatGuardNextScanAt = state.nextScanAt
    end
    runtime.threatGuardAlertSceneKey = nil
    runtime.threatGuardAlertSceneNextAt = nil
    runtime.threatGuardAlertFaceAt = nil
    Internal.LogTransition("exit", record, zombie, state, nil, reason)
end

function Internal.AttackEnabled(record)
    return tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        ~= tostring(Const.ATTACK_TYPE_NONE or "none")
end

function Internal.EnterAvoidance(record, zombie, state, target, threatContext)
    local moved
    local reason
    if not Tactics or not Tactics.AvoidThreat then return false end
    moved, reason = Tactics.AvoidThreat(record, zombie, target, {
        radius = threatContext.radius,
        reason = "threat_guard_avoid",
    })
    if not moved then return false end
    state.phase = "avoid"
    record.activeBehavior = "CombatGuard:avoid"
    Common.ClearCombatTarget(record, "threat_guard_avoid", zombie)
    Internal.LogTransition("avoid", record, zombie, state, target, reason)
    return true
end

function Internal.EngageTarget(record, zombie, target, threatContext)
    local result
    if Companion and Companion.Internal
        and Companion.Internal.EngageResolvedTarget
    then
        result = Companion.Internal.EngageResolvedTarget(
            record,
            zombie,
            target,
            threatContext
        )
        return result ~= false
    end
    if PNC.BehaviorCombat and PNC.BehaviorCombat.TickEngage then
        result = PNC.BehaviorCombat.TickEngage(record, zombie, target)
        return result ~= false
    end
    return false
end

function Internal.Engage(record, zombie, state, target, threatContext)
    local scene = record.runtime and record.runtime.animationScene or nil
    local runtime = record.runtime or {}
    if target.alertOnly == true then
        return Internal.AlertTarget(record, zombie, state, target)
    end
    if not Internal.CanAttackTarget(record, target) then
        if Internal.EnterAvoidance(
            record,
            zombie,
            state,
            target,
            threatContext
        ) then
            return true
        end
        return Internal.AlertTarget(record, zombie, state, target)
    end
    if scene and not preserveTravelConversationScene(record, scene) then
        if not releaseCombatScene(record, zombie, scene) then
            return false
        end
    end
    -- Stopping a sleep scene is intentionally two-phase: the facility owner
    -- must release the native bed/resting carrier before combat can use it.
    -- Let the facility wake pump own this tick; the wake callback preserves a
    -- bounded self-defense threat for the next combat tick.
    if runtime.facilityActivity
        and runtime.facilityActivity.sleepWakePending == true
    then
        return false
    end
    state.phase = "engaged"
    state.target = target
    if not Common.SetCombatTarget(
        record,
        target,
        "threat_guard"
    ) then
        return false
    end
    record.activeBehavior = "CombatGuard:engaged"
    if not Internal.EngageTarget(record, zombie, target, threatContext) then
        Common.ClearCombatTarget(record, "threat_guard_engage_failed", zombie)
        return false
    end
    Internal.LogTransition(
        "enter",
        record,
        zombie,
        state,
        target,
        "target_acquired"
    )
    return true
end

return ThreatGuard
