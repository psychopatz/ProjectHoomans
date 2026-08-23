-- Passage lookup and goal-directed door/window/fence discovery.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal

function TraversalQuery.GetPassageBetween(fromSquare, toSquare)
    local object
    if not fromSquare or not toSquare or fromSquare == toSquare then
        return nil
    end
    object = Internal.CallFirst(fromSquare, { "getDoorTo", "getIsoDoorTo" }, toSquare)
    if object then
        return object
    end
    object = Internal.CallFirst(toSquare, { "getDoorTo", "getIsoDoorTo" }, fromSquare)
    if object then
        return object
    end
    object = Internal.CallFirst(fromSquare, { "getWindowTo", "getWindowOrWindowThumpableTo", "getWindowThumpableTo" }, toSquare)
    if object then
        return object
    end
    object = Internal.CallFirst(toSquare, { "getWindowTo", "getWindowOrWindowThumpableTo", "getWindowThumpableTo" }, fromSquare)
    if object then
        return object
    end
    return nil
end

function TraversalQuery.FindPassageToward(zombie, goalX, goalY, goalZ, cell)
    local fromSquare
    local nextSquare
    local passage
    local originX
    local originY
    local originZ
    local dirX
    local dirY
    local stepX
    local stepY
    local candidates
    local candidate
    local fence
    local tall
    local i
    if not zombie then return nil end
    cell = cell or (getCell and getCell() or nil)
    if not cell then return nil end
    originX = zombie:getX()
    originY = zombie:getY()
    originZ = zombie:getZ()
    if goalZ ~= nil and math.abs((tonumber(goalZ) or originZ) - originZ) >= 1 then
        return nil
    end
    dirX = (tonumber(goalX) or originX) - originX
    dirY = (tonumber(goalY) or originY) - originY
    if math.abs(dirX) <= 0.001 and math.abs(dirY) <= 0.001 then
        return nil
    end
    fromSquare = TraversalQuery.GetSquare(originX, originY, originZ, cell)
    if not fromSquare then return nil end
    stepX = dirX >= 0 and 1 or -1
    stepY = dirY >= 0 and 1 or -1
    if math.abs(dirX) >= math.abs(dirY) then
        candidates = {
            { x = fromSquare:getX() + stepX, y = fromSquare:getY(), enabled = math.abs(dirX) > 0.001 },
            { x = fromSquare:getX(), y = fromSquare:getY() + stepY, enabled = math.abs(dirY) > 0.001 },
        }
    else
        candidates = {
            { x = fromSquare:getX(), y = fromSquare:getY() + stepY, enabled = math.abs(dirY) > 0.001 },
            { x = fromSquare:getX() + stepX, y = fromSquare:getY(), enabled = math.abs(dirX) > 0.001 },
        }
    end
    for i = 1, #candidates do
        candidate = candidates[i]
        if candidate.enabled
            and Internal.GoalCrossesEdge(
                fromSquare,
                candidate.x,
                candidate.y,
                goalX,
                goalY
            )
        then
            nextSquare = cell:getGridSquare(candidate.x, candidate.y, originZ)
            passage = TraversalQuery.GetPassageBetween(fromSquare, nextSquare)
            if not passage and TraversalQuery.GetFenceBetween then
                fence, tall = TraversalQuery.GetFenceBetween(
                    fromSquare,
                    nextSquare
                )
                if fence
                    and TraversalQuery.IsFenceApproachReady
                    and TraversalQuery.IsFenceApproachReady(
                        originX,
                        originY,
                        fromSquare,
                        nextSquare,
                        dirX,
                        dirY
                    )
                    and TraversalQuery.CanTraverseAt(
                        nextSquare:getX() + 0.5,
                        nextSquare:getY() + 0.5,
                        nextSquare:getZ(),
                        cell
                    )
                then
                    passage = fence
                end
            end
            if passage then
                return {
                    object = passage,
                    tall = tall == true,
                    fromSquare = fromSquare,
                    toSquare = nextSquare,
                    dirX = dirX,
                    dirY = dirY,
                }
            end
        end
    end
    return nil
end
