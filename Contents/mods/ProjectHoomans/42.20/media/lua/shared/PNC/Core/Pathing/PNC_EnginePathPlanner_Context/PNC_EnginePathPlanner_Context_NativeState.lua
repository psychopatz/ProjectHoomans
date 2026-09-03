PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = PNC.EnginePathPlanner.Internal
local Const = PNC.Const or {}

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
-- vanilla WalkTowardState out of that route: IsoGameCharacter's deferred
-- movement guard discards path2 whenever WalkTowardState is still active.
-- Releasing only these stale states is important; entering PathFindState would
-- make Java execute Behavior2 a second time during the same update.
function Internal.EnsureNativeMovementOwner(body)
    local actionState
    if not body or not body.getActionStateName then
        return false
    end
    actionState = string.lower(tostring(body:getActionStateName() or ""))
    if actionState ~= "walktoward" and actionState ~= "turnalerted"
        or not body.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    if actionState == "turnalerted" and body.setTurnAlertedValues then
        body:setTurnAlertedValues(0, 0)
    end
    body:changeState(ZombieIdleState.instance())
    return true
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
