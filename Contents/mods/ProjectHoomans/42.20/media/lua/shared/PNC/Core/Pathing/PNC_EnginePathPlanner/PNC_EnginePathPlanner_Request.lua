-- Native-path capability checks and request acquisition.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Planner.CanUseNativePath(body)
    if not body then return false, "native_path_unavailable" end
    if Internal.IsMultiplayerAuthority
        and Internal.IsMultiplayerAuthority()
    then
        if not body.pathToLocationF then
            return false, "native_path_unavailable"
        end
        return true
    end
    local behavior = Internal.GetPathBehavior(body)
    if not behavior
        or not behavior.pathToLocation
        or not behavior.update
    then
        return false, "native_behavior_unavailable"
    end
    return true
end

function Internal.BeginRequest(body, finalTarget, navigation, now, reason)
    local multiplayerAuthority = Internal.IsMultiplayerAuthority()
    local nativeSafe
    local unsafeReason
    nativeSafe, unsafeReason = Planner.CanUseNativePath(body)
    if not nativeSafe then
        navigation.lastPlanReason = unsafeReason
        navigation.plannedAt = now
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return false
    end
    Internal.ClearEngineRequest(body, navigation)
    Internal.EnsureNativeMovementOwner(body)
    if Diagnostics then
        Diagnostics.Increment("Pathing.EnginePathRequests")
    end
    local x = tonumber(finalTarget.x) or body:getX()
    local y = tonumber(finalTarget.y) or body:getY()
    local z = tonumber(finalTarget.z) or body:getZ()
    if not multiplayerAuthority then
        local behavior = Internal.GetPathBehavior(body)
        behavior:pathToLocation(x, y, z)
    end
    navigation.requestPending = true
    navigation.nativeActive = true
    navigation.controllerMode = multiplayerAuthority
        and "client_goto" or "behavior2_move"
    navigation.lastBehaviorResult = nil
    navigation.lastBehaviorUpdateAt = multiplayerAuthority and 0 or now
    navigation.clientDelegated = multiplayerAuthority == true
    navigation.requestRevision =
        (tonumber(navigation.requestRevision) or 0) + 1
    navigation.requestStartedAt = now
    navigation.movingStartedAt = 0
    navigation.plannedAt = now
    navigation.requestX = x
    navigation.requestY = y
    navigation.requestZ = z
    navigation.requestStopDistance = math.max(
        0.1,
        tonumber(finalTarget.stopDistance) or 0.7
    )
    navigation.lastObservedX = body:getX()
    navigation.lastObservedY = body:getY()
    navigation.lastObservedZ = body:getZ()
    navigation.lastPhysicalProgressAt = now
    navigation.lastPlanReason = reason or "native_request"
    navigation.steeringKind = multiplayerAuthority
        and "engine_native_client"
        or "engine_native_behavior2"
    Internal.SetServerMovementLease(body, navigation, true)
    if not multiplayerAuthority then
        local handedOff = Internal.HandoffUpcomingPassage(
            navigation.record,
            body,
            navigation
        )
        if handedOff then return true end
    end
    return true
end
