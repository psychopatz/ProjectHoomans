local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Const = PNC.Const or {}
local Targeting = PNC.BehaviorTargeting
local Companion = PNC.BehaviorCompanion
local Diagnostics = PNC.PerformanceScalingDiagnostics
local SCAN_MS = Internal.SCAN_MS
local VALIDATE_MS = Internal.VALIDATE_MS
local publishZombieGroupAlert = Internal.PublishZombieGroupAlert
local auditDecision = Internal.AuditDecision
local retainableTarget = Internal.RetainableTarget

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
    if PNC.Perception and PNC.Perception.FindNPCGroupAlert then
        candidate = PNC.Perception.FindNPCGroupAlert(
            record,
            math.max(
                tonumber(threatContext.radius) or 0,
                tonumber(Const.NPC_GROUP_ALERT_RADIUS) or 0
            ),
            true
        )
        if Internal.IsThreat(candidate, threatContext) then
            auditDecision("target_acquired", record, nil, candidate,
                "npc_group_alert")
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

return ThreatGuard
