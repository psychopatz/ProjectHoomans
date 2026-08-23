-- Shared probing geometry and special-action suppression policy.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery

local function normalize2D(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then return nil, nil end
    return dx / len, dy / len
end

local function sameSquare(left, right)
    return left ~= nil and right ~= nil
        and left:getX() == right:getX()
        and left:getY() == right:getY()
        and left:getZ() == right:getZ()
end

function Internal.passageMethodReturnsTrue(object, names)
    if not object then return false end
    for i = 1, #names do
        local method = object[names[i]]
        if type(method) == "function" and method(object) == true then
            return true
        end
    end
    return false
end

function Internal.passageImprovesGoalDistance(
    fromX, fromY, toX, toY, goalX, goalY
)
    return Internal.Core.Distance(toX, toY, goalX, goalY) + 0.05
        < Internal.Core.Distance(fromX, fromY, goalX, goalY)
end

function Internal.passageObstacleSquareKey(square)
    return square and ("sq:" .. Internal.describeSquare(square)) or nil
end

function Internal.passageWindowDestination(object, actorSquare)
    local objectSquare = object and object.getSquare
        and object:getSquare() or nil
    local oppositeSquare = object and object.getOppositeSquare
        and object:getOppositeSquare() or nil
    if sameSquare(actorSquare, objectSquare) then return oppositeSquare end
    if sameSquare(actorSquare, oppositeSquare) then return objectSquare end
    return nil
end

function Internal.logTraversalReject(
    record, zombie, lane, event, reason, extra
)
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        event or "traversal_rejected",
        reason or "rejected",
        extra or ""
    )
end

function Internal.passageFindFenceAhead(cell, zombie, goalX, goalY)
    if TraversalQuery and TraversalQuery.FindFenceAhead then
        return TraversalQuery.FindFenceAhead(zombie, goalX, goalY, cell)
    end
    return nil
end

function Internal.passageIsObstacleAhead(
    zombie, square, goalX, goalY, fallbackX, fallbackY
)
    if not zombie then return false end
    local goalDirX, goalDirY = normalize2D(
        (tonumber(goalX) or zombie:getX()) - zombie:getX(),
        (tonumber(goalY) or zombie:getY()) - zombie:getY()
    )
    if not goalDirX then return true end
    local objectX = square and (square:getX() + 0.5) or fallbackX
    local objectY = square and (square:getY() + 0.5) or fallbackY
    local obstacleDirX, obstacleDirY = normalize2D(
        (tonumber(objectX) or zombie:getX()) - zombie:getX(),
        (tonumber(objectY) or zombie:getY()) - zombie:getY()
    )
    if not obstacleDirX and fallbackX and fallbackY then
        obstacleDirX, obstacleDirY = normalize2D(
            fallbackX - zombie:getX(),
            fallbackY - zombie:getY()
        )
    end
    if not obstacleDirX then return true end
    return ((goalDirX * obstacleDirX)
        + (goalDirY * obstacleDirY)) >= 0.25
end

function Internal.rememberSpecialAction(lane, key, now)
    if not lane then return end
    lane.lastSpecialActionKey = key
    lane.lastSpecialActionAt = now
end

function Internal.shouldSuppressSpecialAction(lane, key, now)
    if not lane or not key then return false end
    return lane.lastSpecialActionKey == key
        and (now - (tonumber(lane.lastSpecialActionAt) or 0))
            < Internal.SPECIAL_ACTION_COOLDOWN_MS
end

function Internal.isDoorCollision(zombie)
    if not zombie then return false end
    local method = zombie.isCollidedWithDoor
    if type(method) == "function" then return method(zombie) == true end
    return Internal.passageMethodReturnsTrue(
        zombie,
        { "isCollidedThisFrame", "isCollided" }
    )
end

