local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Const = PNC.Const or {}
local Scenes = PNC.AnimationScenes
local Diagnostics = PNC.PerformanceScalingDiagnostics

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

Internal.PublishZombieGroupAlert = publishZombieGroupAlert
Internal.AuditDecision = auditDecision
Internal.RetainableTarget = retainableTarget
Internal.PreserveTravelConversationScene = preserveTravelConversationScene
Internal.ReleaseCombatScene = releaseCombatScene
Internal.AlertTargetKey = alertTargetKey
Internal.ReleaseAlertScene = releaseAlertScene

return ThreatGuard
