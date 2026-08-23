PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Internal = PNC.EnginePathPlanner.Internal
local Const = PNC.Const or {}

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
    if not fromSquare or not toSquare or fromSquare == toSquare then
        return nil
    end
    passage = query.GetPassageBetween
        and query.GetPassageBetween(fromSquare, toSquare)
        or nil
    if passage then
        -- Open doors need no owner; windows remain traversal edges.
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
        fence, tall = query.GetFenceBetween(fromSquare, toSquare)
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

-- Behavior2 has approached the current edge; the body's forward direction
-- identifies the next crossing without inspecting opaque Path userdata.
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
    if not body or not navigation then return nil end
    query = PNC.TraversalQuery
    cell = getCell and getCell() or nil
    if not query or not cell then return nil end
    bodyX = math.floor(body:getX())
    bodyY = math.floor(body:getY())
    bodyZ = math.floor(body:getZ())
    forward = body:getForwardDirection()
    directionX = forward and tonumber(forward:getX()) or 0
    directionY = forward and tonumber(forward:getY()) or 0
    goalX = (tonumber(navigation.requestX) or body:getX()) - body:getX()
    goalY = (tonumber(navigation.requestY) or body:getY()) - body:getY()
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
        and navigation.inspectedBehaviorResult
            == navigation.lastBehaviorResult
    then
        return navigation.upcomingPassage
    end
    navigation.inspectedEdgeX = bodyX
    navigation.inspectedEdgeY = bodyY
    navigation.inspectedEdgeZ = bodyZ
    navigation.inspectedDirectionX = directionKeyX
    navigation.inspectedDirectionY = directionKeyY
    navigation.inspectedRequestRevision = navigation.requestRevision
    navigation.inspectedBehaviorResult = navigation.lastBehaviorResult
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

function Internal.StageUpcomingPathPassage(record, body, navigation)
    local lane = record and record.runtime
        and record.runtime.pathing or nil
    local passage = Internal.GetUpcomingPathPassage(body, navigation)
    local dx
    local dy
    local handoffDistance
    if not lane or not passage then return false end
    dx = body:getX() - ((tonumber(passage.fromX) or 0) + 0.5)
    dy = body:getY() - ((tonumber(passage.fromY) or 0) + 0.5)
    handoffDistance = math.max(
        1.25,
        tonumber(Const.ENGINE_PATH_PASSAGE_HANDOFF_DISTANCE) or 2.0
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

return Internal
