--[[
    Unified native movement ownership based on Bandits' proven split:
    single-player directly advances PathFindBehavior2 (Move), while dedicated
    multiplayer publishes a goal for the nearest client character wrapper
    (GoTo). Scripted traversal owns passages the zombie pathfinder cannot
    safely enter. Embodied movement never falls back to setX/setY stepping.
]]

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Planner.CanUseNativePath(body)
    if not body then
        return false, "native_path_unavailable"
    end
    -- Dedicated authority publishes the destination without entering a local
    -- Java movement state. Preserve that transport path for the owning client.
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

local function targetDriftSquared(navigation, finalTarget)
    local requestX = tonumber(navigation and navigation.requestX)
    local requestY = tonumber(navigation and navigation.requestY)
    local targetX = tonumber(finalTarget and finalTarget.x)
    local targetY = tonumber(finalTarget and finalTarget.y)
    if requestX == nil or requestY == nil
        or targetX == nil or targetY == nil
    then
        return 0
    end
    local dx = targetX - requestX
    local dy = targetY - requestY
    return (dx * dx) + (dy * dy)
end

local function handoffUpcomingPassage(record, body, navigation)
    local handled
    local state
    if not Internal.StageUpcomingPathPassage
        or not Internal.StageUpcomingPathPassage(
            record,
            body,
            navigation
        )
    then
        return false, nil
    end
    -- Stop Behavior2 before its next update can queue one of the vanilla
    -- climb states. Those states dereference BodyDamage during enter(), so an
    -- exception there would prevent any post-update recovery from running.
    Internal.ClearEngineRequest(body, navigation)
    if PNC.PathService and PNC.PathService.Pump then
        handled, state = PNC.PathService.Pump(
            record,
            body,
            "engine_passage_handoff"
        )
        return true, state or (handled
            and "native_passage_handoff"
            or "native_passage_waiting")
    end
    return true, "native_passage_waiting"
end

local function beginRequest(body, finalTarget, navigation, now, reason)
    local multiplayerAuthority =
        Internal.IsMultiplayerAuthority()
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
    if Diagnostics then
        Diagnostics.Increment("Pathing.EnginePathRequests")
    end
    local x = tonumber(finalTarget.x) or body:getX()
    local y = tonumber(finalTarget.y) or body:getY()
    local z = tonumber(finalTarget.z) or body:getZ()
    -- Bandits' SP Move action submits and updates PathFindBehavior2 directly.
    -- This avoids PathFindState selecting ClimbOverFenceState, whose B42
    -- implementation assumes a BodyDamage object that humanized zombies lack.
    -- Dedicated MP remains goal-only; the nearest client owns its GoTo call.
    if not multiplayerAuthority then
        local behavior = Internal.GetPathBehavior(body)
        behavior:pathToLocation(x, y, z)
    end
    navigation.requestPending = true
    navigation.nativeActive = true
    navigation.controllerMode = multiplayerAuthority
        and "client_goto" or "behavior2_move"
    navigation.lastBehaviorResult = nil
    navigation.lastBehaviorUpdateAt = multiplayerAuthority
        and 0 or now
    navigation.clientDelegated =
        multiplayerAuthority == true
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
        local handedOff = handoffUpcomingPassage(
            navigation.record,
            body,
            navigation
        )
        if handedOff then
            return true
        end
    end
    return true
end

function Planner.GetSteeringTarget(record, body, finalTarget)
    if not record or not body or type(finalTarget) ~= "table" then
        return finalTarget
    end
    local navigation = Internal.EnsureNavigation(record)
    navigation.body = body
    local now = Core and Core.Now and Core.Now() or 0
    local nativeSafe
    local unsafeReason
    nativeSafe, unsafeReason = Planner.CanUseNativePath(body)
    if not nativeSafe then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = unsafeReason
        navigation.plannedAt = now
        navigation.steeringKind = "native_unavailable"
        return finalTarget
    end
    local replanMs = math.max(
        250,
        tonumber(Const.ENGINE_PATH_REPLAN_MS) or 1000
    )
    if navigation.nativeActive then
        local stillNeeded
        local routeReason
        stillNeeded, routeReason = Internal.RouteNeed(
            record,
            body,
            finalTarget
        )
        if not stillNeeded then
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason = routeReason
            navigation.steeringKind = "final_direct"
            return finalTarget
        end
        local replanDistance = math.max(
            0.5,
            tonumber(Const.ENGINE_PATH_TARGET_REPLAN_DISTANCE) or 1.5
        )
        local levelChanged = math.floor(
            tonumber(navigation.requestZ) or body:getZ()
        ) ~= math.floor(
            tonumber(finalTarget.z) or body:getZ()
        )
        local targetMoved = targetDriftSquared(
            navigation,
            finalTarget
        ) >= (replanDistance * replanDistance)
        if (levelChanged or targetMoved)
            and now - (tonumber(navigation.plannedAt) or 0) >= replanMs
        then
            -- Multiplayer replans only publish a destination for the nearest
            -- client; they do not run A* on the dedicated server. The SP
            -- request budget must not expose the old fake-movement fallback.
            if Internal.IsMultiplayerAuthority()
                or Internal.ConsumeRequestBudget(now)
            then
                if Diagnostics then
                    Diagnostics.Increment("Pathing.Replans")
                end
                beginRequest(
                    body,
                    finalTarget,
                    navigation,
                    now,
                    levelChanged
                        and "moving_target_level_replan"
                        or "moving_target_replan"
                )
            else
                navigation.lastPlanReason =
                    "native_replan_budget_deferred"
                navigation.deferredPlans =
                    (tonumber(navigation.deferredPlans) or 0) + 1
            end
        end
        navigation.steeringKind = navigation.controllerMode
            == "behavior2_move"
            and "engine_native_behavior2"
            or "engine_native_client"
        return finalTarget
    end

    local needed, reason = Internal.RouteNeed(record, body, finalTarget)
    if not needed then
        navigation.lastPlanReason = reason
        navigation.steeringKind = "final_direct"
        return finalTarget
    end

    -- Wait until PathService has committed the movement lane so a behavior
    -- change cannot cancel a native request later in the same authority tick.
    local lane = record.runtime and record.runtime.pathing or nil
    if not lane or lane.phase ~= "active" then
        navigation.lastPlanReason = "native_waiting_for_move_lane"
        navigation.steeringKind = "final_native_deferred"
        return finalTarget
    end

    local retryDelayMs = replanMs * math.max(
        1,
        math.min(
            4,
            1 + (tonumber(navigation.planFailures) or 0)
        )
    )
    if (tonumber(navigation.plannedAt) or 0) > 0
        and now - (tonumber(navigation.plannedAt) or 0)
            < retryDelayMs
    then
        navigation.lastPlanReason = "native_replan_cooldown"
        navigation.steeringKind = "final_native_deferred"
        return finalTarget
    end
    -- Dedicated MP authority only publishes the goal. The controlling client
    -- incurs the native pathfinding cost, so never leave an MP lane without
    -- its native owner because the SP request budget was exhausted.
    if not Internal.IsMultiplayerAuthority()
        and not Internal.ConsumeRequestBudget(now)
    then
        navigation.lastPlanReason = "native_budget_deferred"
        navigation.steeringKind = "final_native_deferred"
        navigation.deferredPlans =
            (tonumber(navigation.deferredPlans) or 0) + 1
        return finalTarget
    end

    if Diagnostics and (tonumber(navigation.planFailures) or 0) > 0 then
        Diagnostics.Increment("Pathing.Retries")
    end
    beginRequest(body, finalTarget, navigation, now, reason)
    return finalTarget
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
    if Diagnostics then
        Diagnostics.RecordPathPump(record, source)
        if record
            and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
        then
            Diagnostics.Increment(
                "LiveAbstract.AbstractPhysicalTraversal"
            )
        end
    end
    if navigation.clientDelegated == true
        and Internal.IsMultiplayerAuthority()
    then
        local traversalState =
            Internal.GetNativeTraversalState(body)
        navigation.lastPumpAt = now
        navigation.requestPending = false
        navigation.nativeTraversalState = traversalState
        navigation.lastPlanReason = traversalState
            and ("client_native_" .. traversalState)
            or "client_native_moving"
        navigation.steeringKind = "engine_native_client"
        Internal.SetServerMovementLease(
            body,
            navigation,
            true
        )
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

    -- Match Bandits Move.onWorking: the zombie update event is the sole
    -- PathFindBehavior2 update owner. The scheduled path pump may observe,
    -- interact with passages, and publish state, but never advances A* a
    -- second time in the same frame.
    if navigation.controllerMode == "behavior2_move"
        and source == "zombie_update"
        and (tonumber(navigation.lastBehaviorUpdateAt) or 0) ~= now
    then
        -- Inspect the already-built route before advancing Java. This is the
        -- critical fence/window interception point: doing it only afterward
        -- is too late when ClimbOverFenceState.enter() itself throws.
        local handedOff
        local handoffResult
        handedOff, handoffResult = handoffUpcomingPassage(
            record,
            body,
            navigation
        )
        if handedOff then
            return true, handoffResult
        end
        if Diagnostics then
            Diagnostics.RecordLogicalAdvance(
                record,
                "engine_behavior2"
            )
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
        handedOff, handoffResult = handoffUpcomingPassage(
            record,
            body,
            navigation
        )
        if handedOff then
            return true, handoffResult
        end
    end

    local traversalState =
        Internal.GetNativeTraversalState(body)
    if traversalState ~= nil
        and navigation.controllerMode == "behavior2_move"
    then
        -- A humanized IsoZombie has no BodyDamage. Native fence/window states
        -- dereference it during enter/execute, so never retain an escaped
        -- state as a legitimate physical traversal owner in single-player.
        Internal.ClearEngineRequest(body, navigation)
        if PNC.LiveBodyControl
            and PNC.LiveBodyControl.SuppressZombieState
        then
            PNC.LiveBodyControl.SuppressZombieState(body, nil, now)
        end
        navigation.lastPlanReason = "unsafe_native_traversal"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        if Diagnostics then
            Diagnostics.Increment(
                "Pathing.UnsafeNativeTraversalEscapes"
            )
        end
        return true, "engine_path_failed"
    end
    if navigation.nativeTraversalState ~= nil then
        if traversalState ~= nil then
            local traversalTimeoutMs = math.max(
                1000,
                tonumber(
                    Const.ENGINE_PATH_TRAVERSAL_TIMEOUT_MS
                ) or 3000
            )
            if now - (
                tonumber(
                    navigation.nativeTraversalStartedAt
                ) or now
            ) < traversalTimeoutMs
            then
                navigation.nativeTraversalState =
                    traversalState
                navigation.lastPlanReason =
                    "native_traversal_" .. traversalState
                Internal.SetServerMovementLease(
                    body,
                    navigation,
                    true
                )
                return true, navigation.lastPlanReason
            end
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason =
                "native_traversal_timeout"
            navigation.planFailures =
                (tonumber(navigation.planFailures) or 0) + 1
            if Diagnostics then
                Diagnostics.Increment("Pathing.Timeouts")
            end
            return true, "engine_path_failed"
        end
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
    end

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
        if Diagnostics then
            Diagnostics.Increment("Pathing.Timeouts")
        end
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
        )
            >= routeTimeoutMs
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_route_timeout"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        if Diagnostics then
            Diagnostics.Increment("Pathing.Timeouts")
        end
        return true, "engine_path_timeout"
    end

    traversalState = Internal.GetNativeTraversalState(body)
    if traversalState ~= nil then
        navigation.nativeTraversalState = traversalState
        navigation.nativeTraversalStartedAt =
            (tonumber(
                navigation.nativeTraversalStartedAt
            ) or 0) > 0
                and navigation.nativeTraversalStartedAt
                or now
        navigation.requestPending = false
        navigation.lastPlanReason =
            "native_traversal_" .. traversalState
        navigation.steeringKind = "engine_native"
        Internal.SetServerMovementLease(
            body,
            navigation,
            true
        )
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

function Planner.PumpFrame(record, body)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "client_replica"
    end
    local lane = record and record.runtime
        and record.runtime.pathing or nil
    if not lane or lane.phase ~= "active" then
        return false, "move_lane_inactive"
    end
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if (lane.traversalAction or lane.blockedStepToX ~= nil)
        and PNC.PathService
        and PNC.PathService.Pump
    then
        -- The ordinary scheduler is intentionally throttled; advance the
        -- short scripted crossing on zombie frames for smooth motion and keep
        -- Behavior2 dormant until the action has completely released.
        return PNC.PathService.Pump(
            record,
            body,
            "zombie_update_path_service"
        )
    end
    if navigation
        and navigation.controllerMode == "behavior2_move"
        and Internal.IsBodyCollided
        and Internal.IsBodyCollided(body)
    then
        -- Do not run Behavior2 again at contact. Let the path service cancel
        -- native ownership and begin its BodyDamage-safe scripted passage on
        -- this same zombie-update frame.
        if PNC.PathService and PNC.PathService.Pump then
            return PNC.PathService.Pump(
                record,
                body,
                "zombie_update_collision"
            )
        end
        return true, "native_collision_waiting"
    end
    return Planner.Pump(record, body, "zombie_update")
end

function Planner.PumpServerFrame()
    if not Internal.IsMultiplayerAuthority() then
        return 0
    end
    local pumped = 0
    for record, navigation in pairs(Planner.ActiveServerRoutes) do
        local lane = record and record.runtime
            and record.runtime.pathing or nil
        local body = navigation and navigation.body or nil
        if PNC.Registry
            and PNC.Registry.GetLiveZombie
            and record
            and record.id
        then
            local liveBody = PNC.Registry.GetLiveZombie(record.id)
            if liveBody ~= body then
                body = nil
            end
        end
        if navigation
            and navigation.nativeActive == true
            and navigation.serverMovementLease == true
            and lane
            and lane.phase == "active"
            and body
        then
            Planner.Pump(record, body, "server_tick")
            pumped = pumped + 1
        else
            Internal.ClearEngineRequest(
                body,
                navigation
            )
        end
    end
    return pumped
end

function Planner.Clear(record, body)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if navigation and navigation.provider == "engine_path" then
        Internal.ClearEngineRequest(body or navigation.body, navigation)
    end
    if record and record.runtime then
        record.runtime.localNavigation = nil
    end
end

function Planner.Invalidate(record, reason, body)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if not navigation or navigation.provider ~= "engine_path" then
        return false
    end
    Internal.ClearEngineRequest(body or navigation.body, navigation)
    navigation.plannedAt = 0
    navigation.lastPlanReason = reason or "invalidated"
    return true
end

return Planner
