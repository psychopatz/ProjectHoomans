-- Motion provider: stable public PathService motion commands.

local PathService = PNC.PathService
local Internal = PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

function PathService.Reset(zombie, record)
    local lane = record and record.runtime and record.runtime.pathing or nil
    if lane and lane.traversalAction and Internal.clearTraversalAction then
        Internal.clearTraversalAction(zombie, lane, "reset")
    end
    if PNC.EnginePathPlanner and PNC.EnginePathPlanner.Clear then
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
    if Diagnostics
        and record
        and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
    then
        Diagnostics.Increment("LiveAbstract.AbstractPathRequests")
    end
    record.runtime = record.runtime or {}
    local intent = record.runtime.moveIntent
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
    if zombie and Internal.isAtGoal(
        zombie,
        Internal.buildGoal(targetX, targetY, targetZ, mode, stopDistance),
        stopDistance
    ) then
        return true, "arrived"
    end
    return true, "move_intent"
end

function PathService.AdvanceAbstract(
    record,
    targetX,
    targetY,
    targetZ,
    stopDistance
)
    local elapsedMs = record and record.runtime
        and tonumber(record.runtime.abstractStepElapsedMs)
        or tonumber(PNC.Const.TICK_ABSTRACT_MS)
        or 3000
    local speed = tonumber(PNC.Const.ABSTRACT_TRAVEL_SPEED)
        or ((tonumber(PNC.Const.ABSTRACT_TRAVEL_STEP) or 5) / 3)
    local step = math.max(0, speed * math.max(0, elapsedMs) / 1000)
    stopDistance = tonumber(stopDistance) or 1.0
    local dist = Internal.Core.Distance(record.x, record.y, targetX, targetY)
    if dist <= stopDistance and record.z == targetZ then
        return true
    end
    local dx = targetX - record.x
    local dy = targetY - record.y
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0 then
        return true
    end
    record.x = record.x + (dx / len) * math.min(step, len)
    record.y = record.y + (dy / len) * math.min(step, len)
    record.z = targetZ
    return false
end
