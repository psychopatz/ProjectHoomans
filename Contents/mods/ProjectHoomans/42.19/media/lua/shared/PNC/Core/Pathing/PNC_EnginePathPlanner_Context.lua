-- Shared engine-path query and request helpers.

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local LiveBodyControl = PNC.LiveBodyControl

Planner.RequestBudget = Planner.RequestBudget or {
    windowStartedAt = 0,
    used = 0,
}
Planner.ActiveServerRoutes = Planner.ActiveServerRoutes or {}

function Internal.GetSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then
        return nil
    end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function squareBuilding(square)
    return square and square.getBuilding and square:getBuilding() or nil
end

local function squareRoom(square)
    return square and square.getRoom and square:getRoom() or nil
end

local function getBodySquare(body)
    if body and body.getSquare then
        local square = body:getSquare()
        if square then return square end
    end
    return body and Internal.GetSquare(
        body:getX(),
        body:getY(),
        body:getZ()
    ) or nil
end

function Internal.EnsureNavigation(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    local navigation = record.runtime.localNavigation
    if not navigation or navigation.provider ~= "engine_path" then
        navigation = {
            provider = "engine_path",
            plannedAt = 0,
            requestStartedAt = 0,
            requestPending = false,
            nativeActive = false,
            planFailures = 0,
        }
        record.runtime.localNavigation = navigation
    end
    navigation.record = record
    return navigation
end

function Internal.GetPathBehavior(body)
    return body and body.getPathFindBehavior2
        and body:getPathFindBehavior2() or nil
end

function Internal.GetNativeTraversalState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(
            body:getActionStateName() or ""
        ))
        or ""
    if state == "climbfence"
        or state == "climbwindow"
        or state == "climbwall"
    then
        return state
    end
    return nil
end

function Internal.IsMultiplayerAuthority()
    return Core
        and Core.IsAuthority
        and Core.IsAuthority()
        and isServer
        and isServer() == true
end

function Internal.SetServerMovementLease(body, navigation, active)
    if not navigation then
        return false
    end
    active = active == true
        and Internal.IsMultiplayerAuthority()
    navigation.serverMovementLease = active
    local record = navigation.record
    if record then
        Planner.ActiveServerRoutes[record] =
            active and navigation or nil
    end
    if LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            not active,
            active
        )
    elseif body and body.setUseless then
        -- Defensive load-order fallback: MP bodies must remain useful even if
        -- the shared body-control module failed to initialize.
        local multiplayer = (isClient and isClient() == true)
            or (isServer and isServer() == true)
        body:setUseless(multiplayer and false or not active)
    end
    return active
end

function Internal.ClearEngineRequest(body, navigation)
    body = body or (navigation and navigation.body)
    local behavior = Internal.GetPathBehavior(body)
    if behavior then
        if behavior.cancel then
            behavior:cancel()
        end
        if behavior.reset then
            behavior:reset()
        end
    end
    if body and body.setPath2 then
        body:setPath2(nil)
    end
    if navigation then
        Internal.SetServerMovementLease(body, navigation, false)
    end
    if navigation then
        navigation.requestPending = false
        navigation.requestStartedAt = 0
        navigation.movingStartedAt = 0
        navigation.lastPumpAt = 0
        navigation.nativeActive = false
        navigation.clientDelegated = false
        navigation.serverMovementLease = false
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
        navigation.nativeTraversalResult = nil
    end
end

function Internal.ConsumeRequestBudget(now)
    local budget = Planner.RequestBudget
    local windowMs = math.max(
        50,
        tonumber(Const.ENGINE_PATH_REQUEST_BUDGET_WINDOW_MS) or 100
    )
    local allowed = math.max(
        1,
        tonumber(Const.ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW) or 1
    )
    if now - (tonumber(budget.windowStartedAt) or 0) >= windowMs then
        budget.windowStartedAt = now
        budget.used = 0
    end
    if (tonumber(budget.used) or 0) >= allowed then
        return false
    end
    budget.used = (tonumber(budget.used) or 0) + 1
    return true
end

function Internal.RouteNeed(record, body, finalTarget)
    local bodyZ = body and body:getZ() or 0
    local finalZ = tonumber(finalTarget and finalTarget.z) or bodyZ
    local fromX = body and body:getX() or 0
    local fromY = body and body:getY() or 0
    local targetX = tonumber(finalTarget and finalTarget.x) or fromX
    local targetY = tonumber(finalTarget and finalTarget.y) or fromY
    local dx = targetX - fromX
    local dy = targetY - fromY
    local distanceSq = (dx * dx) + (dy * dy)
    local stopDistance = math.max(
        0.1,
        tonumber(finalTarget and finalTarget.stopDistance) or 0.7
    )
    if math.floor(bodyZ) ~= math.floor(finalZ) then
        return true, "level_transition"
    end
    if distanceSq <= (stopDistance * stopDistance) then
        return false, "within_stop_distance"
    end
    -- Never fall back to authoritative setX/setY stepping in multiplayer.
    -- Even short corrections belong to the nearest client's native zombie
    -- controller so all peers receive one coherent movement stream.
    if Internal.IsMultiplayerAuthority() then
        return true, "client_native_route"
    end

    local fromSquare = getBodySquare(body)
    local toSquare = Internal.GetSquare(
        finalTarget.x,
        finalTarget.y,
        finalZ
    )
    if fromSquare and toSquare then
        local fromBuilding = squareBuilding(fromSquare)
        local toBuilding = squareBuilding(toSquare)
        if fromBuilding ~= toBuilding then
            return true, "building_transition"
        end
        if fromBuilding ~= nil
            and squareRoom(fromSquare) ~= squareRoom(toSquare)
        then
            return true, "room_transition"
        end
    end

    local lane = record and record.runtime and record.runtime.pathing or nil
    if lane and (
        (tonumber(lane.nonProgressStepCount) or 0) >= 2
        or (tonumber(lane.noProgressCount) or 0) >= 2
        or lane.blockedStepReason ~= nil
        or lane.blockReason == "no_goal_progress"
    ) then
        return true, "movement_stalled"
    end
    local minimumRouteDistance = math.max(
        stopDistance,
        tonumber(Const.ENGINE_PATH_MIN_ROUTE_DISTANCE) or 1.0
    )
    if distanceSq <= (minimumRouteDistance * minimumRouteDistance) then
        return false, "direct_short_adjustment"
    end
    return true, "native_route"
end

function Internal.ResultMatches(result, name)
    if BehaviorResult and BehaviorResult[name] ~= nil then
        return result == BehaviorResult[name]
    end
    local value = tostring(result or "")
    return value == name
        or value == ("BehaviorResult." .. name)
end

return Internal
