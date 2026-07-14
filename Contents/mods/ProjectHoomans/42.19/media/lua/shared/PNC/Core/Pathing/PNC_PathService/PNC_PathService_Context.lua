--[[
    PNC Path Service Context
    Shared constants and core helpers for the split pathing subsystem.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local Core = PNC.Core
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local FakeLocomotion = PNC.FakeLocomotion
local LocomotionProfiles = PNC.LocomotionProfiles
local MotionHints = PNC.MotionHints
local TraversalQuery = PNC.TraversalQuery

Internal.Core = Core
Internal.Animation = Animation
Internal.LiveBodyControl = LiveBodyControl
Internal.FakeLocomotion = FakeLocomotion
Internal.LocomotionProfiles = LocomotionProfiles
Internal.MotionHints = MotionHints
Internal.TraversalQuery = TraversalQuery

Internal.GOAL_REFRESH_DELAY_MS = 120
Internal.PROGRESS_TIMEOUT_MS = 2200
Internal.INTERACTION_STALL_MS = 260
Internal.SPECIAL_ACTION_COOLDOWN_MS = 1500
Internal.TRAVERSAL_REPEAT_COOLDOWN_MS = 2400
Internal.TRAVERSAL_PROGRESS_CLEAR_DISTANCE = 1.35
Internal.RUN_START_DISTANCE = 4.50
Internal.RUN_STOP_DISTANCE = 2.90
Internal.FACE_REAPPLY_INTERVAL_MS = 90
Internal.FACE_SIMILAR_DOT = 0.985
Internal.FACE_MIN_DISTANCE_SQ = 0.0036
Internal.COMBAT_FACING_DEFAULT_MS = 180
Internal.NON_LOCOMOTION_RECOVERY_MS = 240
Internal.LOCOMOTION_VISUAL_LEASE_MS = 420

local ALLOWED_MOVE_ACTION_STATES = {
    [""] = true,
    ["idle"] = true,
    ["walktoward"] = true,
}

function Internal.roundHalf(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function Internal.getSquare(x, y, z)
    if not getCell then
        return nil
    end
    return getCell():getGridSquare(math.floor(x), math.floor(y), z)
end

function Internal.isSquareWalkable(x, y, z)
    if TraversalQuery and TraversalQuery.CanOccupy then
        return TraversalQuery.CanOccupy(x, y, z)
    end
    return false
end

function Internal.syncRecordPosition(record, zombie)
    if not record or not zombie then
        return
    end
    record.x = zombie:getX()
    record.y = zombie:getY()
    record.z = zombie:getZ()
end

function Internal.isMovementDebugEnabled(record)
    if Core and Core.IsRecordDebugEnabled then
        return Core.IsRecordDebugEnabled(record)
    end
    return false
end

function Internal.hasActiveAttack(record, now)
    local runtime = record and record.runtime or nil
    local attackAction = runtime and runtime.attackAction or nil
    now = tonumber(now) or Core.Now()
    return attackAction ~= nil and now < (tonumber(attackAction.finishAt) or 0)
end

local function buildTraversalPointKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(y) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

function Internal.clearTraversalMemory(lane)
    if not lane then
        return
    end
    lane.lastTraversalObstacleKey = nil
    lane.lastTraversalKind = nil
    lane.lastTraversalFromKey = nil
    lane.lastTraversalToKey = nil
    lane.lastTraversalFromX = nil
    lane.lastTraversalFromY = nil
    lane.lastTraversalFromZ = nil
    lane.lastTraversalToX = nil
    lane.lastTraversalToY = nil
    lane.lastTraversalToZ = nil
    lane.lastTraversalAttemptAt = 0
    lane.lastTraversalGoalRevision = 0
end

function Internal.noteTraversalAttempt(lane, kind, obstacleKey, fromX, fromY, fromZ, toX, toY, toZ, now, goalRevision)
    if not lane then
        return
    end
    lane.lastTraversalKind = kind and tostring(kind) or lane.lastTraversalKind
    lane.lastTraversalObstacleKey = obstacleKey and tostring(obstacleKey) or lane.lastTraversalObstacleKey
    lane.lastTraversalFromKey = buildTraversalPointKey(fromX, fromY, fromZ)
    lane.lastTraversalToKey = toX ~= nil and buildTraversalPointKey(toX, toY, toZ) or nil
    lane.lastTraversalFromX = tonumber(fromX)
    lane.lastTraversalFromY = tonumber(fromY)
    lane.lastTraversalFromZ = tonumber(fromZ)
    lane.lastTraversalToX = tonumber(toX)
    lane.lastTraversalToY = tonumber(toY)
    lane.lastTraversalToZ = tonumber(toZ)
    lane.lastTraversalAttemptAt = tonumber(now) or Core.Now()
    if goalRevision ~= nil then
        lane.lastTraversalGoalRevision = tonumber(goalRevision) or lane.lastTraversalGoalRevision
    end
end

function Internal.isRepeatedTraversalAttempt(lane, obstacleKey, fromX, fromY, fromZ, goalRevision, now)
    local fromKey
    if not lane or not obstacleKey or not lane.lastTraversalObstacleKey or not lane.lastTraversalFromKey then
        return false
    end
    fromKey = buildTraversalPointKey(fromX, fromY, fromZ)
    if tostring(lane.lastTraversalObstacleKey) ~= tostring(obstacleKey) then
        return false
    end
    if tostring(lane.lastTraversalFromKey) ~= tostring(fromKey) then
        return false
    end
    if (tonumber(now) or Core.Now()) - (tonumber(lane.lastTraversalAttemptAt) or 0) > Internal.TRAVERSAL_REPEAT_COOLDOWN_MS then
        return false
    end
    if goalRevision ~= nil and (tonumber(goalRevision) or 0) > (tonumber(lane.lastTraversalGoalRevision) or 0) then
        return false
    end
    return true
end

function Internal.refreshTraversalMemory(lane, zombie)
    local dx
    local dy
    if not lane or not zombie or lane.lastTraversalToX == nil or lane.lastTraversalToY == nil then
        return
    end
    dx = zombie:getX() - (tonumber(lane.lastTraversalToX) or zombie:getX())
    dy = zombie:getY() - (tonumber(lane.lastTraversalToY) or zombie:getY())
    if math.sqrt((dx * dx) + (dy * dy)) >= Internal.TRAVERSAL_PROGRESS_CLEAR_DISTANCE then
        Internal.clearTraversalMemory(lane)
    end
end

local function resetNonLocomotionTracking(lane)
    if not lane then
        return
    end
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
end

function Internal.tryRecoverNonLocomotionState(record, zombie, lane, now)
    local actionState
    if not zombie or not lane then
        return false, nil
    end
    now = tonumber(now) or Core.Now()
    actionState = Internal.getActionStateName(zombie)
    if ALLOWED_MOVE_ACTION_STATES[actionState or ""] then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if Internal.hasActiveAttack(record, now)
        or (tonumber(lane.specialMoveUntil) or 0) > now
        or (tonumber(lane.combatFacingUntil) or 0) > now
        or (LiveBodyControl and LiveBodyControl.IsSuppressedActionState and LiveBodyControl.IsSuppressedActionState(actionState))
    then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if tostring(lane.ownerMode or "") ~= "fake_locomotion" then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if lane.lastNonLocomotionState ~= actionState then
        lane.lastNonLocomotionState = actionState
        lane.lastNonLocomotionAt = now
        return false, actionState
    end
    if (now - (tonumber(lane.lastNonLocomotionAt) or 0)) < Internal.NON_LOCOMOTION_RECOVERY_MS then
        return false, actionState
    end
    Internal.hardResetMoveOwner(zombie)
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    resetNonLocomotionTracking(lane)
    return true, actionState
end

function Internal.setWalkAnim(zombie, record, mode, force)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local profile = lane and lane.motionProfile or nil
    local moveAnim = profile and profile.moveAnim or "Walk"
    -- BumpType is an exclusive special-action channel, not a locomotion
    -- transition channel.  Starting a bump for every short movement request
    -- masked the walk cycle and made frequently refreshed follow goals glide.
    -- Explicit combat/traversal bumps remain owned by PNC.Animation.PlayBump.
    if Animation and Animation.Apply then
        Animation.Apply(zombie, record, moveAnim, profile, true)
    end
    if Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, record)
    end
end

function Internal.resetPathController(zombie)
    local behavior
    if not zombie then
        return
    end
    if Internal.getActionStateName and Internal.getActionStateName(zombie) == "walktoward"
        and zombie.changeState and ZombieIdleState and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if zombie.getPathFindBehavior2 then
        behavior = zombie:getPathFindBehavior2()
        if behavior then
            behavior:update()
            behavior:cancel()
            behavior:reset()
        end
    end
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
end

function Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    if not zombie then
        return
    end
    Internal.resetPathController(zombie)
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if preserveVisualMotion ~= true
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if preserveVisualMotion ~= true and zombie.setRunning then
        zombie:setRunning(false)
    end
end

function Internal.getActionStateName(zombie)
    if LiveBodyControl and LiveBodyControl.GetActionStateName then
        return LiveBodyControl.GetActionStateName(zombie)
    end
    if not zombie or not zombie.getActionStateName then
        return ""
    end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

function Internal.hasPath2(zombie)
    if not zombie or not zombie.getPath2 then
        return false
    end
    return zombie:getPath2() ~= nil
end

function Internal.buildGoal(x, y, z, mode, stopDistance)
    return {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        mode = tostring(mode or "walk"),
        stopDistance = tonumber(stopDistance) or 0.7,
    }
end

function Internal.getGoalTolerance(mode, stopDistance)
    local tolerance = tostring(mode or "walk") == "run" and 1.75 or 1.0
    if mode == "sneak" or mode == "crawl" then
        tolerance = 0.6
    end
    if tonumber(stopDistance) and tonumber(stopDistance) > tolerance then
        tolerance = math.min(tonumber(stopDistance) * 1.25, tolerance + 0.75)
    end
    return tolerance
end

function Internal.computeResolvedMode(record, lane, zombie, goal)
    local dist
    local previousMode
    if not lane or not goal then
        return "walk"
    end
    if lane.mode == "crawl" then
        return "crawl"
    end
    if lane.mode == "sneak" or (record and record.runtime and record.runtime.stealthActive == true) then
        return "sneak"
    end
    if lane.mode ~= "walk" and lane.mode ~= "run" then
        return tostring(lane.mode or "walk")
    end
    if not zombie then
        return tostring(lane.mode or "walk")
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    previousMode = tostring(lane.resolvedMode or lane.mode or "walk")
    if previousMode == "run" then
        if dist <= math.max(tonumber(lane.stopDistance) or 0.7, Internal.RUN_STOP_DISTANCE) then
            return "walk"
        end
        return "run"
    end
    if dist >= math.max((tonumber(lane.stopDistance) or 0.7) + 2.75, Internal.RUN_START_DISTANCE) then
        return "run"
    end
    return "walk"
end

function Internal.computeAnimSpeedForMode(mode)
    if LocomotionProfiles and LocomotionProfiles.ComputeAnimSpeed then
        return LocomotionProfiles.ComputeAnimSpeed(mode)
    end
    return 1.0
end

function Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    local resolvedMode = Internal.computeResolvedMode(record, lane, zombie, goal)
    local profile
    if lane then
        lane.resolvedMode = resolvedMode
        profile = LocomotionProfiles and LocomotionProfiles.Resolve and LocomotionProfiles.Resolve(record, lane, zombie, goal, Core.Now()) or nil
        lane.motionProfile = profile
        lane.speed = tonumber(profile and profile.speed) or 0
        lane.animSpeed = tonumber(profile and profile.animSpeed) or Internal.computeAnimSpeedForMode(resolvedMode)
        lane.moveAnim = profile and tostring(profile.moveAnim or "Idle") or "Idle"
        lane.walkType = profile and tostring(profile.walkType or "") or ""
        lane.engineWalkType = profile and tostring(profile.engineWalkType or "") or ""
        lane.profileKey = profile and tostring(profile.profileKey or resolvedMode) or tostring(resolvedMode or "walk")
        lane.staminaMode = profile and tostring(profile.staminaMode or "travel") or "travel"
        lane.isRunning = profile and profile.isRunning == true or false
        lane.isCrawling = profile and profile.isCrawling == true or false
    end
    return resolvedMode
end

function Internal.getStopDistanceClass(stopDistance)
    local value = tonumber(stopDistance) or 0.7
    if value <= 0.35 then
        return "tight"
    end
    if value <= 0.9 then
        return "near"
    end
    return "wide"
end

function Internal.goalsDiffer(currentGoal, nextGoal, currentMode)
    local tolerance
    if not currentGoal or not nextGoal then
        return true
    end
    tolerance = Internal.getGoalTolerance(currentMode or nextGoal.mode, nextGoal.stopDistance)
    return math.abs((currentGoal.x or 0) - (nextGoal.x or 0)) > tolerance
        or math.abs((currentGoal.y or 0) - (nextGoal.y or 0)) > tolerance
        or (currentGoal.z or 0) ~= (nextGoal.z or 0)
        or tostring(currentMode or "") ~= tostring(nextGoal.mode or "")
        or Internal.getStopDistanceClass(currentGoal.stopDistance) ~= Internal.getStopDistanceClass(nextGoal.stopDistance)
end

function Internal.applyHoldAnimation(zombie, record, lane)
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
    local attackAction = record and record.runtime and record.runtime.attackAction or nil
    local profile = lane and lane.motionProfile or nil
    if not zombie or not record then
        return
    end
    if attackAction and Core.Now() < (tonumber(attackAction.finishAt) or 0) then
        return
    end
    if lane and Core.Now() < (tonumber(lane.visualMovingUntil) or 0) then
        if Animation and Animation.Apply then
            Animation.Apply(zombie, record, lane.moveAnim or "Walk", lane.motionProfile, true)
        end
        if Animation and Animation.SyncLocomotion then
            Animation.SyncLocomotion(zombie, record)
        end
        return
    end
    if lane then
        if MotionHints and MotionHints.Clear then
            MotionHints.Clear(lane)
        end
    end
    if healthState == "incapacitated" and Animation and Animation.ApplyDowned then
        Animation.ApplyDowned(zombie, record, false)
        return
    end
    Animation.Apply(zombie, record, "Idle", profile, false)
end

function Internal.isAtGoal(zombie, goal, stopDistance)
    local dist
    if not zombie or not goal then
        return false
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    return dist <= (tonumber(stopDistance) or 0.7) and zombie:getZ() == goal.z
end
