-- Native traversal-state ownership and timeout handling.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Internal.HandleTraversalOwnership(body, navigation, now)
    local traversalState = Internal.GetNativeTraversalState(body)
    if traversalState ~= nil
        and navigation.controllerMode == "behavior2_move"
    then
        Internal.ClearEngineRequest(body, navigation)
        if PNC.LiveBodyControl and PNC.LiveBodyControl.SuppressZombieState then
            PNC.LiveBodyControl.SuppressZombieState(body, nil, now)
        end
        navigation.lastPlanReason = "unsafe_native_traversal"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        if Diagnostics then
            Diagnostics.Increment("Pathing.UnsafeNativeTraversalEscapes")
        end
        return true, "engine_path_failed"
    end
    if navigation.nativeTraversalState ~= nil then
        if traversalState ~= nil then
            local traversalTimeoutMs = math.max(
                1000,
                tonumber(Const.ENGINE_PATH_TRAVERSAL_TIMEOUT_MS) or 3000
            )
            if now - (
                tonumber(navigation.nativeTraversalStartedAt) or now
            ) < traversalTimeoutMs
            then
                navigation.nativeTraversalState = traversalState
                navigation.lastPlanReason =
                    "native_traversal_" .. traversalState
                Internal.SetServerMovementLease(body, navigation, true)
                return true, navigation.lastPlanReason
            end
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason = "native_traversal_timeout"
            navigation.planFailures =
                (tonumber(navigation.planFailures) or 0) + 1
            if Diagnostics then Diagnostics.Increment("Pathing.Timeouts") end
            return true, "engine_path_failed"
        end
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
    end
    return false, nil
end
