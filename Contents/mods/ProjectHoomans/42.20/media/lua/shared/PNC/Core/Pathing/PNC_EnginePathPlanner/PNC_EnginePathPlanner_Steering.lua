-- Steering-target planning and bounded native-route replanning.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

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
    local lane = record.runtime and record.runtime.pathing or nil
    local nativeBackoffUntil = tonumber(
        lane and lane.nativeBackoffUntil
    ) or 0
    if nativeBackoffUntil > now then
        navigation.lastPlanReason = "native_stall_backoff"
        navigation.steeringKind = "final_native_deferred"
        return finalTarget
    end
    if lane and lane.ownerMode == "native_backoff" then
        lane.ownerMode = "engine_path_waiting"
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
        ) ~= math.floor(tonumber(finalTarget.z) or body:getZ())
        local targetMoved = targetDriftSquared(
            navigation,
            finalTarget
        ) >= (replanDistance * replanDistance)
        if (levelChanged or targetMoved)
            and now - (tonumber(navigation.plannedAt) or 0) >= replanMs
        then
            if Internal.IsMultiplayerAuthority()
                or Internal.ConsumeRequestBudget(now)
            then
                if Diagnostics then Diagnostics.Increment("Pathing.Replans") end
                Internal.BeginRequest(
                    body,
                    finalTarget,
                    navigation,
                    now,
                    levelChanged
                        and "moving_target_level_replan"
                        or "moving_target_replan"
                )
            else
                navigation.lastPlanReason = "native_replan_budget_deferred"
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
    lane = record.runtime and record.runtime.pathing or nil
    if not lane or lane.phase ~= "active" then
        navigation.lastPlanReason = "native_waiting_for_move_lane"
        navigation.steeringKind = "final_native_deferred"
        return finalTarget
    end
    local retryDelayMs = replanMs * math.max(
        1,
        math.min(4, 1 + (tonumber(navigation.planFailures) or 0))
    )
    if (tonumber(navigation.plannedAt) or 0) > 0
        and now - (tonumber(navigation.plannedAt) or 0) < retryDelayMs
    then
        navigation.lastPlanReason = "native_replan_cooldown"
        navigation.steeringKind = "final_native_deferred"
        return finalTarget
    end
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
    Internal.BeginRequest(body, finalTarget, navigation, now, reason)
    return finalTarget
end
