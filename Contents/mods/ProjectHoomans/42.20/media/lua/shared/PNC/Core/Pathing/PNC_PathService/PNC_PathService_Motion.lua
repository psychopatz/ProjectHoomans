--[[
    PNC Path Service Motion
    Move lifecycle, active pumping, and public path-service API.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Internal.finalizeCancel(zombie, record, lane)
    local now = Internal.Core.Now()
    local preserveVisualMotion = now < (tonumber(lane and lane.visualMovingUntil) or 0)
    if zombie and not Internal.hasActiveAttack(record, now, zombie) then
        Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    end
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.startedAt = 0
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
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
    if Diagnostics then
        Diagnostics.Increment("Pathing.PathRequests")
    end
    now = Internal.Core.Now()
    preserveVisualMotion = now < (tonumber(lane.visualMovingUntil) or 0)
    Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    lane.resolvedMode = Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
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
        zombie:getX(),
        zombie:getY(),
        goal.x,
        goal.y
    )
    lane.bestGoalDistance = lane.goalDistance
    lane.lastGoalProgressAt = now
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
    if (not preserveVisualMotion) and Internal.MotionHints and Internal.MotionHints.Clear then
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
    local preserveVisualMotion = phase == "arrived" and now < (tonumber(lane and lane.visualMovingUntil) or 0)
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

    if Diagnostics then
        Diagnostics.RecordLogicalAdvance(
            record,
            "path_service_active_move"
        )
    end

    now = Internal.Core.Now()
    if Internal.Animation
        and Internal.Animation.PumpBumpRelease
        and Internal.Animation.PumpBumpRelease(zombie, now)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.ownerMode = "bump_release"
        return true, "bump_release"
    elseif lane.ownerMode == "bump_release" then
        lane.ownerMode = "fake_locomotion"
    end
    if Internal.refreshTraversalMemory then
        Internal.refreshTraversalMemory(lane, zombie)
    end
    if lane.traversalAction and Internal.updateTraversalAction then
        local traversalActive
        local traversalState
        traversalActive, traversalState = Internal.updateTraversalAction(zombie, record, lane, now)
        if traversalActive then
            Internal.logMoveDebug(record, zombie, lane, "special_progress", traversalState or lane.ownerMode, "")
            return true, traversalState or lane.ownerMode
        end
        if traversalState == "completed" then
            Internal.logMoveDebug(record, zombie, lane, "special_complete", lane.lastTraversalFinishReason or "completed", "")
            return true, "traversal_completed"
        end
    end
    if (lane.ownerMode == "window_climb" or lane.ownerMode == "window_open" or lane.ownerMode == "window_smash" or lane.ownerMode == "door_open" or lane.ownerMode == "fence_climb")
        and now < (tonumber(lane.specialMoveUntil) or 0)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        Internal.logMoveDebug(record, zombie, lane, "special_cooldown", lane.ownerMode, "")
        return true, lane.ownerMode
    end

    Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    lane.lastActionState = Internal.getActionStateName(zombie)
    if Internal.tryDoorOrWindowInteraction
        and (
            lane.blockedStepToX ~= nil
            or Internal.hasClosedPassageToward
                and Internal.hasClosedPassageToward(
                    zombie,
                    goal.x,
                    goal.y,
                    goal.z
                )
        )
    then
        interacted, interactType = Internal.tryDoorOrWindowInteraction(zombie, record, lane, goal.x, goal.y, goal.z)
        if interacted then
            if Internal.clearBlockedStep then
                Internal.clearBlockedStep(lane)
            end
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
            elseif interactType == "window_smash" then
                lane.ownerMode = "window_smash"
            elseif interactType == "fence_climb" then
                lane.ownerMode = "fence_climb"
            else
                lane.ownerMode = "window_climb"
            end
            Internal.logMoveDebug(record, zombie, lane, "passage_interact", interactType or "door_or_window", "")
            return true, interactType or "interact"
        end
    elseif Internal.isDoorCollision
        and Internal.isDoorCollision(zombie)
        and Internal.tryDoorOrWindowInteraction
    then
        interacted, interactType = Internal.tryDoorOrWindowInteraction(zombie, record, lane, goal.x, goal.y, goal.z)
        if interacted then
            if Internal.clearBlockedStep then
                Internal.clearBlockedStep(lane)
            end
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
            elseif interactType == "window_smash" then
                lane.ownerMode = "window_smash"
            elseif interactType == "fence_climb" then
                lane.ownerMode = "fence_climb"
            else
                lane.ownerMode = "window_climb"
            end
            Internal.logMoveDebug(record, zombie, lane, "collision_interact", interactType or "door_or_window", "")
            return true, interactType or "interact"
        end
    end
    -- A collision can put the embodied zombie into a vanilla traversal state
    -- before a tiny fake-locomotion step crosses the tile boundary. Adopt the
    -- obstacle immediately instead of suppressing the state forever.
    if (lane.lastActionState == "climbfence" or lane.lastActionState == "climbwindow")
        and Internal.tryDoorOrWindowInteraction
    then
        interacted, interactType = Internal.tryDoorOrWindowInteraction(zombie, record, lane, goal.x, goal.y, goal.z)
        if interacted then
            if Internal.clearBlockedStep then
                Internal.clearBlockedStep(lane)
            end
            lane.lastIssueAt = now
            lane.noProgressCount = 0
            if interactType == "fence_climb" then
                lane.ownerMode = "fence_climb"
            elseif interactType == "window_climb" then
                lane.ownerMode = "window_climb"
            elseif interactType == "door_open" then
                lane.ownerMode = "door_open"
            elseif interactType == "window_open" then
                lane.ownerMode = "window_open"
            elseif interactType == "window_smash" then
                lane.ownerMode = "window_smash"
            end
            Internal.logMoveDebug(record, zombie, lane, "adopt_traversal", interactType or lane.lastActionState, "")
            return true, interactType or "traversal"
        end
    end
    if Internal.LiveBodyControl and Internal.LiveBodyControl.SuppressZombieState then
        suppressed, suppressedState = Internal.LiveBodyControl.SuppressZombieState(zombie, lane, now)
    else
        suppressed = false
        suppressedState = nil
    end
    if suppressed then
        lane.lastActionState = Internal.getActionStateName(zombie)
        lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
        lane.lastRecoveryReason = suppressedState or lane.lastActionState
        lane.lastRecoverAt = now
        if lane.navigationProvider ~= "engine_path"
            and Internal.FakeLocomotion
            and Internal.FakeLocomotion.PrepareBody
        then
            Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
        end
        if lane.ownerMode ~= "window_climb" and lane.ownerMode ~= "window_open" and lane.ownerMode ~= "window_smash" and lane.ownerMode ~= "fence_climb" then
            Internal.setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or "walk", false)
        end
        if lane.lastSuppressedWarnState ~= suppressedState
            or (now - (tonumber(lane.lastSuppressedWarnAt) or 0)) >= 15000
        then
            lane.lastSuppressedWarnState = suppressedState
            lane.lastSuppressedWarnAt = now
            Internal.logMoveWarning(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "action=" .. tostring(suppressedState or lane.lastActionState))
        end
        Internal.logMoveDebug(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "postAction=" .. tostring(lane.lastActionState))
    else
        lane.lastSuppressedWarnState = nil
        lane.lastSuppressedWarnAt = nil
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
            if lane.navigationProvider ~= "engine_path"
                and Internal.FakeLocomotion
                and Internal.FakeLocomotion.PrepareBody
            then
                Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
            end
            Internal.logMoveWarning(record, zombie, lane, "recover_nonlocomotion", recoveredState or "unknown", "action=" .. tostring(recoveredState or "unknown"))
            Internal.logMoveDebug(record, zombie, lane, "recover_nonlocomotion", recoveredState or "unknown", "")
            return true, "recovering"
        end
    end

    if lane.pendingGoal
        and (
            now - (tonumber(lane.pendingGoalAt) or now)
        ) >= Internal.GOAL_REFRESH_DELAY_MS
    then
        return Internal.refreshPendingGoal(zombie, record, lane, "goal_refresh")
    end

    if Internal.isAtGoal(zombie, goal, lane.stopDistance) then
        return Internal.completeMove(zombie, record, lane, "arrived", "arrived")
    end

    if lane.navigationProvider ~= "engine_path"
        and Internal.FakeLocomotion
        and Internal.FakeLocomotion.PrepareBody
    then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    if Internal.FakeLocomotion and Internal.FakeLocomotion.StepTowardGoal then
        stepped, stepResult, stepDistance = Internal.FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
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
            return Internal.completeMove(zombie, record, lane, "arrived", "arrived")
        end
        Internal.logMoveDebug(record, zombie, lane, "progress", "fake_step", "step=" .. tostring(stepResult or "direct") .. " dist=" .. string.format("%.3f", tonumber(stepDistance) or 0))
        return true, "moving"
    end

    -- A requested fake path is movement intent, not physical movement. Do
    -- not loop Run/Walk while throttled or blocked unless a real step occurred
    -- inside the short visual continuity lease.
    if now >= (tonumber(lane.visualMovingUntil) or 0) then
        Internal.applyHoldAnimation(zombie, record, lane)
    end

    if stepResult == "blocked"
        or stepResult == "interaction_blocked"
        or stepResult == "stalled"
    then
        lane.blockReason = stepResult == "stalled"
            and "no_goal_progress" or "fake_step_blocked"
        if stepResult == "stalled"
            and now - (tonumber(lane.lastNavigationInvalidatedAt) or 0)
                >= 500
            and PNC.NavigationRouter
            and PNC.NavigationRouter.Invalidate
        then
            PNC.NavigationRouter.Invalidate(
                record,
                "fake_locomotion_stalled"
            )
            lane.lastNavigationInvalidatedAt = now
        end
        Internal.logMoveDebug(record, zombie, lane, "step_blocked", stepResult, "dist=" .. string.format("%.3f", tonumber(stepDistance) or 0))
    end

    if stepResult ~= "throttle"
        and (
            (
                stepResult == "blocked"
                or stepResult == "interaction_blocked"
                or stepResult == "stalled"
            )
            or (now - (tonumber(lane.lastProgressAt) or 0))
                >= Internal.INTERACTION_STALL_MS
        )
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
            elseif interactType == "window_smash" then
                lane.ownerMode = "window_smash"
            elseif interactType == "fence_climb" then
                lane.ownerMode = "fence_climb"
            else
                lane.ownerMode = "window_climb"
            end
            Internal.logMoveDebug(record, zombie, lane, "interact", interactType or "door_or_window", "")
            return true, interactType or "interact"
        end
        if stepResult == "blocked"
            or stepResult == "interaction_blocked"
            or stepResult == "stalled"
        then
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
        if Diagnostics then Diagnostics.Increment("Pathing.Retries") end
        return true, "retry"
    end

    return true, "waiting"
end

function PathService.Reset(zombie, record)
    local lane = record and record.runtime and record.runtime.pathing or nil
    if lane and lane.traversalAction and Internal.clearTraversalAction then
        Internal.clearTraversalAction(zombie, lane, "reset")
    end
    if PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.Clear
    then
        PNC.EnginePathPlanner.Clear(record, zombie)
    end
    if record and record.runtime then
        record.runtime.pathing = nil
        record.runtime.moveIntent = nil
    end
    Internal.hardResetMoveOwner(zombie)
end

function PathService.MoveToward(
    record,
    zombie,
    targetX,
    targetY,
    targetZ,
    mode,
    stopDistance,
    reason,
    navigation
)
    local intent
    if Diagnostics
        and record
        and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
    then
        Diagnostics.Increment("LiveAbstract.AbstractPathRequests")
    end
    record.runtime = record.runtime or {}
    intent = record.runtime.moveIntent
    if not intent or intent.kind ~= "move" then
        intent = {}
        record.runtime.moveIntent = intent
    end
    intent.kind = "move"
    intent.x = tonumber(targetX) or record.x
    intent.y = tonumber(targetY) or record.y
    intent.z = tonumber(targetZ) or record.z or 0
    intent.mode = tostring(mode or "walk")
    intent.stopDistance = tonumber(stopDistance) or 0.7
    intent.reason = reason or "path_service_move"
    intent.requestedByJob = tostring(record.activeJob or "none")
    intent.requestedByBehavior = tostring(
        record.activeBehavior or record.activeJob or "none"
    )
    intent.requestedOrder = tostring(
        record.orderSpec and record.orderSpec.kind or "none"
    )
    intent.combatReason = tostring(
        record.runtime.combatBlockReason or "none"
    )
    intent.navigationPolicy = navigation
        and navigation.navigationPolicy or nil
    intent.navigationProvider = navigation
        and navigation.navigationProvider or nil
    intent.finalX = navigation and tonumber(navigation.finalX) or intent.x
    intent.finalY = navigation and tonumber(navigation.finalY) or intent.y
    intent.finalZ = navigation and tonumber(navigation.finalZ) or intent.z
    intent.waypointIndex = navigation
        and tonumber(navigation.waypointIndex) or nil
    intent.steeringIndex = navigation
        and tonumber(navigation.steeringIndex) or nil
    intent.steeringKind = navigation
        and tostring(navigation.steeringKind or "") or nil
    intent.updatedAt = Internal.Core.Now()
    if zombie and Internal.isAtGoal(zombie, Internal.buildGoal(targetX, targetY, targetZ, mode, stopDistance), stopDistance) then
        return true, "arrived"
    end
    return true, "move_intent"
end

function PathService.Pump(record, zombie, caller)
    local runtime = record and record.runtime or nil
    local lane
    local intentState
    local now
    local positionRepaired
    if Diagnostics then
        Diagnostics.RecordPathPump(
            record,
            caller or "scheduler_path_service"
        )
        if record
            and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
        then
            Diagnostics.Increment("LiveAbstract.AbstractPathRequests")
            if zombie then
                Diagnostics.Increment(
                    "LiveAbstract.AbstractPhysicalTraversal"
                )
            end
        end
    end
    if not zombie or not runtime then
        return false, "no_live_body"
    end

    lane = Internal.ensureMoveLane(record)
    now = Internal.Core.Now()
    -- A scripted window/fence crossing intentionally interpolates through a
    -- normally solid edge. Running generic unstuck recovery during that lease
    -- repeatedly teleports the body to the landing tile, after which the next
    -- traversal frame places it back inside the edge (the live log showed five
    -- recoveries during one window climb).
    if not lane.traversalAction
        and Internal.repairInvalidBodyPosition
    then
        positionRepaired = Internal.repairInvalidBodyPosition(
            record,
            zombie,
            lane,
            now
        )
        if positionRepaired
            and lane.navigationProvider ~= "engine_path"
            and Internal.FakeLocomotion
            and Internal.FakeLocomotion.PrepareBody
        then
            Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
        end
    end
    if not lane.traversalAction then
        Internal.applyCombatFacing(zombie, lane, now, false)
    end

    -- This guard intentionally runs before consuming or finalizing movement
    -- intents. Both startRequestedMove and finalizeCancel write locomotion/
    -- idle variables, so allowing either during the body-local bump tail can
    -- replace the weapon clip even after the combat action itself is done.
    if Internal.hasActiveAttack(record, now, zombie) then
        local nativeNavigation = record.runtime
            and record.runtime.localNavigation or nil
        local enginePlanner = PNC.EnginePathPlanner
        if nativeNavigation
            and nativeNavigation.nativeActive == true
            and enginePlanner
            and enginePlanner.Invalidate
        then
            enginePlanner.Invalidate(
                record,
                "combat_attack_lease",
                zombie
            )
        end
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.ownerMode = "attack_lease"
        return true, "attack_active"
    end

    intentState = Internal.consumeMoveIntent(record, lane, zombie)

    if lane.phase == "cancel_pending" then
        Internal.finalizeCancel(zombie, record, lane)
        intentState = Internal.consumeMoveIntent(record, lane, zombie)
    end

    if lane.phase == "requested" then
        local started
        local startState
        started, startState = Internal.startRequestedMove(
            zombie,
            record,
            lane
        )
        if started
            and lane.navigationProvider == "engine_path"
            and PNC.EnginePathPlanner
            and PNC.EnginePathPlanner.GetSteeringTarget
        then
            PNC.EnginePathPlanner.GetSteeringTarget(
                record,
                zombie,
                lane.goal
            )
        end
        return started, startState
    end

    if lane.phase == "active" then
        local enginePlanner = PNC.EnginePathPlanner
        local nativeNavigation = record.runtime
            and record.runtime.localNavigation or nil
        local scriptedPassageOwner = lane.traversalAction ~= nil
            or lane.blockedStepToX ~= nil
            or (
                Internal.LiveBodyControl
                and Internal.LiveBodyControl.IsMultiplayer
                and not Internal.LiveBodyControl.IsMultiplayer()
                and (
                    Internal.isDoorCollision
                    and Internal.isDoorCollision(zombie)
                    or Internal.hasClosedPassageToward
                    and lane.goal
                    and Internal.hasClosedPassageToward(
                        zombie,
                        lane.goal.x,
                        lane.goal.y,
                        lane.goal.z
                    )
                )
            )
        -- Bandits resolves collisions before processing its Move task. Preserve
        -- that ordering: scripted passage ownership must advance or acquire
        -- the obstacle before any new Behavior2 request can be submitted.
        if scriptedPassageOwner then
            return Internal.updateActiveMove(
                zombie,
                record,
                lane
            )
        end
        if lane.navigationProvider == "engine_path"
            and enginePlanner
            and enginePlanner.GetSteeringTarget
            and (
                not nativeNavigation
                or nativeNavigation.nativeActive ~= true
            )
        then
            enginePlanner.GetSteeringTarget(
                record,
                zombie,
                lane.goal
            )
        end
        nativeNavigation = record.runtime
            and record.runtime.localNavigation or nil
        if enginePlanner and enginePlanner.Pump
            and nativeNavigation
            and nativeNavigation.provider == "engine_path"
            and nativeNavigation.nativeActive == true
        then
            local handled
            local nativeState
            local nativeTraversalState
            local passageInteracted
            local passageKind
            local fromX = zombie:getX()
            local fromY = zombie:getY()
            local fromZ = zombie:getZ()
            -- Dedicated MP routes publish movement to the nearest client, but
            -- doors are authoritative world objects. Resolve an adjacent
            -- closed passage here before asking the client to re-path through
            -- it; the old fallback-only interaction branch was never reached
            -- by an engine_path lane.
            if lane.goal
                and Internal.hasClosedPassageToward
                and Internal.hasClosedPassageToward(
                    zombie,
                    lane.goal.x,
                    lane.goal.y,
                    lane.goal.z
                )
                and Internal.tryDoorOrWindowInteraction
            then
                passageInteracted, passageKind =
                    Internal.tryDoorOrWindowInteraction(
                        zombie,
                        record,
                        lane,
                        lane.goal.x,
                        lane.goal.y,
                        lane.goal.z
                    )
                if passageInteracted then
                    if Internal.clearBlockedStep then
                        Internal.clearBlockedStep(lane)
                    end
                    if enginePlanner.Invalidate then
                        enginePlanner.Invalidate(
                            record,
                            "native_" .. tostring(passageKind),
                            zombie
                        )
                    end
                    lane.ownerMode = passageKind or "passage_interact"
                    lane.lastProgressAt = now
                    lane.lastIssueAt = now
                    Internal.logMoveDebug(
                        record,
                        zombie,
                        lane,
                        "native_passage_interact",
                        passageKind or "passage",
                        ""
                    )
                    return true, passageKind or "passage_interact"
                end
            end
            nativeTraversalState = enginePlanner.Internal
                and enginePlanner.Internal.GetNativeTraversalState
                and enginePlanner.Internal.GetNativeTraversalState(
                    zombie
                )
                or nil
            if lane.goal then
                lane.resolvedMode = Internal.refreshResolvedLocomotion(
                    record,
                    lane,
                    zombie,
                    lane.goal
                )
                if nativeTraversalState == nil then
                    Internal.setWalkAnim(
                        zombie,
                        record,
                        lane.resolvedMode or lane.mode
                            or lane.goal.mode,
                        false
                    )
                end
            end
            handled, nativeState = enginePlanner.Pump(
                record,
                zombie,
                lane
            )
            if handled then
                local toX = zombie:getX()
                local toY = zombie:getY()
                local toZ = zombie:getZ()
                local dx = toX - fromX
                local dy = toY - fromY
                local stepDistance = math.sqrt(
                    (dx * dx) + (dy * dy)
                )
                local nativeFailed = nativeState == "engine_path_failed"
                    or nativeState == "engine_path_timeout"
                if nativeFailed then
                    lane.ownerMode = "engine_path_waiting"
                    lane.lastStepAt = now
                    lane.lastStepDistance = 0
                    lane.lastStepLabel = nativeState
                    if Internal.noteNativeGoalFailure
                        and Internal.noteNativeGoalFailure(
                            lane,
                            lane.goal,
                            now
                        )
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
                nativeTraversalState = nativeNavigation
                    and nativeNavigation.nativeTraversalState
                    or nil
                lane.ownerMode = nativeTraversalState
                    and "engine_traversal"
                    or "engine_path"
                lane.lastIssueAt = now
                lane.lastStepAt = now
                lane.lastStepDistance = stepDistance
                lane.lastStepLabel = nativeState
                if stepDistance > 0.0001 then
                    lane.lastProgressAt = now
                    lane.lastPhysicalMoveAt = now
                    lane.lastX = toX
                    lane.lastY = toY
                    lane.visualMovingUntil = now
                        + Internal.LOCOMOTION_VISUAL_LEASE_MS
                    if Internal.MotionHints
                        and Internal.MotionHints.Remember
                    then
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
                if Internal.syncRecordPosition then
                    Internal.syncRecordPosition(record, zombie)
                end
                if Internal.isAtGoal(
                        zombie,
                        lane.goal,
                        lane.stopDistance
                    ) then
                    return Internal.completeMove(
                        zombie,
                        record,
                        lane,
                        "arrived",
                        nativeState
                    )
                end
                return true, nativeState
            end
        end
        -- Native policies have one transport owner. A deferred, failed, or
        -- retrying engine request must remain stationary until it is
        -- resubmitted; falling through here would silently reactivate the old
        -- Lua setX/setY controller and duplicate collision/path work.
        if lane.navigationProvider == "engine_path" then
            lane.ownerMode = "engine_path_waiting"
            if now >= (tonumber(lane.visualMovingUntil) or 0) then
                Internal.applyHoldAnimation(zombie, record, lane)
            end
            return true, "native_waiting"
        end
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
    local elapsedMs = record and record.runtime
        and tonumber(record.runtime.abstractStepElapsedMs)
        or tonumber(PNC.Const.TICK_ABSTRACT_MS)
        or 3000
    local speed = tonumber(PNC.Const.ABSTRACT_TRAVEL_SPEED)
        or ((tonumber(PNC.Const.ABSTRACT_TRAVEL_STEP) or 5) / 3)
    local step = math.max(0, speed * math.max(0, elapsedMs) / 1000)
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
