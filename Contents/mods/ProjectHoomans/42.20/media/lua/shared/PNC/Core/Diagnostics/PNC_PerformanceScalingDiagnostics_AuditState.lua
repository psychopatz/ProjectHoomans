PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Diagnostics.LogSeatingState(
    eventName,
    record,
    zombie,
    scene,
    reason,
    extra
)
    local runtime
    local state
    local path
    local navigation
    local followState
    local intent
    local fields
    local bodyX
    local bodyY
    local bodyZ
    if Diagnostics.SeatingAuditEnabled ~= true then return false end
    runtime = record and record.runtime or nil
    if not Diagnostics.IsSeatingRuntime(runtime, scene) then return false end
    state = runtime and runtime.facilityActivity
        and runtime.facilityActivity.seating == true
        and runtime.facilityActivity
        or runtime and runtime.roamingSeat
    path = runtime and runtime.pathing or nil
    navigation = runtime and runtime.localNavigation or nil
    followState = runtime and runtime.followState or nil
    intent = runtime and runtime.moveIntent or nil
    bodyX = zombie and zombie.getX and zombie:getX() or ""
    bodyY = zombie and zombie.getY and zombie:getY() or ""
    bodyZ = zombie and zombie.getZ and zombie:getZ() or ""
    fields = {
        "npc=" .. tostring(record and record.id or ""),
        "seatSession=" .. tostring(state and state.seatSessionId or ""),
        "controller=" .. tostring(runtime and runtime.facilityActivity
            and runtime.facilityActivity.seating == true
            and "facility" or runtime and runtime.roamingSeat
            and "roaming" or "scene_only"),
        "scene=" .. tostring(scene and scene.id
            or runtime and runtime.animationScene
            and runtime.animationScene.id or ""),
        "sceneRevision=" .. tostring(scene and scene.revision
            or runtime and runtime.animationScene
            and runtime.animationScene.revision or ""),
        "phase=" .. tostring(state and state.phase or ""),
        "seatState=" .. tostring(state and state.seatState or ""),
        "seatEntered=" .. tostring(state and state.seatEntered == true),
        "positioned=" .. tostring(state and state.positioned == true),
        "resourceKey=" .. tostring(state and state.resourceKey or ""),
        "reservationId=" .. tostring(state and state.reservationId or ""),
        "approachKey=" .. tostring(state and state.approachKey or ""),
        "pathPhase=" .. tostring(path and path.phase or ""),
        "pathOwnerMode=" .. tostring(path and path.ownerMode or ""),
        "pathReason=" .. tostring(path and path.lastProgressReason or ""),
        "moveKind=" .. tostring(intent and intent.kind or ""),
        "moveReason=" .. tostring(intent and intent.reason or ""),
        "moveRevision=" .. tostring(intent and intent.revision or ""),
        "nativeActive=" .. tostring(navigation
            and navigation.nativeActive == true),
        "nativeTraversal=" .. tostring(navigation
            and navigation.nativeTraversalState or ""),
        "followOwnerMoving=" .. tostring(followState
            and followState.ownerMoving == true),
        "bodyAction=" .. tostring(zombie and zombie.getActionStateName
            and zombie:getActionStateName() or ""),
        "bodyX=" .. tostring(bodyX),
        "bodyY=" .. tostring(bodyY),
        "bodyZ=" .. tostring(bodyZ),
        "recordX=" .. tostring(record and record.x or ""),
        "recordY=" .. tostring(record and record.y or ""),
        "recordZ=" .. tostring(record and record.z or ""),
        "reason=" .. tostring(reason or ""),
    }
    for _, field in ipairs(extra or {}) do fields[#fields + 1] = tostring(field) end
    return Diagnostics.LogSeatingAudit(eventName, fields)
end

-- Sleep state snapshot for the bed/sofa handoff trace. Callers guard this
-- function before assembling event-specific fields so the disabled path stays
-- allocation-free on the normal facility tick.
function Diagnostics.LogSleepState(
    eventName,
    record,
    zombie,
    scene,
    reason,
    extra
)
    local runtime
    local animationScene
    local modData
    local actionState
    local contextState
    local bump
    local bodyX
    local bodyY
    local bodyZ
    local fields
    if Diagnostics.SleepAuditEnabled ~= true then return false end
    runtime = record and record.runtime or {}
    animationScene = scene or runtime.animationScene
    modData = zombie and zombie.getModData and zombie:getModData() or nil
    actionState = zombie and zombie.getActionStateName
        and zombie:getActionStateName() or ""
    contextState = PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionContextStateName
        and PNC.LiveBodyControl.GetActionContextStateName(zombie) or ""
    bump = zombie and zombie.getBumpType and zombie:getBumpType()
        or modData and modData.PNC_BumpRequestedType or ""
    bodyX = zombie and zombie.getX and zombie:getX() or ""
    bodyY = zombie and zombie.getY and zombie:getY() or ""
    bodyZ = zombie and zombie.getZ and zombie:getZ() or ""
    fields = {
        "npc=" .. tostring(record and record.id or ""),
        "surface=" .. tostring(runtime.sleepSurface or ""),
        "resourceKey=" .. tostring(runtime.resourceKey or ""),
        "scene=" .. tostring(animationScene and animationScene.id or ""),
        "sceneBump=" .. tostring(animationScene and animationScene.bump or ""),
        "sceneActive=" .. tostring(runtime.sleepSceneActive == true
            or animationScene ~= nil),
        "phase=" .. tostring(runtime.phase or ""),
        "arrivalSettled=" .. tostring(runtime.arrivalSettled == true),
        "positioned=" .. tostring(runtime.positioned == true),
        "surfaceEntered=" .. tostring(runtime.sleepSurfaceEntered == true),
        "sleepWakePending=" .. tostring(runtime.sleepWakePending == true),
        "startupAttempts=" .. tostring(runtime.startupAttempts or 0),
        "interruptReason=" .. tostring(runtime.interruptReason or ""),
        "failedReason=" .. tostring(runtime.failedReason or ""),
        "action=" .. tostring(actionState),
        "context=" .. tostring(contextState),
        "bump=" .. tostring(bump or ""),
        "requestedBump=" .. tostring(modData
            and modData.PNC_BumpRequestedType or ""),
        "bumpLease=" .. tostring(modData
            and modData.PNC_BumpActionLease == true or false),
        "bedAssigned=" .. tostring(zombie and zombie.getBed
            and zombie:getBed() ~= nil or false),
        "onBed=" .. tostring(zombie and zombie.getVariableBoolean
            and zombie:getVariableBoolean("OnBed") == true or false),
        "sittingOnFurniture=" .. tostring(zombie
            and zombie.getVariableBoolean
            and zombie:getVariableBoolean("SittingOnFurniture") == true
            or false),
        "bodyX=" .. tostring(bodyX),
        "bodyY=" .. tostring(bodyY),
        "bodyZ=" .. tostring(bodyZ),
        "recordX=" .. tostring(record and record.x or ""),
        "recordY=" .. tostring(record and record.y or ""),
        "recordZ=" .. tostring(record and record.z or ""),
        "reason=" .. tostring(reason or ""),
    }
    for _, field in ipairs(extra or {}) do fields[#fields + 1] = tostring(field) end
    return Diagnostics.LogSleepAudit(eventName, fields)
end

-- Follower presence auditing is intentionally separate from the general
-- performance and seating streams. Callers must check the gate before
-- assembling fields so disabled gameplay pays only a boolean check.
function Diagnostics.LogFollowerPresence(eventName, fields)
    local output
    if Diagnostics.FollowerPresenceAuditEnabled ~= true then return false end
    output = { "follower_presence", "event=" .. tostring(eventName or "unknown") }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

-- Callers guard this function before assembling fields so disabled gameplay
-- pays only a boolean check.
function Diagnostics.LogFollowerAbandonment(eventName, fields)
    local output
    if Diagnostics.FollowerAbandonmentAuditEnabled ~= true then return false end
    output = {
        "follower_abandonment",
        "event=" .. tostring(eventName or "unknown"),
    }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end


return Diagnostics
