PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = PNC.EnginePathPlanner.Internal
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics
local NATIVE_AUDIT_REPEAT_MS = 1000

local function shouldSampleNativeAudit(record, body, navigation, force)
    local runtime
    local audit
    local stateName
    local hasPath
    local moving
    local nativeActive
    local now
    local repeatMs
    if force == true or not record then return true end
    runtime = record.runtime or {}
    record.runtime = runtime
    audit = runtime.nativeHandoffAudit or {}
    runtime.nativeHandoffAudit = audit
    stateName = Internal.GetEngineStateName(body)
    hasPath = body and body.getPath2 and body:getPath2() ~= nil or false
    moving = body and body.isMoving and body:isMoving() == true or false
    nativeActive = navigation and navigation.nativeActive == true or false
    now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    repeatMs = (hasPath or nativeActive) and 250 or NATIVE_AUDIT_REPEAT_MS
    if audit.stateName == stateName
        and audit.hasPath == hasPath
        and audit.moving == moving
        and audit.nativeActive == nativeActive
        and audit.controllerMode == (navigation
            and navigation.controllerMode or "")
        and now - (tonumber(audit.at) or 0) < repeatMs
    then
        return false
    end
    audit.stateName = stateName
    audit.hasPath = hasPath
    audit.moving = moving
    audit.nativeActive = nativeActive
    audit.controllerMode = navigation and navigation.controllerMode or ""
    audit.at = now
    return true
end

function Internal.GetEngineStateName(body)
    if not body then return "" end
    if body.getCurrentStateName then
        return string.lower(tostring(body:getCurrentStateName() or ""))
    end
    -- Compatibility fallback for isolated test doubles and older bridges.
    return body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or "")) or ""
end

function Internal.IsNativeWalkTowardState(stateName)
    stateName = string.lower(tostring(stateName or ""))
    return stateName == "walktoward"
        or stateName == "walktowardstate"
        or stateName == "walktowardnetwork"
        or stateName == "walktowardnetworkstate"
end

local function isSuspiciousNativeBoundary(body)
    return Internal.IsNativeWalkTowardState(
        Internal.GetEngineStateName(body)
    )
end

function Internal.RecordNativeHandoff(
    record,
    body,
    eventName,
    navigation,
    extra,
    force
)
    if not Diagnostics
        or Diagnostics.NativeHandoffAuditEnabled ~= true
        or not Diagnostics.LogNativeHandoff
        or (force ~= true and not isSuspiciousNativeBoundary(body))
        or not shouldSampleNativeAudit(record, body, navigation, force)
    then
        return false
    end
    return Diagnostics.LogNativeHandoff(
        record,
        body,
        eventName,
        "native_path",
        navigation,
        extra
    )
end

function Internal.GetPathBehavior(body)
    return body and body.getPathFindBehavior2
        and body:getPathFindBehavior2() or nil
end

-- Match ZAMove.onWorking's collision gate. A manual Behavior2 owner must not
-- advance another frame after contact; PathService gets that frame to adopt
-- the door/window/fence into its safe scripted traversal lane.
function Internal.IsBodyCollided(body)
    if not body then return false end
    local collidedWithDoor = body.isCollidedWithDoor
    if type(collidedWithDoor) == "function"
        and collidedWithDoor(body) == true
    then
        return true
    end
    local collidedThisFrame = body.isCollidedThisFrame
    if type(collidedThisFrame) == "function"
        and collidedThisFrame(body) == true
    then
        return true
    end
    local collided = body.isCollided
    return type(collided) == "function"
        and collided(body) == true
        or collided == true
end

function Internal.GetNativeTraversalState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    if state == "climbfence"
        or state == "climbwindow"
        or state == "climbwall"
    then
        return state
    end
    return nil
end

function Internal.GetNativeMovementState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    if state == "pathfind" then return state end
    return Internal.GetNativeTraversalState(body)
end

-- Hoomans owns the single-player Behavior2 pump directly from Lua. Keep the
-- vanilla WalkTowardState out of that route once a native path is actually
-- published: IsoGameCharacter's deferred movement guard discards path2
-- whenever WalkTowardState is still active. Do not clear WalkTowardState
-- before path2 exists, because that is the vanilla follow/request owner while
-- Behavior2 is still acquiring the route. Releasing only this stale state is
-- important; entering PathFindState would make Java execute Behavior2 a second
-- time during the same update.
function Internal.EnsureNativeMovementOwner(body, boundary, record)
    local engineState
    if not body
        or (not body.getCurrentStateName and not body.getActionStateName)
    then
        return false
    end
    engineState = Internal.GetEngineStateName(body)
    if not Internal.IsNativeWalkTowardState(engineState)
        or not body.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    if body.getPath2 and body:getPath2() == nil then
        return false
    end
    Internal.RecordNativeHandoff(
        record,
        body,
        "walktoward_conflict_before",
        record and record.runtime and record.runtime.localNavigation or nil,
        "boundary=" .. tostring(boundary or "unknown")
    )
    body:changeState(ZombieIdleState.instance())
    -- IsoGameCharacter.doDeferredMovement only rejects path2 when the legacy
    -- AI state is still WalkTowardState. Keep the movement flag untouched:
    -- Behavior2 has just set it to true and the native route still owns the
    -- locomotion presentation. Clearing it here creates the idle/walk fight
    -- this fence is intended to prevent.
    Internal.RecordNativeHandoff(
        record,
        body,
        "walktoward_conflict_after",
        record and record.runtime and record.runtime.localNavigation or nil,
        "boundary=" .. tostring(boundary or "unknown"),
        true
    )
    return true
end

-- Public boundary for managed-body callbacks. The planner pump also uses the
-- internal helper, but the engine can recreate WalkTowardState after
-- Behavior2 publishes path2. This repairs the state for the next engine
-- frame; the generic animation ownership fence is what prevents the conflict
-- from being recreated during the current frame.
function Planner.ReconcileNativeMovementOwner(body, record, boundary)
    return Internal.EnsureNativeMovementOwner(body, boundary or "reconcile", record)
end

local function hasOwnedNativeAction(record, body, now)
    local animation = PNC.Animation
    local runtime = record and record.runtime or nil
    local attackAction = runtime and runtime.attackAction or nil
    local pathing = runtime and runtime.pathing or nil
    if animation and animation.IsBumpActionActive
        and animation.IsBumpActionActive(body, now)
    then
        return true
    end
    if attackAction
        and now < (tonumber(attackAction.finishAt) or 0)
    then
        return true
    end
    if pathing and (pathing.traversalAction or pathing.vanillaFenceAction) then
        return true
    end
    return false
end

local function releaseStaleBumpedState(body)
    if not body then return end
    if body.setBumpDone then
        body:setBumpDone(true)
    end
    if body.setVariable then
        body:setVariable("BumpDone", true)
        body:setVariable("BumpAnimFinished", true)
    end
    if body.reportEvent then
        body:reportEvent("ActiveAnimFinishing")
    end
    if body.setBumpType then
        body:setBumpType("")
    end
    if body.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        body:changeState(ZombieIdleState.instance())
    end
end

-- Behavior2 can leave the vanilla BumpedState active while path2 remains
-- published. That state owns the Java animation loop and prevents the native
-- route from making progress. Only repair it after a short observation grace
-- period, and only when no PNC action or traversal owns the bump.
function Internal.RecoverStaleNativeBump(record, body, navigation, now)
    local actionState
    local startedAt
    local lane
    local recoveryCount
    local backoffMs
    if not navigation
        or navigation.nativeActive ~= true
        or not body
        or not body.getActionStateName
    then
        return false, nil
    end
    actionState = string.lower(tostring(body:getActionStateName() or ""))
    if actionState ~= "bumped" then
        navigation.nativeBumpStartedAt = 0
        return false, nil
    end
    now = tonumber(now) or 0
    if hasOwnedNativeAction(record, body, now) then
        navigation.nativeBumpStartedAt = 0
        return false, nil
    end
    startedAt = tonumber(navigation.nativeBumpStartedAt) or 0
    if startedAt <= 0 then
        navigation.nativeBumpStartedAt = now
        return false, nil
    end
    if now - startedAt < math.max(
        250,
        tonumber(Const.NATIVE_BUMP_STALE_GRACE_MS)
            or tonumber(Const.BUMP_RELEASE_HARD_TIMEOUT_MS)
            or 750
    ) then
        return false, nil
    end

    releaseStaleBumpedState(body)
    lane = record and record.runtime and record.runtime.pathing or nil
    recoveryCount = (tonumber(lane and lane.nativeStallRecoveryCount) or 0) + 1
    if lane then
        lane.nativeStallRecoveryCount = recoveryCount
        lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
        lane.lastRecoveryReason = "native_stale_bumped"
        lane.lastRecoverAt = now
    end
    backoffMs = math.max(
        1000,
        tonumber(Const.NATIVE_STALL_BACKOFF_MS) or 5000
    )
    if lane and recoveryCount >= 2 then
        lane.nativeBackoffUntil = now + backoffMs
        lane.ownerMode = "native_backoff"
        lane.blockReason = "native_stall_backoff"
    elseif lane then
        lane.nativeBackoffUntil = 0
        lane.ownerMode = "engine_path_waiting"
        lane.blockReason = "native_stale_bumped"
    end
    navigation.nativeBumpStartedAt = 0
    navigation.nativeBumpRecoveryAt = now
    if recoveryCount >= 2 then
        return true, "native_stall_backoff"
    end
    return true, "native_stale_bump_released"
end

function Internal.InvalidateRecoveredNativeBump(
    record,
    body,
    navigation,
    reason
)
    reason = reason or "native_stale_bump_released"
    if Planner.Invalidate then
        Planner.Invalidate(record, reason, body)
    elseif Internal.ClearEngineRequest then
        Internal.ClearEngineRequest(body, navigation)
        navigation.plannedAt = 0
    else
        navigation.nativeActive = false
        navigation.requestPending = false
        navigation.plannedAt = 0
    end
    navigation.lastPlanReason = reason
    return true
end

function Internal.IsAtRequestGoal(body, navigation)
    if not body or not navigation then return false end
    local requestZ = tonumber(navigation.requestZ) or body:getZ()
    if math.abs(body:getZ() - requestZ) >= 0.5 then return false end
    local dx = (tonumber(navigation.requestX) or body:getX()) - body:getX()
    local dy = (tonumber(navigation.requestY) or body:getY()) - body:getY()
    local stopDistance = math.max(
        0.1,
        tonumber(navigation.requestStopDistance) or 0.7
    )
    return (dx * dx) + (dy * dy) <= stopDistance * stopDistance
end

function Internal.ResultMatches(result, name)
    if BehaviorResult and BehaviorResult[name] ~= nil then
        return result == BehaviorResult[name]
    end
    local value = tostring(result or "")
    return value == name or value == ("BehaviorResult." .. name)
end

return Internal
