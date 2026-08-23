-- Goal-directed fence discovery for live traversal.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal

function TraversalQuery.FindFenceAhead(zombie, goalX, goalY, cell)
    local originX
    local originY
    local originZ
    local dirX
    local dirY
    local len
    local fromSquare
    local nextSquare
    local landingSquare
    local fence
    local tall
    local candidates
    local i
    local stepX
    local stepY
    if not zombie then
        return nil
    end
    cell = cell or (getCell and getCell() or nil)
    if not cell then
        return nil
    end
    originX = zombie:getX()
    originY = zombie:getY()
    originZ = zombie:getZ()
    dirX = (tonumber(goalX) or originX) - originX
    dirY = (tonumber(goalY) or originY) - originY
    len = math.sqrt((dirX * dirX) + (dirY * dirY))
    if len <= 0.001 then
        return nil
    end
    fromSquare = TraversalQuery.GetSquare(originX, originY, originZ, cell)
    if not fromSquare then
        return nil
    end
    stepX = dirX >= 0 and 1 or -1
    stepY = dirY >= 0 and 1 or -1
    -- Fence APIs are cardinal-edge based. A normalized diagonal probe can
    -- cross both tile axes and ask getHoppableThumpable() for the wrong edge.
    -- Probe the dominant goal axis first, then the secondary axis.
    if math.abs(dirX) >= math.abs(dirY) then
        candidates = {
            { x = fromSquare:getX() + stepX, y = fromSquare:getY() },
            { x = fromSquare:getX(), y = fromSquare:getY() + stepY, enabled = math.abs(dirY) > 0.15 },
        }
    else
        candidates = {
            { x = fromSquare:getX(), y = fromSquare:getY() + stepY },
            { x = fromSquare:getX() + stepX, y = fromSquare:getY(), enabled = math.abs(dirX) > 0.15 },
        }
    end
    for i = 1, #candidates do
        if candidates[i].enabled ~= false
            and Internal.GoalCrossesEdge(
                fromSquare,
                candidates[i].x,
                candidates[i].y,
                goalX,
                goalY
            )
        then
            nextSquare = cell:getGridSquare(candidates[i].x, candidates[i].y, originZ)
            fence, tall = TraversalQuery.GetFenceBetween(fromSquare, nextSquare)
            if fence then
                break
            end
        end
    end
    if not fence then
        return nil
    end
    landingSquare = nextSquare
    if not TraversalQuery.IsFenceApproachReady(
        originX,
        originY,
        fromSquare,
        landingSquare,
        dirX,
        dirY
    ) then
        return nil
    end
    if not landingSquare or not TraversalQuery.CanTraverseAt(
        landingSquare:getX() + 0.5,
        landingSquare:getY() + 0.5,
        landingSquare:getZ(),
        cell
    ) then
        return nil
    end
    return {
        object = fence,
        tall = tall == true,
        square = fence.getSquare and fence:getSquare() or fromSquare,
        fromSquare = fromSquare,
        dirX = dirX,
        dirY = dirY,
        landingSquare = landingSquare,
    }
end
