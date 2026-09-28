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

local function publishZombieGroupAlert(record, target, now)
    local zombie
    if not target or target.kind ~= "zombie"
        or not PNC.Perception
        or not PNC.Perception.PublishZombieGroupAlert
        or not PNC.Perception.FindZombieByID
    then
        return
    end
    zombie = PNC.Perception.FindZombieByID(target.zombieId)
    if zombie and not zombie:isDead() then
        PNC.Perception.PublishZombieGroupAlert(record, zombie, now)
    end
end

local function auditDecision(eventName, record, zombie, target, reason)
    local runtime
    local state
    local now
    local key
    if not Diagnostics or Diagnostics.NPCThreatAuditEnabled ~= true
        or not Diagnostics.LogNPCThreatAudit or not record
    then
        return
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    state = runtime.npcThreatAudit or {}
    runtime.npcThreatAudit = state
    now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    key = tostring(eventName or "decision") .. "|"
        .. tostring(reason or "") .. "|"
        .. tostring(target and target.kind or "none") .. "|"
        .. tostring(target and (target.zombieId or target.id) or "")
    if state.key == key and now - (tonumber(state.at) or 0) < 500 then
        return
    end
    state.key = key
    state.at = now
    Diagnostics.LogNPCThreatAudit(eventName, {
        "authority=" .. tostring(PNC.Core and PNC.Core.IsAuthority
            and PNC.Core.IsAuthority() or "unknown"),
        "npc=" .. tostring(record.id or ""),
        "behavior=" .. tostring(record.activeBehavior or ""),
        "targetKind=" .. tostring(target and target.kind or ""),
        "targetId=" .. tostring(target
            and (target.zombieId or target.id or target.onlineID) or ""),
        "distance=" .. tostring(target and target.distSq
            and math.sqrt(tonumber(target.distSq) or 0) or ""),
        "visible=" .. tostring(target and target.visible == true),
        "proximityAlert=" .. tostring(target
            and target.proximityAlert == true),
        "alertOnly=" .. tostring(target and target.alertOnly == true),
        "threatening=" .. tostring(target and target.threatening == true),
        "nativeTarget=" .. tostring(zombie and zombie.getTarget
            and zombie:getTarget() ~= nil or false),
        "action=" .. tostring(zombie and zombie.getActionStateName
            and zombie:getActionStateName() or ""),
        "pathPhase=" .. tostring(record.runtime
            and record.runtime.pathing and record.runtime.pathing.phase or ""),
        "reason=" .. tostring(reason or ""),
    })
end

local function retainableTarget(target, now, threatContext)
    local retainMs
    local dx
    local dy
    if not target or target.kind ~= "zombie" then return false end
    retainMs = tonumber(Const.THREAT_GUARD_TARGET_RETAIN_MS) or 3500
    if now - (tonumber(target.lastSeenAt) or 0) > retainMs then
        return false
    end
    if tonumber(target.z) ~= nil
        and math.abs((tonumber(target.z) or 0) - threatContext.z) >= 1
    then
        return false
    end
    dx = (tonumber(target.x) or 0) - threatContext.x
    dy = (tonumber(target.y) or 0) - threatContext.y
    if dx * dx + dy * dy > threatContext.radius * threatContext.radius then
        return false
    end
    target.visible = false
    target.alertOnly = true
    return true
end

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

local function alertTargetKey(target)
    if not target then return "" end
    return tostring(target.kind or "") .. "|"
        .. tostring(target.zombieId or target.id or target.onlineID or "")
        .. "|" .. tostring(target.alertSequence or target.lastSeenAt or "")
end

-- Alert-only targets are intentionally conservative about movement: the
-- recipient has heard a nearby threat but has not confirmed line of sight.
-- They must still be able to stand up from a seat/sleep/ground scene. Retry
-- the handoff at a bounded cadence if a native wake transaction still owns
-- the body; do not call Interrupt/Stop on every behavior tick.
local function releaseAlertScene(record, zombie, now)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local sceneKey
    local released
    if not runtime then return true end
    if not scene or scene.blocking ~= true
        or preserveTravelConversationScene(record, scene)
    then
        if not scene then
            runtime.threatGuardAlertSceneKey = nil
            runtime.threatGuardAlertSceneNextAt = nil
        end
        return true
    end
    sceneKey = tostring(scene.revision or scene.id or scene)
    if runtime.threatGuardAlertSceneKey ~= sceneKey then
        runtime.threatGuardAlertSceneKey = sceneKey
        runtime.threatGuardAlertSceneNextAt = 0
    end
    if now < (tonumber(runtime.threatGuardAlertSceneNextAt) or 0) then
        return runtime.animationScene ~= scene
            or scene.blocking ~= true
    end
    released = releaseCombatScene(record, zombie, scene)
    runtime.threatGuardAlertSceneNextAt = now + 250
    return released
end

function Internal.LogTransition(eventName, record, zombie, state, target, reason)
    local runtime = record and record.runtime or {}
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local action = zombie and zombie.getActionStateName
        and zombie:getActionStateName() or ""
    local nativeTarget = zombie and zombie.getTarget
        and zombie:getTarget() ~= nil or false
    if Diagnostics and Diagnostics.NPCThreatAuditEnabled == true
        and Diagnostics.LogNPCThreatAudit
    then
        Diagnostics.LogNPCThreatAudit("threat_guard_" .. tostring(eventName), {
            "npc=" .. tostring(record and record.id or ""),
            "behavior=" .. tostring(record and record.activeBehavior or ""),
            "source=" .. tostring(state and state.source or ""),
            "phase=" .. tostring(state and state.phase or ""),
            "targetId=" .. tostring(target and (target.zombieId
                or target.id or target.onlineID) or ""),
            "targetKind=" .. tostring(target and target.kind or ""),
            "targetThreatening=" .. tostring(target
                and target.threatening == true),
            "proximityAlert=" .. tostring(target
                and target.proximityAlert == true),
            "alertOnly=" .. tostring(target and target.alertOnly == true),
            "targetSource=" .. tostring(runtime.targetSource or ""),
            "attackType=" .. tostring(record and record.attackType or ""),
            "nativeAction=" .. tostring(action or ""),
            "nativeTarget=" .. tostring(nativeTarget),
            "reason=" .. tostring(reason or ""),
        })
        return
    end
    if not Diagnostics or Diagnostics.SeatingAuditEnabled ~= true
        or not Diagnostics.LogSeatingAudit then
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
    local options
    if current and Targeting and Targeting.UpdateTargetFromWorld then
        if now >= (tonumber(state.nextValidateAt) or 0) then
            current = Targeting.UpdateTargetFromWorld(record, current)
            state.nextValidateAt = now + VALIDATE_MS
        end
        if Internal.IsThreat(current, threatContext) then
            auditDecision("target_valid", record, nil, current, "validated")
            return current
        end
        if retainableTarget(current, now, threatContext) then
            auditDecision("target_retained", record, nil, current,
                "visibility_or_registry_gap")
            return current
        end
    end
    if state.target and retainableTarget(state.target, now, threatContext) then
        auditDecision("target_retained", record, nil, state.target,
            "refresh_returned_nil")
        return state.target
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
            auditDecision("target_acquired", record, nil, candidate,
                "immediate_npc")
            return candidate
        end
    end
    if Targeting and Targeting.ResolveImmediateZombieThreat then
        candidate = Targeting.ResolveImmediateZombieThreat(record)
        if Internal.IsThreat(candidate, threatContext) then
            publishZombieGroupAlert(record, candidate, now)
            auditDecision("target_acquired", record, nil, candidate,
                "immediate_zombie")
            return candidate
        end
    end
    if PNC.Perception and PNC.Perception.FindProximityZombieAlert then
        candidate = PNC.Perception.FindProximityZombieAlert(
            record,
            threatContext.radius
        )
        if Internal.IsThreat(candidate, threatContext) then
            auditDecision("target_acquired", record, nil, candidate,
                candidate.alertOnly and "group_alert" or "proximity")
            return candidate
        end
    end
    options = {
        areaDefense = threatContext.targetPolicy ~= "owner",
    }
    if threatContext.targetPolicy == "owner" then
        options.ownerEngaged = runtime.followState
            and runtime.followState.ownerEngaged == true or false
    end
    if Companion and Companion.Internal
        and Companion.Internal.ResolveThreatTarget
    then
        candidate = Companion.Internal.ResolveThreatTarget(
            record,
            threatContext,
            options
        )
    elseif threatContext.targetPolicy == "owner"
        and Targeting
        and Targeting.ResolveCompanionProtectionTarget
    then
        candidate = Targeting.ResolveCompanionProtectionTarget(
            record,
            options.ownerEngaged
        )
    elseif Targeting and Targeting.ResolveRoamingEngageTarget then
        candidate = Targeting.ResolveRoamingEngageTarget(
            record,
            threatContext.radius
        )
    end
    if Internal.IsThreat(candidate, threatContext) then
        auditDecision("target_acquired", record, nil, candidate,
            "resolver")
        return candidate
    end
    auditDecision("target_rejected", record, nil, candidate, "no_eligible_threat")
    return nil
end

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
