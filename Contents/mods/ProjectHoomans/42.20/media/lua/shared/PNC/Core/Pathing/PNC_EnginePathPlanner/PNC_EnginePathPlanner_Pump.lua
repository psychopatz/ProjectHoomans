-- Native route pump orchestration.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function suppressConflictingNativeState(body, navigation, now)
    local liveBodyControl = PNC.LiveBodyControl
    local actionState
    if not body or not navigation
        or navigation.controllerMode ~= "behavior2_move"
        or not liveBodyControl
        or not liveBodyControl.IsSuppressedActionState
        or not liveBodyControl.SuppressZombieState
    then
        return false
    end
    -- Fence/window/wall states are a deliberate traversal handoff and must
    -- remain owned by the traversal provider. Limit this repair to the
    -- vanilla pathfind state observed to compete with Behavior2. Combat
    -- bumps, attacks, lunge, and other action leases must
    -- remain available to their respective owners.
    actionState = body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or "")) or ""
    if actionState ~= "pathfind"
        or not liveBodyControl.IsSuppressedActionState(actionState)
    then
        return false
    end
    -- PathFindState without path2 is still the vanilla request/follow
    -- startup path. Resetting it here prevents Behavior2 from ever acquiring
    -- the route and leaves the NPC idle forever. Only repair the actual
    -- ownership conflict after the engine has published path2.
    if not body.getPath2 or body:getPath2() == nil then
        return false
    end
    liveBodyControl.SuppressZombieState(body, nil, now)
    return true
end

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
    -- In single-player, Behavior2 is advanced from OnZombieUpdate. The
    -- scheduler may start a requested lane, but it must not advance the same
    -- native controller from a second callback.
    if not Internal.IsMultiplayerAuthority() and source ~= "zombie_update" then
        navigation.lastPlanReason = "native_waiting_for_zombie_update"
        return false, "native_waiting_for_zombie_update"
    end
    -- A route has one owner per simulation timestamp. This boundary is shared
    -- by the per-NPC scheduler and the engine update event, so the guard must
    -- live here instead of being duplicated in either caller.
    if tonumber(navigation.lastPumpAt) == now then
        if Diagnostics then
            Diagnostics.RecordPathPump(record, source)
        end
        navigation.duplicatePumpCount =
            (tonumber(navigation.duplicatePumpCount) or 0) + 1
        return false, "native_duplicate_pump_skipped"
    end
    navigation.lastPumpAt = now
    navigation.lastPumpSource = source
    local recovered
    local recoveryState
    recovered, recoveryState = Internal.RecoverStaleNativeBump(
        record,
        body,
        navigation,
        now
    )
    if recovered then
        Internal.InvalidateRecoveredNativeBump(
            record,
            body,
            navigation,
            recoveryState
        )
        local pathService = PNC.PathService
        local pathInternal = pathService and pathService.Internal or nil
        if pathInternal and pathInternal.logMoveWarning then
            pathInternal.logMoveWarning(
                record,
                body,
                record and record.runtime and record.runtime.pathing or nil,
                "native_bump_recovery",
                recoveryState,
                "action=bumped"
            )
        end
        return true, recoveryState
    end
    suppressConflictingNativeState(body, navigation, now)
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
        -- A Behavior2 update can restore WalkTowardState after publishing its
        -- path.  Clear it in the same frame so Java never owns movement in
        -- parallel with path2.  Traversal states are intentionally excluded
        -- by EnsureNativeMovementOwner and remain available for handoff.
        Internal.EnsureNativeMovementOwner(body)
        suppressConflictingNativeState(body, navigation, now)
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
