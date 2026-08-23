-- Physical route progress, request timeouts, and movement-state publication.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Internal.UpdateRouteProgress(body, navigation, now)
    local x = body:getX()
    local y = body:getY()
    local z = body:getZ()
    local dx = x - (tonumber(navigation.lastObservedX) or x)
    local dy = y - (tonumber(navigation.lastObservedY) or y)
    local dz = z - (tonumber(navigation.lastObservedZ) or z)
    if (dx * dx) + (dy * dy) + (dz * dz) >= 0.0025 then
        navigation.lastPhysicalProgressAt = now
    end
    navigation.lastObservedX = x
    navigation.lastObservedY = y
    navigation.lastObservedZ = z

    local requestTimeoutMs = math.max(
        500,
        tonumber(Const.ENGINE_PATH_REQUEST_TIMEOUT_MS) or 2500
    )
    local hasPath = body and body.getPath2 and body:getPath2() ~= nil
    local movementState = Internal.GetNativeMovementState(body)
    if not hasPath and movementState == nil
        and now - (tonumber(navigation.requestStartedAt) or now)
            >= requestTimeoutMs
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_request_timeout"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        if Diagnostics then Diagnostics.Increment("Pathing.Timeouts") end
        return true, "engine_path_timeout"
    end
    if (hasPath or movementState ~= nil)
        and (tonumber(navigation.movingStartedAt) or 0) <= 0
    then
        navigation.movingStartedAt = now
    end
    local routeTimeoutMs = math.max(
        requestTimeoutMs,
        tonumber(Const.ENGINE_PATH_ROUTE_TIMEOUT_MS) or 15000
    )
    if now - (
        tonumber(navigation.lastPhysicalProgressAt)
            or navigation.requestStartedAt
            or now
    ) >= routeTimeoutMs
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_route_timeout"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        if Diagnostics then Diagnostics.Increment("Pathing.Timeouts") end
        return true, "engine_path_timeout"
    end

    local traversalState = Internal.GetNativeTraversalState(body)
    if traversalState ~= nil then
        navigation.nativeTraversalState = traversalState
        navigation.nativeTraversalStartedAt =
            (tonumber(navigation.nativeTraversalStartedAt) or 0) > 0
                and navigation.nativeTraversalStartedAt
                or now
        navigation.requestPending = false
        navigation.lastPlanReason = "native_traversal_" .. traversalState
        navigation.steeringKind = "engine_native"
        Internal.SetServerMovementLease(body, navigation, true)
        return true, navigation.lastPlanReason
    end
    navigation.requestPending = navigation.controllerMode
        == "behavior2_move"
        and not hasPath
        or (not hasPath and movementState == "pathfind")
    if navigation.controllerMode == "behavior2_move" then
        navigation.lastPlanReason = navigation.requestPending
            and "native_behavior_pending"
            or "native_behavior_moving"
        navigation.steeringKind = "engine_native_behavior2"
    else
        navigation.lastPlanReason = navigation.requestPending
            and "native_path_pending" or "native_path_moving"
        navigation.steeringKind = "engine_native"
    end
    return true, navigation.lastPlanReason
end
