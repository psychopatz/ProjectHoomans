-- Move-intent capture and lane transition orchestration.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

local function continuousGoalTolerance(intent)
    if not intent or intent.navigationProvider == nil then
        return nil
    end
    return tonumber(PNC.Const and PNC.Const.PATH_CONTINUOUS_RETARGET_DISTANCE)
        or 0.22
end

function Internal.captureIntentContext(record, lane, intent)
    if not lane then
        return
    end
    lane.intentReason = intent and intent.reason or nil
    lane.requestedByJob = intent and intent.requestedByJob or tostring(record and record.activeJob or "none")
    lane.requestedByBehavior = intent and intent.requestedByBehavior or tostring(record and record.activeBehavior or record and record.activeJob or "none")
    lane.requestedOrder = intent and intent.requestedOrder or tostring(record and record.orderSpec and record.orderSpec.kind or "none")
    lane.navigationPolicy = intent and intent.navigationPolicy or nil
    lane.navigationProvider = intent and intent.navigationProvider or nil
    lane.finalGoalX = intent and tonumber(intent.finalX) or nil
    lane.finalGoalY = intent and tonumber(intent.finalY) or nil
    lane.finalGoalZ = intent and tonumber(intent.finalZ) or nil
    lane.waypointIndex = intent
        and tonumber(intent.waypointIndex) or nil
    lane.steeringIndex = intent
        and tonumber(intent.steeringIndex) or nil
    lane.steeringKind = intent and intent.steeringKind or nil
end

local function consumeVehicleBlockedIntent(record, lane, intent)
    Internal.captureIntentContext(record, lane, intent)
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.cancelReason = "vehicle_path_blocked"
    if lane.phase == "active" or lane.phase == "requested" then
        Internal.setLanePhase(
            record,
            lane,
            "cancel_pending",
            "vehicle_path_blocked"
        )
    elseif lane.phase ~= "idle" and lane.phase ~= "cancel_pending" then
        Internal.setLanePhase(
            record,
            lane,
            "idle",
            "vehicle_path_blocked"
        )
    end
    return "vehicle_blocked"
end

local function consumeTraversalIntent(record, lane, intent, goalTolerance)
    local goal
    Internal.captureIntentContext(record, lane, intent)
    if intent and intent.kind ~= "hold" then
        goal = Internal.buildGoal(
            intent.x,
            intent.y,
            intent.z,
            intent.mode,
            intent.stopDistance
        )
        if not lane.pendingGoal
            or Internal.goalsDiffer(
                lane.pendingGoal,
                goal,
                lane.mode,
                goalTolerance
            )
        then
            lane.pendingGoalAt = Internal.Core.Now()
        end
        lane.pendingGoal = goal
    end
    return "special_active"
end

local function consumeHoldIntent(record, lane, intent)
    Internal.captureIntentContext(record, lane, intent)
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    if lane.phase == "active" or lane.phase == "requested" then
        lane.cancelReason = intent and intent.reason or "hold"
        Internal.setLanePhase(record, lane, "cancel_pending", lane.cancelReason)
    elseif lane.phase ~= "idle" then
        Internal.setLanePhase(record, lane, "idle", intent and intent.reason or "hold")
    end
    return "hold"
end

local function consumeArrivedIntent(record, lane, goal)
    lane.pendingGoal = nil
    lane.pendingGoalAt = 0
    lane.goal = goal
    lane.mode = goal.mode
    lane.stopDistance = goal.stopDistance
    if lane.phase == "active" or lane.phase == "requested" then
        lane.cancelReason = "arrived"
        Internal.setLanePhase(record, lane, "cancel_pending", "arrived")
    else
        Internal.setLanePhase(record, lane, "arrived", "intent_arrived")
    end
    return "arrived"
end

local function consumeChangedGoal(
    record,
    lane,
    goal,
    continuousSteering,
    goalTolerance
)
    if continuousSteering and lane.phase == "active" then
        Internal.retargetLaneGoal(record, lane, goal)
        return "retargeted"
    end
    if not lane.pendingGoal
        or Internal.goalsDiffer(
            lane.pendingGoal,
            goal,
            lane.mode,
            goalTolerance
        )
    then
        lane.pendingGoalAt = Internal.Core.Now()
    end
    lane.pendingGoal = goal
    if lane.phase == "requested" then
        Internal.setLaneGoal(record, lane, goal)
        lane.pendingGoal = nil
        Internal.setLanePhase(record, lane, "requested", "goal_refresh")
        return "requested"
    end
    return "refresh_pending"
end

function Internal.consumeMoveIntent(record, lane, zombie)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local goal
    local continuousSteering
    local goalTolerance
    if not runtime then
        return "hold"
    end
    goalTolerance = continuousGoalTolerance(intent)
    if Internal.isVehicleBlockedGoal(lane, intent) then
        return consumeVehicleBlockedIntent(record, lane, intent)
    end
    if lane and lane.traversalAction then
        return consumeTraversalIntent(record, lane, intent, goalTolerance)
    end
    if not intent or intent.kind == "hold" then
        return consumeHoldIntent(record, lane, intent)
    end

    goal = Internal.buildGoal(intent.x, intent.y, intent.z, intent.mode, intent.stopDistance)
    Internal.captureIntentContext(record, lane, intent)
    if Internal.isNativeGoalBlocked
        and Internal.isNativeGoalBlocked(
            lane,
            goal,
            Internal.Core.Now()
        )
    then
        lane.pendingGoal = nil
        lane.pendingGoalAt = 0
        lane.blockReason = "native_goal_cooldown"
        return "navigation_blocked"
    end
    if zombie and Internal.isAtGoal(zombie, goal, goal.stopDistance) then
        return consumeArrivedIntent(record, lane, goal)
    end

    if lane.goal == nil or lane.phase == "idle" or lane.phase == "arrived" or lane.phase == "blocked" then
        Internal.setLaneGoal(record, lane, goal)
        lane.pendingGoal = nil
        Internal.setLanePhase(record, lane, "requested", "new_goal")
        return "requested"
    end

    continuousSteering = intent.navigationProvider ~= nil
    if Internal.goalsDiffer(
        lane.goal,
        goal,
        lane.mode,
        goalTolerance
    ) then
        return consumeChangedGoal(
            record,
            lane,
            goal,
            continuousSteering,
            goalTolerance
        )
    end
    return "unchanged"
end
