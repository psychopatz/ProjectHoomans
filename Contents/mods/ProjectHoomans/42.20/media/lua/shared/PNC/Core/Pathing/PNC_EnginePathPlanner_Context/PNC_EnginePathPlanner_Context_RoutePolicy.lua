PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Const = PNC.Const or {}

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
    if (tonumber(budget.used) or 0) >= allowed then return false end
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
    return true, "native_route"
end

return Internal
