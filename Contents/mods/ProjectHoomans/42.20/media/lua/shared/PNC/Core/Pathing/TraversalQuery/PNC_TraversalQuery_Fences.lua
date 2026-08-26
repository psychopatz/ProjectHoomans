-- Fence-edge geometry and crossing lookup.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal

local FENCE_LANDING_MARGIN = 0.05

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function TraversalQuery.GetFenceTransferPoint(
    fromSquare,
    toSquare,
    x,
    y
)
    local dx
    local dy
    local startX = tonumber(x)
    local startY = tonumber(y)
    local targetX
    local targetY
    local minimumX
    local maximumX
    local minimumY
    local maximumY
    if not fromSquare or not toSquare
        or not startX or not startY
    then
        return nil, nil
    end
    dx, dy = Internal.CardinalDelta(fromSquare, toSquare)
    if not dx then
        return nil, nil
    end
    -- Move exactly one cardinal tile, preserving the coordinate parallel to
    -- the fence. Target-square centers are not valid transfer points: they
    -- introduce a sideways turn whenever the actor approaches off-center.
    targetX = startX + dx
    targetY = startY + dy
    minimumX = toSquare:getX() + FENCE_LANDING_MARGIN
    maximumX = toSquare:getX() + 1 - FENCE_LANDING_MARGIN
    minimumY = toSquare:getY() + FENCE_LANDING_MARGIN
    maximumY = toSquare:getY() + 1 - FENCE_LANDING_MARGIN
    return clamp(targetX, minimumX, maximumX),
        clamp(targetY, minimumY, maximumY)
end

function TraversalQuery.IsFenceApproachReady(
    x,
    y,
    fromSquare,
    toSquare,
    dirX,
    dirY
)
    local dx
    local dy
    local distanceToEdge
    local edgeX
    local edgeY
    local length
    if not fromSquare or not toSquare then
        return false
    end
    dx, dy = Internal.CardinalDelta(fromSquare, toSquare)
    if not dx then
        return false
    end
    if math.floor(tonumber(x) or -math.huge) ~= fromSquare:getX()
        or math.floor(tonumber(y) or -math.huge) ~= fromSquare:getY()
    then
        return false
    end
    edgeX = math.max(fromSquare:getX(), toSquare:getX())
    edgeY = math.max(fromSquare:getY(), toSquare:getY())
    if dx ~= 0 then
        distanceToEdge = math.abs((tonumber(x) or 0) - edgeX)
    else
        distanceToEdge = math.abs((tonumber(y) or 0) - edgeY)
    end
    -- The Java fence state is entered from the current square and advances
    -- over one adjacent edge. Do not select an edge while the actor is still
    -- deep in that square; this is what caused distant/sideways false hops.
    if distanceToEdge > 0.72 then
        return false
    end
    if dirX ~= nil or dirY ~= nil then
        length = math.sqrt(
            (tonumber(dirX) or 0) * (tonumber(dirX) or 0)
                + (tonumber(dirY) or 0) * (tonumber(dirY) or 0)
        )
        if length <= 0.001
            or ((dx * (tonumber(dirX) or 0))
                + (dy * (tonumber(dirY) or 0))) <= 0.05 * length
        then
            return false
        end
    end
    return true
end

function TraversalQuery.IsFenceCrossed(x, y, z, fromSquare, toSquare)
    local dx
    local dy
    if not fromSquare or not toSquare then
        return false
    end
    dx, dy = Internal.CardinalDelta(fromSquare, toSquare)
    if not dx then
        return false
    end
    return math.floor(tonumber(x) or -math.huge) == toSquare:getX()
        and math.floor(tonumber(y) or -math.huge) == toSquare:getY()
        and math.floor(tonumber(z) or -math.huge) == toSquare:getZ()
end

function TraversalQuery.GetFenceBetween(fromSquare, toSquare)
    local fromX
    local fromY
    local toX
    local toY
    local northEdge
    local squares
    local square
    local object
    local isFence
    local isTall
    local i
    if not fromSquare or not toSquare or fromSquare == toSquare then
        return nil, false
    end
    -- IsoGridSquare.getHoppableTo() also has a diagonal convenience path,
    -- but ClimbOverFenceState.isPlayerAbleToHopWallTo() explicitly requires
    -- adjacent squares. Accepting the convenience path here selected fences
    -- at corners and made the controller hop on a non-crossing edge.
    if not Internal.CardinalDelta(fromSquare, toSquare) then
        return nil, false
    end
    object = Internal.CallFirst(
        fromSquare,
        {
            "getHoppableTo",
            "getWallHoppableTo",
            "getHoppableThumpableTo",
        },
        toSquare
    )
    isFence, isTall = TraversalQuery.IsFence(object)
    if object and isFence then
        return object, isTall
    end
    object = Internal.CallFirst(
        toSquare,
        {
            "getHoppableTo",
            "getWallHoppableTo",
            "getHoppableThumpableTo",
        },
        fromSquare
    )
    isFence, isTall = TraversalQuery.IsFence(object)
    if object and isFence then
        return object, isTall
    end
    fromX = fromSquare:getX()
    fromY = fromSquare:getY()
    toX = toSquare:getX()
    toY = toSquare:getY()
    northEdge = math.abs(toY - fromY) >= math.abs(toX - fromX)
    squares = { fromSquare, toSquare }
    for i = 1, #squares do
        square = squares[i]
        object = Internal.CallFirst(
            square,
            {
                "getHoppable",
                "getWallHoppable",
                "getHoppableWall",
                "getThumpableWallOrHoppable",
                "getHoppableThumpable",
            },
            northEdge
        )
        isFence, isTall = TraversalQuery.IsFence(object)
        if object and isFence then
            return object, isTall
        end
        object = Internal.CallFirst(square, { "getWall" }, northEdge)
        isFence, isTall = TraversalQuery.IsFence(object)
        if object and isFence then
            return object, isTall
        end
    end
    return nil, false
end

function TraversalQuery.GetFenceCrossing(fromSquare, toSquare, cell)
    local fence
    local tall
    if not fromSquare or not toSquare then
        return nil
    end
    fence, tall = TraversalQuery.GetFenceBetween(fromSquare, toSquare)
    if not fence
        or not TraversalQuery.CanTraverseAt(
            toSquare:getX() + 0.5,
            toSquare:getY() + 0.5,
            toSquare:getZ(),
            cell
        )
    then
        return nil
    end
    return {
        object = fence,
        tall = tall == true,
        fromSquare = fromSquare,
        toSquare = toSquare,
    }
end
