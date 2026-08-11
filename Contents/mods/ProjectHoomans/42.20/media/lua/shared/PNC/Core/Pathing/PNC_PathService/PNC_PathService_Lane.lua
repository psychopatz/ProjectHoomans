--[[
    PNC Path Service Lane
    Shared movement-lane state and intent consumption helpers.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local Const = PNC.Const or {}

local TRAVERSAL_OWNER_MODES = {
    door_open = true,
    fence_climb = true,
    window_climb = true,
    window_open = true,
}

local function continuousGoalTolerance(intent)
    if not intent or intent.navigationProvider == nil then
        return nil
    end
    return tonumber(PNC.Const and PNC.Const.PATH_CONTINUOUS_RETARGET_DISTANCE)
        or 0.22
end

function PathService.IsTraversalActive(record, zombie)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local modData
    local actionState
    if lane and lane.traversalAction then
        return true, lane.traversalAction.kind or lane.ownerMode or "traversal"
    end
    if lane and TRAVERSAL_OWNER_MODES[tostring(lane.ownerMode or "")] then
        return true, lane.ownerMode
    end
    modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData and modData.PNC_BumpReleasePending == true and lane and lane.lastTraversalKind then
        return true, "traversal_release"
    end
    actionState = zombie and zombie.getActionStateName and string.lower(tostring(zombie:getActionStateName() or "")) or ""
    if actionState == "climbfence" or actionState == "climbwindow" then
        return true, actionState
    end
    return false, nil
end

function Internal.ensureMoveLane(record)
    local runtime
    local lane
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    lane = runtime.pathing or {}
    runtime.pathing = lane
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
    lane.nativeFailureCount = tonumber(lane.nativeFailureCount) or 0
    lane.nativeFailureGoalX = lane.nativeFailureGoalX ~= nil
        and tonumber(lane.nativeFailureGoalX) or nil
    lane.nativeFailureGoalY = lane.nativeFailureGoalY ~= nil
        and tonumber(lane.nativeFailureGoalY) or nil
    lane.nativeFailureGoalZ = lane.nativeFailureGoalZ ~= nil
        and tonumber(lane.nativeFailureGoalZ) or nil
    lane.nativeBlockedGoalX = lane.nativeBlockedGoalX ~= nil
        and tonumber(lane.nativeBlockedGoalX) or nil
    lane.nativeBlockedGoalY = lane.nativeBlockedGoalY ~= nil
        and tonumber(lane.nativeBlockedGoalY) or nil
    lane.nativeBlockedGoalZ = lane.nativeBlockedGoalZ ~= nil
        and tonumber(lane.nativeBlockedGoalZ) or nil
    lane.nativeBlockedUntil = tonumber(lane.nativeBlockedUntil) or 0
    lane.lastSpecialActionKey = lane.lastSpecialActionKey or nil
    lane.lastSpecialActionAt = tonumber(lane.lastSpecialActionAt) or 0
    lane.specialMoveUntil = tonumber(lane.specialMoveUntil) or 0
    lane.specialAnim = lane.specialAnim or nil
    lane.resolvedMode = lane.resolvedMode or nil
    lane.animSpeed = tonumber(lane.animSpeed) or 1.0
    lane.speed = tonumber(lane.speed) or 0
    lane.moveAnim = lane.moveAnim or "Idle"
    lane.walkType = lane.walkType or ""
    lane.engineWalkType = lane.engineWalkType or ""
    lane.profileKey = lane.profileKey or "idle"
    lane.staminaMode = lane.staminaMode or "travel"
    lane.isRunning = lane.isRunning == true
    lane.isCrawling = lane.isCrawling == true
    lane.motionProfile = lane.motionProfile or nil
    lane.motionHint = type(lane.motionHint) == "table" and lane.motionHint or nil
    lane.lastSuppressAudioAt = tonumber(lane.lastSuppressAudioAt) or 0
    lane.lastNetworkX = lane.lastNetworkX ~= nil and tonumber(lane.lastNetworkX) or nil
    lane.lastNetworkY = lane.lastNetworkY ~= nil and tonumber(lane.lastNetworkY) or nil
    lane.lastNetworkZ = lane.lastNetworkZ ~= nil and tonumber(lane.lastNetworkZ) or nil
    lane.lastNetworkAt = tonumber(lane.lastNetworkAt) or 0
    lane.lastTraversalObstacleKey = lane.lastTraversalObstacleKey or nil
    lane.lastTraversalKind = lane.lastTraversalKind or nil
    lane.lastTraversalFromKey = lane.lastTraversalFromKey or nil
    lane.lastTraversalToKey = lane.lastTraversalToKey or nil
    lane.lastTraversalFromX = lane.lastTraversalFromX ~= nil and tonumber(lane.lastTraversalFromX) or nil
    lane.lastTraversalFromY = lane.lastTraversalFromY ~= nil and tonumber(lane.lastTraversalFromY) or nil
    lane.lastTraversalFromZ = lane.lastTraversalFromZ ~= nil and tonumber(lane.lastTraversalFromZ) or nil
    lane.lastTraversalToX = lane.lastTraversalToX ~= nil and tonumber(lane.lastTraversalToX) or nil
    lane.lastTraversalToY = lane.lastTraversalToY ~= nil and tonumber(lane.lastTraversalToY) or nil
    lane.lastTraversalToZ = lane.lastTraversalToZ ~= nil and tonumber(lane.lastTraversalToZ) or nil
    lane.lastTraversalAttemptAt = tonumber(lane.lastTraversalAttemptAt) or 0
    lane.lastTraversalGoalRevision = tonumber(lane.lastTraversalGoalRevision) or 0
    lane.lastNonLocomotionState = lane.lastNonLocomotionState or nil
    lane.lastNonLocomotionAt = tonumber(lane.lastNonLocomotionAt) or 0
    lane.ownerMode = lane.ownerMode or "idle"
    lane.facingOwner = lane.facingOwner or "idle"
    lane.combatFacingUntil = tonumber(lane.combatFacingUntil) or 0
    lane.combatFacingX = lane.combatFacingX ~= nil and tonumber(lane.combatFacingX) or nil
    lane.combatFacingY = lane.combatFacingY ~= nil and tonumber(lane.combatFacingY) or nil
    lane.combatFacingZ = lane.combatFacingZ ~= nil and tonumber(lane.combatFacingZ) or nil
    lane.combatFacingReason = lane.combatFacingReason or nil
    lane.lastFacingAt = tonumber(lane.lastFacingAt) or 0
    lane.lastFacingDirX = lane.lastFacingDirX ~= nil and tonumber(lane.lastFacingDirX) or nil
    lane.lastFacingDirY = lane.lastFacingDirY ~= nil and tonumber(lane.lastFacingDirY) or nil
    lane.lastFacingX = lane.lastFacingX ~= nil and tonumber(lane.lastFacingX) or nil
    lane.lastFacingY = lane.lastFacingY ~= nil and tonumber(lane.lastFacingY) or nil
    lane.vehicleBlockedGoalX = lane.vehicleBlockedGoalX ~= nil
        and tonumber(lane.vehicleBlockedGoalX) or nil
    lane.vehicleBlockedGoalY = lane.vehicleBlockedGoalY ~= nil
        and tonumber(lane.vehicleBlockedGoalY) or nil
    lane.vehicleBlockedGoalZ = lane.vehicleBlockedGoalZ ~= nil
        and tonumber(lane.vehicleBlockedGoalZ) or nil
    lane.vehicleBlockedFromX = lane.vehicleBlockedFromX ~= nil
        and tonumber(lane.vehicleBlockedFromX) or nil
    lane.vehicleBlockedFromY = lane.vehicleBlockedFromY ~= nil
        and tonumber(lane.vehicleBlockedFromY) or nil
    lane.vehicleBlockedFromZ = lane.vehicleBlockedFromZ ~= nil
        and tonumber(lane.vehicleBlockedFromZ) or nil
    lane.vehicleBlockedAt = tonumber(lane.vehicleBlockedAt) or 0
    lane.vehicleBlockedReason = lane.vehicleBlockedReason or nil
    return lane
end

function Internal.clearNativeGoalBlock(lane)
    if not lane then return end
    lane.nativeFailureCount = 0
    lane.nativeFailureGoalX = nil
    lane.nativeFailureGoalY = nil
    lane.nativeFailureGoalZ = nil
    lane.nativeBlockedGoalX = nil
    lane.nativeBlockedGoalY = nil
    lane.nativeBlockedGoalZ = nil
    lane.nativeBlockedUntil = 0
end

local function nativeGoalDistance(lane, goal, prefix)
    local x = tonumber(lane[prefix .. "X"])
    local y = tonumber(lane[prefix .. "Y"])
    local z = tonumber(lane[prefix .. "Z"])
    if x == nil or y == nil or not goal then return math.huge end
    local dx = (tonumber(goal.x) or 0) - x
    local dy = (tonumber(goal.y) or 0) - y
    local dz = (tonumber(goal.z) or 0) - (z or 0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

function Internal.isNativeGoalBlocked(lane, goal, now)
    if not lane or lane.nativeBlockedGoalX == nil then return false end
    now = tonumber(now) or Internal.Core.Now()
    local changeDistance = math.max(
        0.5,
        tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_CHANGE_DISTANCE) or 1.5
    )
    if now >= (tonumber(lane.nativeBlockedUntil) or 0)
        or nativeGoalDistance(lane, goal, "nativeBlockedGoal")
            >= changeDistance
    then
        Internal.clearNativeGoalBlock(lane)
        return false
    end
    return true
end

function Internal.noteNativeGoalFailure(lane, goal, now)
    if not lane or not goal then return false end
    now = tonumber(now) or Internal.Core.Now()
    local changeDistance = math.max(
        0.5,
        tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_CHANGE_DISTANCE) or 1.5
    )
    if nativeGoalDistance(lane, goal, "nativeFailureGoal")
        >= changeDistance
    then
        lane.nativeFailureCount = 0
    end
    lane.nativeFailureGoalX = tonumber(goal.x)
    lane.nativeFailureGoalY = tonumber(goal.y)
    lane.nativeFailureGoalZ = tonumber(goal.z)
    lane.nativeFailureCount =
        (tonumber(lane.nativeFailureCount) or 0) + 1
    local failureLimit = tonumber(Const.ENGINE_PATH_FAILURE_LIMIT) or 2
    local followGoal = string.sub(tostring(lane.intentReason or ""), 1, 12)
        == "follow_owner"
    if followGoal then
        failureLimit = 1
    end
    if lane.nativeFailureCount < math.max(
        1,
        math.floor(failureLimit)
    ) then
        return false
    end
    lane.nativeBlockedGoalX = lane.nativeFailureGoalX
    lane.nativeBlockedGoalY = lane.nativeFailureGoalY
    lane.nativeBlockedGoalZ = lane.nativeFailureGoalZ
    local blockedCooldown = followGoal
        and (tonumber(Const.FOLLOW_PATH_BLOCKED_COOLDOWN_MS) or 1200)
        or (tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_COOLDOWN_MS) or 10000)
    lane.nativeBlockedUntil = now + math.max(1000, blockedCooldown)
    return true
end

function Internal.clearVehicleBlockedGoal(lane)
    if not lane then return end
    lane.vehicleBlockedGoalX = nil
    lane.vehicleBlockedGoalY = nil
    lane.vehicleBlockedGoalZ = nil
    lane.vehicleBlockedFromX = nil
    lane.vehicleBlockedFromY = nil
    lane.vehicleBlockedFromZ = nil
    lane.vehicleBlockedAt = 0
    lane.vehicleBlockedReason = nil
end

function Internal.isVehicleBlockedGoal(lane, intent)
    local dx
    local dy
    local dz
    local distance
    local query
    local occupancyReason
    if not lane or not intent or intent.kind ~= "move"
        or lane.vehicleBlockedGoalX == nil
        or lane.vehicleBlockedFromX == nil
    then
        return false
    end
    dx = (tonumber(intent.x) or 0) - lane.vehicleBlockedGoalX
    dy = (tonumber(intent.y) or 0) - lane.vehicleBlockedGoalY
    dz = (tonumber(intent.z) or 0) - (tonumber(lane.vehicleBlockedGoalZ) or 0)
    distance = math.sqrt((dx * dx) + (dy * dy))
    if distance >= Internal.VEHICLE_BLOCKED_GOAL_CHANGE_DISTANCE
        or math.abs(dz) >= 1
    then
        Internal.clearVehicleBlockedGoal(lane)
        return false
    end
    query = Internal.TraversalQuery or PNC.TraversalQuery
    occupancyReason = query and query.GetOccupancyReason
        and query.GetOccupancyReason(
            lane.vehicleBlockedFromX,
            lane.vehicleBlockedFromY,
            lane.vehicleBlockedFromZ
        )
        or nil
    if occupancyReason ~= "vehicle" then
        Internal.clearVehicleBlockedGoal(lane)
        return false
    end
    return true
end

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
    lane.blockedStepFromX = nil
    lane.blockedStepFromY = nil
    lane.blockedStepFromZ = nil
    lane.blockedStepToX = nil
    lane.blockedStepToY = nil
    lane.blockedStepToZ = nil
    lane.blockedStepReason = nil
    lane.ownerMode = "requested"
end

function Internal.retargetLaneGoal(record, lane, goal)
    local now
    if not lane or not goal then
        return false
    end
    now = Internal.Core.Now()
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
    lane.blockedStepFromX = nil
    lane.blockedStepFromY = nil
    lane.blockedStepFromZ = nil
    lane.blockedStepToX = nil
    lane.blockedStepToY = nil
    lane.blockedStepToZ = nil
    lane.blockedStepReason = nil
    lane.goalDistance = nil
    lane.bestGoalDistance = nil
    lane.lastProgressDelta = 0
    lane.lastProgressAt = now
    lane.lastGoalProgressAt = now
    lane.nonProgressStepCount = 0
    lane.noProgressCount = 0
    lane.steeringSide = nil
    lane.directStepCount = 0
    lane.retargetCount = (tonumber(lane.retargetCount) or 0) + 1
    lane.lastRetargetAt = now
    return true
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

function Internal.consumeMoveIntent(record, lane, zombie)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local goal
    local continuousSteering
    local goalTolerance
    local goalsDiffer
    if not runtime then
        return "hold"
    end
    goalTolerance = continuousGoalTolerance(intent)
    if Internal.isVehicleBlockedGoal(lane, intent) then
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
    if lane and lane.traversalAction then
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
    if not intent or intent.kind == "hold" then
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

    if lane.goal == nil or lane.phase == "idle" or lane.phase == "arrived" or lane.phase == "blocked" then
        Internal.setLaneGoal(record, lane, goal)
        lane.pendingGoal = nil
        Internal.setLanePhase(record, lane, "requested", "new_goal")
        return "requested"
    end

    continuousSteering = intent.navigationProvider ~= nil
    goalsDiffer = Internal.goalsDiffer(
        lane.goal,
        goal,
        lane.mode,
        goalTolerance
    )
    if goalsDiffer then
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

    return "unchanged"
end
