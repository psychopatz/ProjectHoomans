-- Motion provider: move lifecycle transitions for PNC.PathService.

local PathService = PNC.PathService
local Internal = PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function resetProgressState(lane, now)
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.startedAt = 0
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
    lane.nextPassageProbeAt = nil
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastPhysicalMoveAt = 0
    lane.lastStepLabel = nil
    lane.lastProgressDelta = 0
    lane.goalDistance = nil
    lane.bestGoalDistance = nil
    lane.lastGoalProgressAt = now
    lane.nonProgressStepCount = 0
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
end

local function finishOwnerReset(zombie, record, lane, preserveVisualMotion)
    if (not preserveVisualMotion)
        and Internal.MotionHints
        and Internal.MotionHints.Clear
    then
        Internal.MotionHints.Clear(lane)
    end
    if Internal.clearTraversalMemory then
        Internal.clearTraversalMemory(lane)
    end
    if not preserveVisualMotion then
        lane.resolvedMode = nil
        lane.animSpeed = 1.0
    end
end

function Internal.finalizeCancel(zombie, record, lane)
    local now = Internal.Core.Now()
    local preserveVisualMotion = now
        < (tonumber(lane and lane.visualMovingUntil) or 0)
    if zombie and not Internal.hasActiveAttack(record, now, zombie) then
        Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    end
    resetProgressState(lane, now)
    finishOwnerReset(zombie, record, lane, preserveVisualMotion)
    lane.ownerMode = "idle"
    Internal.setLanePhase(record, lane, "idle", lane.cancelReason or "cancelled")
    Internal.applyHoldAnimation(zombie, record, lane)
    return true, "cancelled"
end

function Internal.startRequestedMove(zombie, record, lane)
    local goal = lane and lane.goal or nil
    if not zombie or not lane or not goal then
        return false, "no_goal"
    end
    if Diagnostics then
        Diagnostics.Increment("Pathing.PathRequests")
    end
    local now = Internal.Core.Now()
    local preserveVisualMotion = now
        < (tonumber(lane.visualMovingUntil) or 0)
    Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    lane.resolvedMode = Internal.refreshResolvedLocomotion(
        record,
        lane,
        zombie,
        goal
    )
    if lane.navigationProvider ~= "engine_path"
        and Internal.FakeLocomotion
        and Internal.FakeLocomotion.PrepareBody
    then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    if lane.navigationProvider == "engine_path" then
        Internal.setWalkAnim(
            zombie,
            record,
            lane.resolvedMode or lane.mode or goal.mode,
            true
        )
    end
    lane.startedAt = now
    lane.lastIssueAt = now
    lane.lastProgressAt = now
    lane.lastX = zombie:getX()
    lane.lastY = zombie:getY()
    lane.lastActionState = Internal.getActionStateName(zombie)
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastPhysicalMoveAt = 0
    lane.lastStepLabel = nil
    lane.lastProgressDelta = 0
    lane.goalDistance = Internal.Core.Distance(
        zombie:getX(), zombie:getY(), goal.x, goal.y
    )
    lane.bestGoalDistance = lane.goalDistance
    lane.lastGoalProgressAt = now
    lane.nextPassageProbeAt = nil
    lane.nonProgressStepCount = 0
    lane.steeringSide = nil
    lane.directStepCount = 0
    if not preserveVisualMotion then
        lane.visualMovingUntil = 0
    end
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
    if (not preserveVisualMotion)
        and Internal.MotionHints
        and Internal.MotionHints.Clear
    then
        Internal.MotionHints.Clear(lane)
    end
    lane.ownerMode = lane.navigationProvider == "engine_path"
        and "engine_path" or "fake_locomotion"
    Internal.setLanePhase(record, lane, "active", "started")
    Internal.logMoveTransition(record, zombie, lane, "request_issued", "started")
    return true, "started"
end

function Internal.completeMove(zombie, record, lane, phase, reason)
    local now = Internal.Core.Now()
    local preserveVisualMotion = phase == "arrived"
        and now < (tonumber(lane and lane.visualMovingUntil) or 0)
    if Diagnostics then
        if phase == "arrived" then
            Diagnostics.Increment("Pathing.CompletedRoutes")
        elseif phase == "blocked" then
            Diagnostics.Increment("Pathing.BlockedRoutes")
            Diagnostics.Increment("Pathing.FailedRoutes")
        end
    end
    if zombie then
        Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    end
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.startedAt = 0
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.cancelReason = phase == "arrived" and reason or lane.cancelReason
    lane.blockReason = phase == "blocked" and reason or nil
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
    lane.nextPassageProbeAt = nil
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastPhysicalMoveAt = 0
    lane.lastStepLabel = nil
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
    finishOwnerReset(zombie, record, lane, preserveVisualMotion)
    lane.ownerMode = phase == "blocked" and "blocked" or "idle"
    Internal.setLanePhase(record, lane, phase, reason)
    if phase == "blocked" and Internal.logMoveWarning then
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "route_failed",
            reason or "blocked",
            "goal=" .. Internal.describeGoal(lane.goal)
        )
    end
    Internal.logMoveTransition(record, zombie, lane, "complete", reason)
    if preserveVisualMotion then
        Internal.setWalkAnim(
            zombie,
            record,
            lane.resolvedMode or lane.mode or "walk",
            false
        )
    else
        Internal.applyHoldAnimation(zombie, record, lane)
    end
    return true, reason
end

function Internal.refreshPendingGoal(zombie, record, lane, reason)
    if not lane or not lane.pendingGoal then
        return false
    end
    if Diagnostics then Diagnostics.Increment("Pathing.Replans") end
    Internal.setLaneGoal(record, lane, lane.pendingGoal)
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    Internal.setLanePhase(record, lane, "requested", reason or "refresh")
    return Internal.startRequestedMove(zombie, record, lane)
end

function Internal.restartCurrentGoal(zombie, record, lane, reason)
    if not lane or not lane.goal then
        return false, "no_goal"
    end
    if Diagnostics then
        Diagnostics.Increment("Pathing.Replans")
        Diagnostics.Increment("Pathing.Retries")
    end
    lane.ownerMode = "requested"
    Internal.setLanePhase(record, lane, "requested", reason or "restart")
    return Internal.startRequestedMove(zombie, record, lane)
end
