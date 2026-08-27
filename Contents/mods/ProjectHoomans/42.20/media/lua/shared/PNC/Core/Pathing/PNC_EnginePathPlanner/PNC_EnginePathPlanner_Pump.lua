-- Native route pump orchestration.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Planner.Pump(record, body, source)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if not navigation
        or navigation.provider ~= "engine_path"
        or not navigation.nativeActive
    then
        return false, "native_inactive"
    end
    local now = Core and Core.Now and Core.Now() or 0
    source = tostring(source or "scheduled")
    Internal.EnsureNativeMovementOwner(body)
    if Diagnostics then
        Diagnostics.RecordPathPump(record, source)
        if record and record.presenceState == PNC.Const.PRESENCE_ABSTRACT then
            Diagnostics.Increment("LiveAbstract.AbstractPhysicalTraversal")
        end
    end
    if navigation.clientDelegated == true
        and Internal.IsMultiplayerAuthority()
    then
        local traversalState = Internal.GetNativeTraversalState(body)
        navigation.lastPumpAt = now
        navigation.requestPending = false
        navigation.nativeTraversalState = traversalState
        navigation.lastPlanReason = traversalState
            and ("client_native_" .. traversalState)
            or "client_native_moving"
        navigation.steeringKind = "engine_native_client"
        Internal.SetServerMovementLease(body, navigation, true)
        return true, navigation.lastPlanReason
    end

    local behavior = Internal.GetPathBehavior(body)
    if navigation.controllerMode == "behavior2_move"
        and (
            not behavior
            or not behavior.pathToLocation
            or not behavior.update
        )
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_behavior_unavailable"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return true, "engine_path_failed"
    end
    navigation.lastPumpAt = now
    if Internal.IsAtRequestGoal(body, navigation) then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_path_succeeded"
        navigation.planFailures = 0
        navigation.completedAt = now
        return true, "engine_path_succeeded"
    end
    if navigation.controllerMode == "behavior2_move"
        and source == "zombie_update"
        and (tonumber(navigation.lastBehaviorUpdateAt) or 0) ~= now
    then
        local handedOff
        local handoffResult
        handedOff, handoffResult = Internal.HandoffUpcomingPassage(
            record,
            body,
            navigation
        )
        if handedOff then return true, handoffResult end
        if Diagnostics then
            Diagnostics.RecordLogicalAdvance(record, "engine_behavior2")
        end
        local result = behavior:update()
        navigation.lastBehaviorResult = result
        navigation.lastBehaviorUpdateAt = now
        if Internal.ResultMatches(result, "Failed") then
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason = "native_behavior_failed"
            navigation.planFailures =
                (tonumber(navigation.planFailures) or 0) + 1
            return true, "engine_path_failed"
        end
        if Internal.ResultMatches(result, "Succeeded") then
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason = "native_behavior_succeeded"
            navigation.planFailures = 0
            navigation.completedAt = now
            return true, "engine_path_succeeded"
        end
        handedOff, handoffResult = Internal.HandoffUpcomingPassage(
            record,
            body,
            navigation
        )
        if handedOff then return true, handoffResult end
    end
    local traversalHandled
    local traversalResult
    traversalHandled, traversalResult =
        Internal.HandleTraversalOwnership(body, navigation, now)
    if traversalHandled then return true, traversalResult end
    return Internal.UpdateRouteProgress(body, navigation, now)
end
