-- Request and progress defaults for the movement lane.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

function Internal.ensureLaneRequestState(lane)
    lane.id = lane.id or 0
    lane.phase = lane.phase or "idle"
    lane.mode = lane.mode or "walk"
    lane.stopDistance = tonumber(lane.stopDistance) or 0.7
    lane.goal = lane.goal or nil
    lane.pendingGoal = lane.pendingGoal or nil
    lane.pendingGoalAt = tonumber(lane.pendingGoalAt) or 0
    lane.startedAt = tonumber(lane.startedAt) or 0
    lane.lastIssueAt = tonumber(lane.lastIssueAt) or 0
    lane.lastProgressAt = tonumber(lane.lastProgressAt) or 0
    lane.cancelReason = lane.cancelReason or nil
    lane.blockReason = lane.blockReason or nil
    lane.intentReason = lane.intentReason or nil
    lane.requestedByJob = lane.requestedByJob or nil
    lane.requestedByBehavior = lane.requestedByBehavior or nil
    lane.requestedOrder = lane.requestedOrder or nil
    lane.navigationPolicy = lane.navigationPolicy or nil
    lane.navigationProvider = lane.navigationProvider or nil
    lane.finalGoalX = lane.finalGoalX ~= nil
        and tonumber(lane.finalGoalX) or nil
    lane.finalGoalY = lane.finalGoalY ~= nil
        and tonumber(lane.finalGoalY) or nil
    lane.finalGoalZ = lane.finalGoalZ ~= nil
        and tonumber(lane.finalGoalZ) or nil
    lane.lastWarnKey = lane.lastWarnKey or nil
    lane.lastWarnAt = tonumber(lane.lastWarnAt) or 0
end

function Internal.ensureLaneProgressState(lane)
    lane.goalRevision = tonumber(lane.goalRevision) or 0
    lane.recoveryCount = tonumber(lane.recoveryCount) or 0
    lane.fallbackCount = tonumber(lane.fallbackCount) or 0
    lane.lastRecoveryReason = lane.lastRecoveryReason or nil
    lane.lastActionState = lane.lastActionState or nil
    lane.lastDirectStepAt = tonumber(lane.lastDirectStepAt) or 0
    lane.lastStepAt = tonumber(lane.lastStepAt) or 0
    lane.lastStepDistance = tonumber(lane.lastStepDistance) or 0
    lane.lastStepLabel = lane.lastStepLabel or nil
    lane.lastProgressDelta = tonumber(lane.lastProgressDelta) or 0
    lane.goalDistance = lane.goalDistance ~= nil
        and tonumber(lane.goalDistance) or nil
    lane.bestGoalDistance = lane.bestGoalDistance ~= nil
        and tonumber(lane.bestGoalDistance) or nil
    lane.lastGoalProgressAt = tonumber(lane.lastGoalProgressAt) or 0
    lane.nonProgressStepCount = tonumber(lane.nonProgressStepCount) or 0
    lane.lastNavigationInvalidatedAt =
        tonumber(lane.lastNavigationInvalidatedAt) or 0
    lane.steeringSide = lane.steeringSide ~= nil and tonumber(lane.steeringSide) or nil
    lane.directStepCount = tonumber(lane.directStepCount) or 0
    lane.visualMovingUntil = tonumber(lane.visualMovingUntil) or 0
    lane.lastRecoverAt = tonumber(lane.lastRecoverAt) or 0
    lane.noProgressCount = tonumber(lane.noProgressCount) or 0
end
