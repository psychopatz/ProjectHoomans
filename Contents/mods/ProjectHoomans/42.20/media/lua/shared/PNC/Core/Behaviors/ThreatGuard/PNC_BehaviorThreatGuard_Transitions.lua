-- Threat-guard state transitions, combat handoff, and release.

local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Const = PNC.Const or {}
local Targeting = PNC.BehaviorTargeting
local Companion = PNC.BehaviorCompanion
local Common = PNC.BehaviorCommon
local Scenes = PNC.AnimationScenes
local Tactics = PNC.CombatTactics
local Diagnostics = PNC.PerformanceScalingDiagnostics

local SCAN_MS = Internal.SCAN_MS
local VALIDATE_MS = Internal.VALIDATE_MS

local function preserveTravelConversationScene(record, scene)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    return scene
        and scene.id == "social.conversation"
        and lease
        and lease.travelHold == true
end

-- A scene callback can replace the scene with a native wake transaction (the
-- bed/sleep path does this).  Treat a blocking scene that survives the normal
-- interrupt as a failed combat handoff instead of claiming the combat lane
-- while the presentation still owns the body.
local function releaseCombatScene(record, zombie, scene)
    local runtime = record and record.runtime or nil
    local remaining
    if not runtime or not scene then return true end
    if Scenes and Scenes.Interrupt then
        Scenes.Interrupt(record, zombie, "combat")
    end
    remaining = runtime.animationScene
    if remaining == scene
        and remaining.blocking == true
        and Scenes
        and Scenes.Stop
    then
        Scenes.Stop(record, zombie, "threat_guard_combat")
        remaining = runtime.animationScene
    end
    return not remaining or remaining.blocking ~= true
end

function Internal.LogTransition(eventName, record, zombie, state, target, reason)
    local runtime = record and record.runtime or {}
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local action = zombie and zombie.getActionStateName
        and zombie:getActionStateName() or ""
    local nativeTarget = zombie and zombie.getTarget
        and zombie:getTarget() ~= nil or false
    if not Diagnostics or Diagnostics.SeatingAuditEnabled ~= true
        or not Diagnostics.LogSeatingAudit
    then
        return
    end
    Diagnostics.LogSeatingAudit("threat_guard_" .. tostring(eventName), {
        "npc=" .. tostring(record and record.id or ""),
        "order=" .. tostring(record and record.orderSpec
            and record.orderSpec.kind or ""),
        "job=" .. tostring(record and record.activeJob or ""),
        "behavior=" .. tostring(record and record.activeBehavior or ""),
        "source=" .. tostring(state and state.source or ""),
        "owner=" .. tostring(state and state.ownerKind or ""),
        "phase=" .. tostring(state and state.phase or ""),
        "targetId=" .. tostring(target and (target.zombieId
            or target.id or target.onlineID) or ""),
        "targetKind=" .. tostring(target and target.kind or ""),
        "targetThreatening=" .. tostring(target
            and target.threatening == true),
        "targetSource=" .. tostring(runtime.targetSource or ""),
        "attackType=" .. tostring(record and record.attackType or ""),
        "scene=" .. tostring(runtime.animationScene
            and runtime.animationScene.id or ""),
        "nativeAction=" .. tostring(action or ""),
        "nativeTarget=" .. tostring(nativeTarget),
        "nativeBump=" .. tostring(modData
            and modData.PNC_BumpRequestedType or ""),
        "reason=" .. tostring(reason or ""),
    })
end

function Internal.RefreshTarget(record, state, threatContext, now)
    local runtime = record.runtime or {}
    local current = state.target or runtime.target
    local candidate
    if current and Targeting and Targeting.UpdateTargetFromWorld then
        if now >= (tonumber(state.nextValidateAt) or 0) then
            current = Targeting.UpdateTargetFromWorld(record, current)
            state.nextValidateAt = now + VALIDATE_MS
        end
        if Internal.IsThreat(current, threatContext) then
            return current
        end
    end
    runtime.target = nil
    runtime.targetSource = nil
    runtime.targetAt = nil
    state.target = nil
    if now < (tonumber(state.nextScanAt) or 0) then return nil end
    state.nextScanAt = now + SCAN_MS
    if Targeting and Targeting.ResolveImmediateNPCThreat then
        candidate = Targeting.ResolveImmediateNPCThreat(record)
        if Internal.IsThreat(candidate, threatContext) then
            return candidate
        end
    end
    if Targeting and Targeting.ResolveImmediateZombieThreat then
        candidate = Targeting.ResolveImmediateZombieThreat(record)
        if Internal.IsThreat(candidate, threatContext) then
            return candidate
        end
    end
    if Companion and Companion.Internal
        and Companion.Internal.ResolveThreatTarget
    then
        candidate = Companion.Internal.ResolveThreatTarget(
            record,
            threatContext,
            { areaDefense = true }
        )
    elseif Targeting and Targeting.ResolveRoamingEngageTarget then
        candidate = Targeting.ResolveRoamingEngageTarget(
            record,
            threatContext.radius
        )
    end
    if Internal.IsThreat(candidate, threatContext) then return candidate end
    return nil
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
    if not Internal.AttackEnabled(record) then
        return Internal.EnterAvoidance(
            record,
            zombie,
            state,
            target,
            threatContext
        )
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
