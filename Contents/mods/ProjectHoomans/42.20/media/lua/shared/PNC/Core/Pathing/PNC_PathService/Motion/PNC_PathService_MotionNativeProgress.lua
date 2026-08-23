-- Motion provider: progress accounting and watchdog policy for native engine paths.

local Internal = PNC.PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function handleNativeFailure(
    record,
    zombie,
    lane,
    now,
    nativeState
)
    lane.ownerMode = "engine_path_waiting"
    lane.lastStepAt = now
    lane.lastStepDistance = 0
    lane.lastStepLabel = nativeState
    if Internal.noteNativeGoalFailure
        and Internal.noteNativeGoalFailure(lane, lane.goal, now)
    then
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "native_goal_blocked",
            "failure_limit",
            "goal=" .. Internal.describeGoal(lane.goal)
        )
        return Internal.completeMove(
            zombie,
            record,
            lane,
            "blocked",
            "native_path_unreachable"
        )
    end
    if now >= (tonumber(lane.visualMovingUntil) or 0) then
        Internal.applyHoldAnimation(zombie, record, lane)
    end
    return true, nativeState
end

local function recordPhysicalStep(
    lane,
    now,
    fromX,
    fromY,
    fromZ,
    toX,
    toY,
    toZ,
    stepDistance
)
    if stepDistance <= 0.0001 then
        return
    end
    lane.lastPhysicalMoveAt = now
    lane.lastX = toX
    lane.lastY = toY
    lane.visualMovingUntil = now + Internal.LOCOMOTION_VISUAL_LEASE_MS
    if Internal.MotionHints and Internal.MotionHints.Remember then
        Internal.MotionHints.Remember(
            lane,
            fromX,
            fromY,
            fromZ,
            toX,
            toY,
            toZ,
            now,
            {
                kind = "engine_path",
                profile = lane.motionProfile,
            }
        )
    end
end

local function recordGoalProgress(lane, now, goalDistance, goalProgress)
    if goalProgress >= 0.01 then
        lane.bestGoalDistance = goalDistance
        lane.lastProgressAt = now
        lane.lastGoalProgressAt = now
        lane.nonProgressStepCount = 0
        lane.noProgressCount = 0
        lane.blockReason = nil
    else
        lane.nonProgressStepCount =
            (tonumber(lane.nonProgressStepCount) or 0) + 1
    end
end

local function handleNativeTimeout(
    record,
    zombie,
    lane,
    enginePlanner,
    now,
    nativeTraversalState
)
    if nativeTraversalState ~= nil
        or now - (tonumber(lane.lastGoalProgressAt) or now)
            < Internal.PROGRESS_TIMEOUT_MS
    then
        return nil
    end
    lane.noProgressCount = (tonumber(lane.noProgressCount) or 0) + 1
    lane.blockReason = "native_no_goal_progress"
    Internal.logMoveWarning(
        record,
        zombie,
        lane,
        "native_progress_timeout",
        lane.blockReason,
        "goal=" .. Internal.describeGoal(lane.goal)
    )
    if lane.noProgressCount >= 2 then
        return Internal.completeMove(
            zombie,
            record,
            lane,
            "blocked",
            "native_progress_timeout"
        )
    end
    if enginePlanner.Invalidate then
        enginePlanner.Invalidate(
            record,
            "native_progress_timeout",
            zombie
        )
    end
    lane.lastGoalProgressAt = now
    lane.lastNavigationInvalidatedAt = now
    if Diagnostics then
        Diagnostics.Increment("Pathing.Replans")
        Diagnostics.Increment("Pathing.Retries")
    end
    return true, "native_repath"
end

function Internal.recordNativeMove(
    record,
    zombie,
    lane,
    navigation,
    enginePlanner,
    now,
    nativeState,
    fromX,
    fromY,
    fromZ
)
    local toX = zombie:getX()
    local toY = zombie:getY()
    local toZ = zombie:getZ()
    local dx = toX - fromX
    local dy = toY - fromY
    local stepDistance = math.sqrt((dx * dx) + (dy * dy))
    local goalDistance = Internal.Core.Distance(
        toX,
        toY,
        lane.goal.x,
        lane.goal.y
    )
    local bestGoalDistance = tonumber(lane.bestGoalDistance)
        or goalDistance
    local goalProgress = bestGoalDistance - goalDistance
    if lane.bestGoalDistance == nil then
        lane.bestGoalDistance = goalDistance
    end
    if lane.lastGoalProgressAt == nil then
        lane.lastGoalProgressAt = tonumber(lane.lastProgressAt) or now
    end
    if nativeState == "engine_path_failed"
        or nativeState == "engine_path_timeout"
    then
        return handleNativeFailure(
            record, zombie, lane, now, nativeState
        )
    end

    local nativeTraversalState = navigation
        and navigation.nativeTraversalState or nil
    lane.ownerMode = nativeTraversalState
        and "engine_traversal" or "engine_path"
    lane.lastIssueAt = now
    lane.lastStepAt = now
    lane.lastStepDistance = stepDistance
    lane.lastStepLabel = nativeState
    lane.goalDistance = goalDistance
    lane.lastProgressDelta = goalProgress
    recordPhysicalStep(
        lane,
        now,
        fromX,
        fromY,
        fromZ,
        toX,
        toY,
        toZ,
        stepDistance
    )
    recordGoalProgress(lane, now, goalDistance, goalProgress)
    if Internal.syncRecordPosition then
        Internal.syncRecordPosition(record, zombie)
    end
    if Internal.isAtGoal(zombie, lane.goal, lane.stopDistance) then
        return Internal.completeMove(
            zombie, record, lane, "arrived", nativeState
        )
    end
    local handled, state = Internal.tryNativeStallPassage(
        record,
        zombie,
        lane,
        enginePlanner,
        now,
        nativeTraversalState
    )
    if handled then
        return handled, state
    end
    handled, state = handleNativeTimeout(
        record,
        zombie,
        lane,
        enginePlanner,
        now,
        nativeTraversalState
    )
    if handled then
        return handled, state
    end
    return true, nativeState
end
