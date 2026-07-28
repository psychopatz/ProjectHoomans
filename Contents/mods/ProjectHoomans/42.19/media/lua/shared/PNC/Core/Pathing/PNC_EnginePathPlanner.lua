--[[
    Uses Project Zomboid's native PathFindBehavior2 for the short, complicated
    routes that fake locomotion cannot solve reliably and for meaningful
    movement. Fake locomotion remains the fallback for sub-tile corrections,
    unavailable native routes, and committed attack animation leases.
]]

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}

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

local function beginRequest(body, finalTarget, navigation, now, reason)
    local multiplayerAuthority =
        Internal.IsMultiplayerAuthority()
    local behavior = not multiplayerAuthority
        and Internal.GetPathBehavior(body) or nil
    if not multiplayerAuthority and not behavior then
        navigation.lastPlanReason = "native_path_unavailable"
        navigation.plannedAt = now
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return false
    end

    Internal.ClearEngineRequest(body, navigation)
    local x = tonumber(finalTarget.x) or body:getX()
    local y = tonumber(finalTarget.y) or body:getY()
    local z = tonumber(finalTarget.z) or body:getZ()
    if not multiplayerAuthority and (
        not behavior.update
        or (not behavior.pathToLocationF and not behavior.pathToLocation)
    ) then
        navigation.lastPlanReason = "native_path_api_unavailable"
        navigation.plannedAt = now
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return false
    end
    -- Build 42 assigns multiplayer zombie simulation to a client. Bandits
    -- follows that ownership and updates PathFindBehavior2 only on the nearest
    -- client. The dedicated server publishes the goal and observes the
    -- replicated body; it must not create a second native path controller.
    if not multiplayerAuthority and behavior.pathToLocationF then
        behavior:pathToLocationF(x, y, z)
    elseif not multiplayerAuthority then
        behavior:pathToLocation(
            math.floor(x),
            math.floor(y),
            math.floor(z)
        )
    end
    navigation.requestPending = true
    navigation.nativeActive = true
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
    navigation.lastPlanReason = reason or "native_request"
    navigation.steeringKind = "engine_native"
    Internal.SetServerMovementLease(body, navigation, true)
    return true
end

function Planner.GetSteeringTarget(record, body, finalTarget)
    if not record or not body or type(finalTarget) ~= "table" then
        return finalTarget
    end
    local navigation = Internal.EnsureNavigation(record)
    navigation.body = body
    local now = Core and Core.Now and Core.Now() or 0
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
        navigation.steeringKind = "engine_native"
        return finalTarget
    end

    local needed, reason = Internal.RouteNeed(record, body, finalTarget)
    if not needed then
        navigation.lastPlanReason = reason
        navigation.steeringKind = "final_direct"
        return finalTarget
    end

    -- Starting a fresh fake-locomotion lane deliberately resets every native
    -- path controller. Wait until that lane is active so this asynchronous
    -- request cannot be cancelled later in the same authority tick.
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

    beginRequest(body, finalTarget, navigation, now, reason)
    return finalTarget
end

local function setNativeUpdateWindow(body, enabled, previousUseless)
    if not body or not body.setUseless then
        return
    end
    if enabled then
        body:setUseless(false)
    else
        body:setUseless(previousUseless == true)
    end
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
    if not behavior or not behavior.update then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_path_api_unavailable"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return true, "engine_path_failed"
    end

    local lastPumpAt = tonumber(navigation.lastPumpAt) or 0
    if lastPumpAt > 0 and now - lastPumpAt < 15
    then
        return true, navigation.lastPlanReason
            or "native_frame_owned"
    end
    local traversalState =
        Internal.GetNativeTraversalState(body)
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
            return true, "engine_path_failed"
        end
        -- The engine traversal action has finished.  If update() had already
        -- reported a terminal result, consume it now; otherwise resume the
        -- same native route after the climb/window state releases.
        local traversalResult =
            navigation.nativeTraversalResult
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
        navigation.nativeTraversalResult = nil
        if traversalResult == "Succeeded" then
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason =
                "native_path_succeeded"
            navigation.planFailures = 0
            navigation.completedAt = now
            return true, "engine_path_succeeded"
        elseif traversalResult == "Failed" then
            Internal.ClearEngineRequest(body, navigation)
            navigation.lastPlanReason =
                "native_path_failed"
            navigation.planFailures =
                (tonumber(navigation.planFailures) or 0) + 1
            return true, "engine_path_failed"
        end
    end
    local requestTimeoutMs = math.max(
        500,
        tonumber(Const.ENGINE_PATH_REQUEST_TIMEOUT_MS) or 2500
    )
    local hasPath = body and body.getPath2 and body:getPath2() ~= nil
    if not hasPath
        and now - (tonumber(navigation.requestStartedAt) or now)
            >= requestTimeoutMs
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_request_timeout"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return true, "engine_path_timeout"
    end
    if hasPath and (tonumber(navigation.movingStartedAt) or 0) <= 0 then
        navigation.movingStartedAt = now
    end
    local routeTimeoutMs = math.max(
        requestTimeoutMs,
        tonumber(Const.ENGINE_PATH_ROUTE_TIMEOUT_MS) or 15000
    )
    if hasPath
        and now - (tonumber(navigation.movingStartedAt) or now)
            >= routeTimeoutMs
    then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_route_timeout"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return true, "engine_path_timeout"
    end

    local previousUseless = true
    if body.isUseless then
        previousUseless = body:isUseless() == true
    end
    setNativeUpdateWindow(body, true, previousUseless)
    local result = behavior:update()
    setNativeUpdateWindow(body, false, previousUseless)
    navigation.lastPumpAt = now
    traversalState = Internal.GetNativeTraversalState(body)
    if traversalState ~= nil then
        navigation.nativeTraversalState = traversalState
        navigation.nativeTraversalStartedAt =
            (tonumber(
                navigation.nativeTraversalStartedAt
            ) or 0) > 0
                and navigation.nativeTraversalStartedAt
                or now
        if Internal.ResultMatches(result, "Succeeded") then
            navigation.nativeTraversalResult = "Succeeded"
        elseif Internal.ResultMatches(result, "Failed") then
            navigation.nativeTraversalResult = "Failed"
        end
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
    if Internal.ResultMatches(result, "Failed") then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_path_failed"
        navigation.planFailures =
            (tonumber(navigation.planFailures) or 0) + 1
        return true, "engine_path_failed"
    end
    if Internal.ResultMatches(result, "Succeeded") then
        Internal.ClearEngineRequest(body, navigation)
        navigation.lastPlanReason = "native_path_succeeded"
        navigation.planFailures = 0
        navigation.completedAt = now
        return true, "engine_path_succeeded"
    end

    navigation.requestPending = not hasPath
    navigation.lastPlanReason = navigation.requestPending
        and "native_path_pending" or "native_path_moving"
    navigation.steeringKind = "engine_native"
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
