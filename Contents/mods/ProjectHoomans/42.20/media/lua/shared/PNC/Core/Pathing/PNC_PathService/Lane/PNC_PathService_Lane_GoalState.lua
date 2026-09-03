-- Lane phase, goal initialization, and continuous retarget state.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

function Internal.setLanePhase(record, lane, phase, reason)
    if not lane or lane.phase == phase then
        return
    end
    lane.phase = phase
    Internal.logMoveTransition(record, nil, lane, phase, reason)
end

function Internal.setLaneGoal(record, lane, goal)
    lane.id = (tonumber(lane.id) or 0) + 1
    lane.goalRevision = (tonumber(lane.goalRevision) or 0) + 1
    lane.goal = {
        x = goal.x,
        y = goal.y,
        z = goal.z,
        mode = goal.mode,
        stopDistance = goal.stopDistance,
    }
    lane.pendingGoalAt = 0
    lane.mode = goal.mode
    lane.stopDistance = goal.stopDistance
    lane.blockReason = nil
    lane.cancelReason = nil
    lane.recoveryCount = 0
    lane.fallbackCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.lastProgressDelta = 0
    lane.goalDistance = nil
    lane.bestGoalDistance = nil
    lane.lastGoalProgressAt = 0
    lane.nonProgressStepCount = 0
    lane.lastNavigationInvalidatedAt = 0
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.visualMovingUntil = 0
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.traversalAction = nil
    lane.vanillaFenceAction = nil
    lane.resolvedMode = nil
    lane.animSpeed = 1.0
    lane.speed = 0
    lane.moveAnim = "Idle"
    lane.walkType = ""
    lane.engineWalkType = ""
    lane.profileKey = "idle"
    lane.staminaMode = "travel"
    lane.isRunning = false
    lane.isCrawling = false
    lane.motionProfile = nil
    lane.motionHint = nil
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
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
    Internal.clearBlockedStep(lane)
    lane.ownerMode = "requested"
end

function Internal.retargetLaneGoal(record, lane, goal)
    local now
    local lastPhysicalMoveAt
    local progressTimeoutMs
    if not lane or not goal then
        return false
    end
    now = Internal.Core.Now()
    lastPhysicalMoveAt = tonumber(lane.lastPhysicalMoveAt) or 0
    progressTimeoutMs = tonumber(Internal.PROGRESS_TIMEOUT_MS) or 2200
    lane.goalRevision = (tonumber(lane.goalRevision) or 0) + 1
    lane.goal = {
        x = goal.x,
        y = goal.y,
        z = goal.z,
        mode = goal.mode,
        stopDistance = goal.stopDistance,
    }
    lane.mode = goal.mode
    lane.stopDistance = goal.stopDistance
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.blockReason = nil
    lane.cancelReason = nil
    Internal.clearBlockedStep(lane)
    lane.goalDistance = nil
    lane.bestGoalDistance = nil
    lane.lastProgressDelta = 0
    lane.lastProgressAt = now
    -- Continuous follow steering may retarget faster than the native
    -- controller can report a result. Do not let each retarget hide a real
    -- physical stall; only refresh the goal watchdog when the body has moved
    -- recently. The route timeout remains responsible for a moving body whose
    -- distance to a moving owner is not monotonically decreasing.
    if lastPhysicalMoveAt > 0
        and now - lastPhysicalMoveAt < progressTimeoutMs
    then
        lane.lastGoalProgressAt = now
    elseif lane.lastGoalProgressAt == nil then
        lane.lastGoalProgressAt = now
    end
    lane.nonProgressStepCount = 0
    lane.noProgressCount = 0
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.retargetCount = (tonumber(lane.retargetCount) or 0) + 1
    lane.lastRetargetAt = now
    return true
end
