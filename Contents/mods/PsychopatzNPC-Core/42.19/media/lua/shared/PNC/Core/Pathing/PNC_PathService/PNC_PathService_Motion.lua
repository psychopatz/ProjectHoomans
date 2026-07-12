--[[
    PNC Path Service Motion
    Move lifecycle, active pumping, and public path-service API.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal

function Internal.finalizeCancel(zombie, record, lane)
    local now = Internal.Core.Now()
    local preserveVisualMotion = now < (tonumber(lane and lane.visualMovingUntil) or 0)
    if zombie and not Internal.hasActiveAttack(record) then
        Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    end
    lane.pendingGoal = nil
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.startedAt = 0
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
    if (not preserveVisualMotion) and Internal.MotionHints and Internal.MotionHints.Clear then
        Internal.MotionHints.Clear(lane)
    end
    if Internal.clearTraversalMemory then
        Internal.clearTraversalMemory(lane)
    end
    if not preserveVisualMotion then
        lane.resolvedMode = nil
        lane.animSpeed = 1.0
    end
    lane.ownerMode = "idle"
    Internal.setLanePhase(record, lane, "idle", lane.cancelReason or "cancelled")
    Internal.applyHoldAnimation(zombie, record, lane)
    return true, "cancelled"
end

function Internal.startRequestedMove(zombie, record, lane)
    local now
    local preserveVisualMotion
    local goal = lane and lane.goal or nil
    if not zombie or not lane or not goal then
        return false, "no_goal"
    end
    now = Internal.Core.Now()
    preserveVisualMotion = now < (tonumber(lane.visualMovingUntil) or 0)
    Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    lane.resolvedMode = Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    if Internal.FakeLocomotion and Internal.FakeLocomotion.PrepareBody then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    Internal.setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or goal.mode, true)
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
    lane.lastStepLabel = nil
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
    if (not preserveVisualMotion) and Internal.MotionHints and Internal.MotionHints.Clear then
        Internal.MotionHints.Clear(lane)
    end
    lane.ownerMode = "fake_locomotion"
    Internal.setLanePhase(record, lane, "active", "started")
    Internal.logMoveTransition(record, zombie, lane, "request_issued", "started")
    return true, "started"
end

function Internal.completeMove(zombie, record, lane, phase, reason)
    local now = Internal.Core.Now()
    local preserveVisualMotion = phase == "arrived" and now < (tonumber(lane and lane.visualMovingUntil) or 0)
    if zombie then
        Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    end
    lane.pendingGoal = nil
    lane.startedAt = 0
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.cancelReason = phase == "arrived" and reason or lane.cancelReason
    lane.blockReason = phase == "blocked" and reason or nil
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
    if (not preserveVisualMotion) and Internal.MotionHints and Internal.MotionHints.Clear then
        Internal.MotionHints.Clear(lane)
    end
    if Internal.clearTraversalMemory then
        Internal.clearTraversalMemory(lane)
    end
    if not preserveVisualMotion then
        lane.resolvedMode = nil
        lane.animSpeed = 1.0
    end
    lane.ownerMode = phase == "blocked" and "blocked" or "idle"
    Internal.setLanePhase(record, lane, phase, reason)
    Internal.logMoveTransition(record, zombie, lane, "complete", reason)
    if preserveVisualMotion then
        Internal.setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or "walk", false)
    else
        Internal.applyHoldAnimation(zombie, record, lane)
    end
    return true, reason
end

function Internal.refreshPendingGoal(zombie, record, lane, reason)
    if not lane or not lane.pendingGoal then
        return false
    end
    Internal.setLaneGoal(record, lane, lane.pendingGoal)
    lane.pendingGoal = nil
    Internal.setLanePhase(record, lane, "requested", reason or "refresh")
    return Internal.startRequestedMove(zombie, record, lane)
end

function Internal.restartCurrentGoal(zombie, record, lane, reason)
    if not lane or not lane.goal then
        return false, "no_goal"
    end
    lane.ownerMode = "requested"
    Internal.setLanePhase(record, lane, "requested", reason or "restart")
    return Internal.startRequestedMove(zombie, record, lane)
end

function Internal.updateActiveMove(zombie, record, lane)
    local goal = lane and lane.goal or nil
    local now
    local stepped
    local stepResult
    local interacted
    local interactType
    local suppressed
    local suppressedState
    local stepDistance

    if not zombie or not lane or not goal then
        return false, "no_goal"
    end

    now = Internal.Core.Now()
    if Internal.refreshTraversalMemory then
        Internal.refreshTraversalMemory(lane, zombie)
    end
    if (lane.ownerMode == "window_climb" or lane.ownerMode == "window_open" or lane.ownerMode == "door_open" or lane.ownerMode == "fence_climb")
        and now < (tonumber(lane.specialMoveUntil) or 0)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        Internal.logMoveDebug(record, zombie, lane, "special_cooldown", lane.ownerMode, "")
        return true, lane.ownerMode
    end

    Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    lane.lastActionState = Internal.getActionStateName(zombie)
    if Internal.LiveBodyControl and Internal.LiveBodyControl.SuppressZombieState then
        suppressed, suppressedState = Internal.LiveBodyControl.SuppressZombieState(zombie, lane, now)
    else
        suppressed = false
        suppressedState = nil
    end
    if suppressed then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.lastActionState = Internal.getActionStateName(zombie)
        lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
        lane.lastRecoveryReason = suppressedState or lane.lastActionState
        lane.lastRecoverAt = now
        if Internal.FakeLocomotion and Internal.FakeLocomotion.PrepareBody then
            Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
        end
        if lane.ownerMode ~= "window_climb" and lane.ownerMode ~= "window_open" and lane.ownerMode ~= "fence_climb" then
            Internal.setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or "walk", false)
        end
        Internal.logMoveWarning(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "action=" .. tostring(suppressedState or lane.lastActionState))
        Internal.logMoveDebug(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "postAction=" .. tostring(lane.lastActionState))
    end

    if not suppressed and Internal.tryRecoverNonLocomotionState then
        local recovered
        local recoveredState
        recovered, recoveredState = Internal.tryRecoverNonLocomotionState(record, zombie, lane, now)
        if recovered then
            lane.lastProgressAt = now
            lane.lastIssueAt = now
            lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
            lane.lastRecoveryReason = recoveredState or lane.lastActionState
            lane.lastRecoverAt = now
            if Internal.FakeLocomotion and Internal.FakeLocomotion.PrepareBody then
                Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
            end
            Internal.logMoveWarning(record, zombie, lane, "recover_nonlocomotion", recoveredState or "unknown", "action=" .. tostring(recoveredState or "unknown"))
            Internal.logMoveDebug(record, zombie, lane, "recover_nonlocomotion", recoveredState or "unknown", "")
            return true, "recovering"
        end
    end

    if lane.pendingGoal and (now - (tonumber(lane.lastIssueAt) or 0)) >= Internal.GOAL_REFRESH_DELAY_MS then
        return Internal.refreshPendingGoal(zombie, record, lane, "goal_refresh")
    end

    if Internal.isAtGoal(zombie, goal, lane.stopDistance) then
        return Internal.completeMove(zombie, record, lane, "arrived", "arrived")
    end

    if Internal.FakeLocomotion and Internal.FakeLocomotion.PrepareBody then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    Internal.setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or goal.mode, false)
    if Internal.FakeLocomotion and Internal.FakeLocomotion.StepTowardGoal then
        stepped, stepResult, stepDistance = Internal.FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
    else
        stepped = false
        stepResult = "missing_locomotion"
        stepDistance = 0
    end

    if stepped then
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
            return Internal.completeMove(zombie, record, lane, "arrived", "arrived")
        end
        Internal.logMoveDebug(record, zombie, lane, "progress", "fake_step", "step=" .. tostring(stepResult or "direct") .. " dist=" .. string.format("%.3f", tonumber(stepDistance) or 0))
        return true, "moving"
    end

    if stepResult == "blocked" or stepResult == "interaction_blocked" then
        lane.blockReason = "fake_step_blocked"
        Internal.logMoveDebug(record, zombie, lane, "step_blocked", stepResult, "dist=" .. string.format("%.3f", tonumber(stepDistance) or 0))
    end

    if stepResult ~= "throttle"
        and ((stepResult == "blocked" or stepResult == "interaction_blocked") or (now - (tonumber(lane.lastProgressAt) or 0)) >= Internal.INTERACTION_STALL_MS)
    then
        interacted, interactType = Internal.tryDoorOrWindowInteraction(zombie, record, lane, goal.x, goal.y, goal.z)
        if interacted then
            lane.lastIssueAt = now
            lane.lastProgressAt = now
            lane.noProgressCount = 0
            lane.lastStepAt = now
            lane.lastX = zombie:getX()
            lane.lastY = zombie:getY()
            if interactType == "door_open" then
                lane.ownerMode = "door_open"
                lane.specialMoveUntil = now + 180
                lane.specialAnim = nil
            elseif interactType == "window_open" then
                lane.ownerMode = "window_open"
                lane.specialMoveUntil = now + 250
                lane.specialAnim = nil
            elseif interactType == "fence_climb" then
                lane.ownerMode = "fence_climb"
            else
                lane.ownerMode = "window_climb"
            end
            Internal.logMoveDebug(record, zombie, lane, "interact", interactType or "door_or_window", "")
            return true, interactType or "interact"
        end
        if stepResult == "blocked" or stepResult == "interaction_blocked" then
            Internal.logMoveDebug(record, zombie, lane, "interact_rejected", stepResult, "goal=" .. Internal.describeGoal(goal))
        end
    end

    if (now - (tonumber(lane.lastProgressAt) or 0)) >= Internal.PROGRESS_TIMEOUT_MS then
        lane.noProgressCount = (tonumber(lane.noProgressCount) or 0) + 1
        lane.blockReason = "fake_locomotion_blocked"
        Internal.logMoveWarning(record, zombie, lane, "progress_timeout", lane.blockReason or "progress_timeout", "")
        if lane.noProgressCount >= 2 then
            Internal.logMoveWarning(record, zombie, lane, "blocked", "progress_timeout", "goal=" .. Internal.describeGoal(goal))
            return Internal.completeMove(zombie, record, lane, "blocked", "progress_timeout")
        end
        lane.lastProgressAt = now
        return true, "retry"
    end

    return true, "waiting"
end

function PathService.Reset(zombie, record)
    if record and record.runtime then
        record.runtime.pathing = nil
        record.runtime.moveIntent = nil
    end
    Internal.hardResetMoveOwner(zombie)
end

function PathService.MoveToward(record, zombie, targetX, targetY, targetZ, mode, stopDistance, reason)
    record.runtime = record.runtime or {}
    record.runtime.moveIntent = {
        kind = "move",
        x = tonumber(targetX) or record.x,
        y = tonumber(targetY) or record.y,
        z = tonumber(targetZ) or record.z or 0,
        mode = tostring(mode or "walk"),
        stopDistance = tonumber(stopDistance) or 0.7,
        reason = reason or "path_service_move",
        requestedByJob = tostring(record.activeJob or "none"),
        requestedByBehavior = tostring(record.activeBehavior or record.activeJob or "none"),
        requestedOrder = tostring(record.orderSpec and record.orderSpec.kind or "none"),
        combatReason = tostring(record.runtime.combatBlockReason or "none"),
        updatedAt = Internal.Core.Now(),
    }
    if zombie and Internal.isAtGoal(zombie, Internal.buildGoal(targetX, targetY, targetZ, mode, stopDistance), stopDistance) then
        return true, "arrived"
    end
    return true, "move_intent"
end

function PathService.Pump(record, zombie)
    local runtime = record and record.runtime or nil
    local lane
    local intentState
    local now
    if not zombie or not runtime then
        return false, "no_live_body"
    end

    lane = Internal.ensureMoveLane(record)
    now = Internal.Core.Now()
    Internal.applyCombatFacing(zombie, lane, now, false)
    intentState = Internal.consumeMoveIntent(record, lane, zombie)

    if lane.phase == "cancel_pending" then
        Internal.finalizeCancel(zombie, record, lane)
        intentState = Internal.consumeMoveIntent(record, lane, zombie)
    end

    if lane.phase == "requested" then
        return Internal.startRequestedMove(zombie, record, lane)
    end

    if lane.phase == "active" then
        return Internal.updateActiveMove(zombie, record, lane)
    end

    if intentState == "arrived" then
        Internal.applyHoldAnimation(zombie, record, lane)
        return true, "arrived"
    end

    Internal.applyHoldAnimation(zombie, record, lane)
    return false, "idle"
end

function PathService.AdvanceAbstract(record, targetX, targetY, targetZ, stopDistance)
    local dist
    local dx
    local dy
    local len
    local step = PNC.Const.ABSTRACT_TRAVEL_STEP
    stopDistance = tonumber(stopDistance) or 1.0
    dist = Internal.Core.Distance(record.x, record.y, targetX, targetY)
    if dist <= stopDistance and record.z == targetZ then
        return true
    end
    dx = targetX - record.x
    dy = targetY - record.y
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0 then
        return true
    end
    record.x = record.x + (dx / len) * math.min(step, len)
    record.y = record.y + (dy / len) * math.min(step, len)
    record.z = targetZ
    return false
end
