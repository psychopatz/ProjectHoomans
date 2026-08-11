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

local function cachePathPassage(
    navigation,
    fromSquare,
    toSquare,
    object,
    kind
)
    navigation.upcomingPassage = {
        fromX = fromSquare:getX(),
        fromY = fromSquare:getY(),
        fromZ = fromSquare:getZ(),
        toX = toSquare:getX(),
        toY = toSquare:getY(),
        toZ = toSquare:getZ(),
        object = object,
        kind = kind,
    }
    return navigation.upcomingPassage
end

local function inspectSquareEdge(
    navigation,
    query,
    fromSquare,
    toSquare
)
    local passage
    local fence
    local tall
    if not fromSquare or not toSquare
        or fromSquare == toSquare
    then
        return nil
    end
    passage = query.GetPassageBetween
        and query.GetPassageBetween(fromSquare, toSquare)
        or nil
    if passage then
        -- An open door needs no special owner. Open/smashed windows remain a
        -- traversal edge and must still transfer into the scripted climb.
        if not (
            query.IsDoor
            and query.IsDoor(passage)
            and query.IsClosedPassage
            and not query.IsClosedPassage(passage)
        ) then
            return cachePathPassage(
                navigation,
                fromSquare,
                toSquare,
                passage,
                query.IsWindow and query.IsWindow(passage)
                    and "window" or "door"
            )
        end
    end
    if query.GetFenceBetween then
        fence, tall = query.GetFenceBetween(
            fromSquare,
            toSquare
        )
        if fence then
            return cachePathPassage(
                navigation,
                fromSquare,
                toSquare,
                fence,
                tall == true and "fence_tall" or "fence"
            )
        end
    end
    return nil
end

-- zombie.pathfind.Path is not exposed to Kahlua beyond being returned as an
-- opaque userdata value: both field probes and method calls throw. Intercept
-- only the current cardinal edge instead. Behavior2 has already approached
-- that edge, and the body's forward direction identifies its next crossing.
function Internal.GetUpcomingPathPassage(body, navigation)
    local query
    local cell
    local bodyX
    local bodyY
    local bodyZ
    local fromSquare
    local forward
    local directionX
    local directionY
    local goalX
    local goalY
    local primaryX
    local primaryY
    local secondaryX
    local secondaryY
    local directionKeyX
    local directionKeyY
    local candidates
    local candidate
    local toX
    local toY
    local toSquare
    local passage
    local i
    if not body or not navigation then
        return nil
    end
    query = PNC.TraversalQuery
    cell = getCell and getCell() or nil
    if not query or not cell then
        return nil
    end
    bodyX = math.floor(body:getX())
    bodyY = math.floor(body:getY())
    bodyZ = math.floor(body:getZ())
    forward = body:getForwardDirection()
    directionX = forward and tonumber(forward:getX()) or 0
    directionY = forward and tonumber(forward:getY()) or 0
    goalX = (tonumber(navigation.requestX) or body:getX())
        - body:getX()
    goalY = (tonumber(navigation.requestY) or body:getY())
        - body:getY()
    -- A newly submitted Behavior2 route may not have authored its forward
    -- vector yet. The destination is a safe initial direction fallback.
    if navigation.lastBehaviorResult == nil
        or math.abs(directionX) + math.abs(directionY) < 0.05
    then
        directionX = goalX
        directionY = goalY
    end
    directionKeyX = directionX > 0.05 and 1
        or (directionX < -0.05 and -1 or 0)
    directionKeyY = directionY > 0.05 and 1
        or (directionY < -0.05 and -1 or 0)
    if directionKeyX == 0 and directionKeyY == 0 then
        navigation.upcomingPassage = nil
        return nil
    end
    if navigation.inspectedEdgeX == bodyX
        and navigation.inspectedEdgeY == bodyY
        and navigation.inspectedEdgeZ == bodyZ
        and navigation.inspectedDirectionX == directionKeyX
        and navigation.inspectedDirectionY == directionKeyY
        and navigation.inspectedRequestRevision
            == navigation.requestRevision
    then
        return navigation.upcomingPassage
    end
    navigation.inspectedEdgeX = bodyX
    navigation.inspectedEdgeY = bodyY
    navigation.inspectedEdgeZ = bodyZ
    navigation.inspectedDirectionX = directionKeyX
    navigation.inspectedDirectionY = directionKeyY
    navigation.inspectedRequestRevision = navigation.requestRevision
    navigation.upcomingPassage = nil
    if math.abs(directionX) >= math.abs(directionY) then
        primaryX, primaryY = directionKeyX, 0
        secondaryX, secondaryY = 0, directionKeyY
    else
        primaryX, primaryY = 0, directionKeyY
        secondaryX, secondaryY = directionKeyX, 0
    end
    candidates = {
        { primaryX, primaryY },
        { secondaryX, secondaryY },
    }
    fromSquare = cell:getGridSquare(bodyX, bodyY, bodyZ)
    if not fromSquare then return nil end
    for i = 1, #candidates do
        candidate = candidates[i]
        if candidate[1] ~= 0 or candidate[2] ~= 0 then
            toX = bodyX + candidate[1]
            toY = bodyY + candidate[2]
            toSquare = cell:getGridSquare(toX, toY, bodyZ)
            passage = inspectSquareEdge(
                navigation,
                query,
                fromSquare,
                toSquare
            )
            if passage then return passage end
        end
    end
    return nil
end

function Internal.StageUpcomingPathPassage(
    record,
    body,
    navigation
)
    local lane = record and record.runtime
        and record.runtime.pathing or nil
    local passage = Internal.GetUpcomingPathPassage(
        body,
        navigation
    )
    local dx
    local dy
    local handoffDistance
    if not lane or not passage then return false end
    dx = body:getX() - ((tonumber(passage.fromX) or 0) + 0.5)
    dy = body:getY() - ((tonumber(passage.fromY) or 0) + 0.5)
    handoffDistance = math.max(
        1.25,
        tonumber(Const.ENGINE_PATH_PASSAGE_HANDOFF_DISTANCE)
            or 2.0
    )
    if (dx * dx) + (dy * dy)
        > handoffDistance * handoffDistance
    then
        return false
    end
    lane.blockedStepFromX = passage.fromX + 0.5
    lane.blockedStepFromY = passage.fromY + 0.5
    lane.blockedStepFromZ = passage.fromZ
    lane.blockedStepToX = passage.toX + 0.5
    lane.blockedStepToY = passage.toY + 0.5
    lane.blockedStepToZ = passage.toZ
    lane.blockedStepReason =
        "native_path_" .. tostring(passage.kind or "passage")
    return true
end

-- Match ZAMove.onWorking's collision gate. A manual Behavior2 owner must not
-- advance another frame after contact; PathService gets that frame to adopt
-- the door/window/fence into its safe scripted traversal lane.
function Internal.IsBodyCollided(body)
    if not body then return false end
    local collidedWithDoor = body.isCollidedWithDoor
    if type(collidedWithDoor) == "function"
        and collidedWithDoor(body) == true
    then
        return true
    end
    local collidedThisFrame = body.isCollidedThisFrame
    if type(collidedThisFrame) == "function"
        and collidedThisFrame(body) == true
    then
        return true
    end
    local collided = body.isCollided
    return type(collided) == "function"
        and collided(body) == true
        or collided == true
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

function Internal.GetNativeMovementState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(
            body:getActionStateName() or ""
        ))
        or ""
    if state == "pathfind" then
        return state
    end
    return Internal.GetNativeTraversalState(body)
end

function Internal.IsAtRequestGoal(body, navigation)
    if not body or not navigation then return false end
    local requestZ = tonumber(navigation.requestZ) or body:getZ()
    if math.abs(body:getZ() - requestZ) >= 0.5 then
        return false
    end
    local dx = (tonumber(navigation.requestX) or body:getX())
        - body:getX()
    local dy = (tonumber(navigation.requestY) or body:getY())
        - body:getY()
    local stopDistance = math.max(
        0.1,
        tonumber(navigation.requestStopDistance) or 0.7
    )
    return (dx * dx) + (dy * dy)
        <= stopDistance * stopDistance
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
    local movementActive = active == true
    local serverLease = movementActive
        and Internal.IsMultiplayerAuthority()
    -- Bandits' ownership split is intentionally asymmetric. In single-player
    -- its Move action advances PathFindBehavior2 itself while the IsoZombie
    -- remains useless. Making that body useful lets IsoZombie.update() also
    -- consume path2, which races the manual controller into WalkTowardState
    -- and unsafe vanilla fence states. Dedicated MP is the opposite: the
    -- controlling client needs a useful body for its GoTo/PathFindState.
    local keepEngineMovementActive = serverLease == true
    navigation.serverMovementLease = serverLease
    local record = navigation.record
    if record then
        Planner.ActiveServerRoutes[record] =
            serverLease and navigation or nil
    end
    if LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            not keepEngineMovementActive,
            keepEngineMovementActive
        )
    elseif body and body.setUseless then
        -- Defensive load-order fallback: MP bodies must remain useful even if
        -- the shared body-control module failed to initialize.
        body:setUseless(not keepEngineMovementActive)
    end
    return serverLease
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
    local actionState = body and body.getActionStateName
        and string.lower(tostring(
            body:getActionStateName() or ""
        ))
        or ""
    if actionState == "pathfind"
        and body.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        body:changeState(ZombieIdleState.instance())
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
        navigation.controllerMode = nil
        navigation.lastBehaviorResult = nil
        navigation.lastBehaviorUpdateAt = 0
        navigation.clientDelegated = false
        navigation.serverMovementLease = false
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
        navigation.nativeTraversalResult = nil
        navigation.inspectedEdgeX = nil
        navigation.inspectedEdgeY = nil
        navigation.inspectedEdgeZ = nil
        navigation.inspectedDirectionX = nil
        navigation.inspectedDirectionY = nil
        navigation.inspectedRequestRevision = nil
        navigation.upcomingPassage = nil
        navigation.lastObservedX = nil
        navigation.lastObservedY = nil
        navigation.lastObservedZ = nil
        navigation.lastPhysicalProgressAt = 0
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
    -- Every embodied correction belongs to a native controller. Bandits uses
    -- PathFindBehavior2 directly in single-player and delegates the character
    -- wrapper in multiplayer; neither mode needs authoritative setX/setY
    -- stepping once the body is outside its stop radius.
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

function Internal.ResultMatches(result, name)
    if BehaviorResult and BehaviorResult[name] ~= nil then
        return result == BehaviorResult[name]
    end
    local value = tostring(result or "")
    return value == name
        or value == ("BehaviorResult." .. name)
end

return Internal
