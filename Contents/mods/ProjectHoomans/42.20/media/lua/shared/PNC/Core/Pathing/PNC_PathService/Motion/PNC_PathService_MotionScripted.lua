-- Motion provider: scripted/fake-locomotion progression for an active lane.

local Internal = PNC.PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function prepareBody(zombie, lane, now)
    if lane.navigationProvider ~= "engine_path"
        and Internal.FakeLocomotion
        and Internal.FakeLocomotion.PrepareBody
    then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
end

local function noteBlockedStep(record, zombie, lane, goal, now, result, distance)
    local blocked = result == "blocked"
        or result == "interaction_blocked"
        or result == "stalled"
    if not blocked then
        return
    end
    lane.blockReason = result == "stalled"
        and "no_goal_progress" or "fake_step_blocked"
    if result == "stalled"
        and now - (tonumber(lane.lastNavigationInvalidatedAt) or 0) >= 500
        and PNC.NavigationRouter
        and PNC.NavigationRouter.Invalidate
    then
        PNC.NavigationRouter.Invalidate(record, "fake_locomotion_stalled")
        lane.lastNavigationInvalidatedAt = now
    end
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        "step_blocked",
        result,
        "dist=" .. string.format("%.3f", tonumber(distance) or 0)
    )
end

function Internal.stepScriptedMove(zombie, record, lane, goal, now)
    prepareBody(zombie, lane, now)
    local stepped
    local stepResult
    local stepDistance
    if Internal.FakeLocomotion and Internal.FakeLocomotion.StepTowardGoal then
        stepped, stepResult, stepDistance =
            Internal.FakeLocomotion.StepTowardGoal(
                zombie, record, lane, goal, now
            )
    else
        stepped = false
        stepResult = "missing_locomotion"
        stepDistance = 0
    end
    if stepped then
        Internal.setWalkAnim(
            zombie,
            record,
            lane.resolvedMode or lane.mode or goal.mode,
            false
        )
        lane.ownerMode = "fake_locomotion"
        lane.recoveryCount = 0
        lane.lastRecoveryReason = nil
        lane.lastRecoverAt = 0
        lane.noProgressCount = 0
        lane.lastIssueAt = now
        lane.lastActionState = Internal.getActionStateName(zombie)
        lane.specialAnim = nil
        lane.visualMovingUntil = now + Internal.LOCOMOTION_VISUAL_LEASE_MS
        Internal.syncRecordPosition(record, zombie)
        if Internal.isAtGoal(zombie, goal, lane.stopDistance) then
            return Internal.completeMove(
                zombie, record, lane, "arrived", "arrived"
            )
        end
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "progress",
            "fake_step",
            "step=" .. tostring(stepResult or "direct")
                .. " dist="
                .. string.format("%.3f", tonumber(stepDistance) or 0)
        )
        return true, "moving"
    end

    if now >= (tonumber(lane.visualMovingUntil) or 0) then
        Internal.applyHoldAnimation(zombie, record, lane)
    end
    noteBlockedStep(
        record, zombie, lane, goal, now, stepResult, stepDistance
    )
    local passageHandled, passageState =
        Internal.tryStalledScriptedPassage(
            zombie, record, lane, goal, now, stepResult
        )
    if passageHandled then
        return passageHandled, passageState
    end
    if (now - (tonumber(lane.lastProgressAt) or 0))
        >= Internal.PROGRESS_TIMEOUT_MS
    then
        lane.noProgressCount = (tonumber(lane.noProgressCount) or 0) + 1
        lane.blockReason = "fake_locomotion_blocked"
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "progress_timeout",
            lane.blockReason or "progress_timeout",
            ""
        )
        if lane.noProgressCount >= 2 then
            Internal.logMoveWarning(
                record,
                zombie,
                lane,
                "blocked",
                "progress_timeout",
                "goal=" .. Internal.describeGoal(goal)
            )
            return Internal.completeMove(
                zombie, record, lane, "blocked", "progress_timeout"
            )
        end
        lane.lastProgressAt = now
        if Diagnostics then Diagnostics.Increment("Pathing.Retries") end
        return true, "retry"
    end
    return true, "waiting"
end

function Internal.updateActiveMove(zombie, record, lane)
    local goal = lane and lane.goal or nil
    if not zombie or not lane or not goal then
        return false, "no_goal"
    end
    if Diagnostics then
        Diagnostics.RecordLogicalAdvance(record, "path_service_active_move")
    end
    local now = Internal.Core.Now()
    local handled, state = Internal.updateScriptedSpecialMove(
        zombie, record, lane, now
    )
    if handled then
        return handled, state
    end

    Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    lane.lastActionState = Internal.getActionStateName(zombie)
    handled, state = Internal.tryImmediateScriptedPassage(
        zombie, record, lane, goal, now
    )
    if handled then
        return handled, state
    end
    handled, state = Internal.tryAdoptScriptedPassage(
        zombie, record, lane, goal, now
    )
    if handled then
        return handled, state
    end
    handled, state = Internal.recoverScriptedBodyState(
        zombie, record, lane, now
    )
    if handled then
        return handled, state
    end
    if lane.pendingGoal
        and now - (tonumber(lane.pendingGoalAt) or now)
            >= Internal.GOAL_REFRESH_DELAY_MS
    then
        return Internal.refreshPendingGoal(
            zombie, record, lane, "goal_refresh"
        )
    end
    if Internal.isAtGoal(zombie, goal, lane.stopDistance) then
        return Internal.completeMove(
            zombie, record, lane, "arrived", "arrived"
        )
    end
    return Internal.stepScriptedMove(zombie, record, lane, goal, now)
end
