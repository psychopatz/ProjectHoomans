--[[
    PNC Traversal Query
    Read-only world and passage queries shared by fake locomotion and special
    traversal. This module never moves a body or starts an animation.
]]

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}

local TraversalQuery = PNC.TraversalQuery

local function callFirst(object, names, ...)
    local i
    local method
    local ok
    local result
    if not object then
        return nil
    end
    for i = 1, #names do
        method = object[names[i]]
        if type(method) == "function" then
            -- Passage APIs differ slightly between PZ point releases. Keep
            -- that compatibility uncertainty isolated to this query seam.
            ok, result = pcall(method, object, ...)
            if ok and result ~= nil then
                return result
            end
        end
    end
    return nil
end

local function objectBool(object, names, defaultValue)
    local result = callFirst(object, names)
    if result == nil then
        return defaultValue == true
    end
    return result == true
end

function TraversalQuery.GetSquare(x, y, z, cell)
    cell = cell or (getCell and getCell() or nil)
    if not cell then
        return nil
    end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

function TraversalQuery.IsDoor(object)
    if not object then
        return false
    end
    if instanceof and instanceof(object, "IsoDoor") then
        return true
    end
    return objectBool(object, { "isDoor", "IsDoor" }, false)
end

function TraversalQuery.IsWindow(object)
    return object ~= nil and instanceof ~= nil and instanceof(object, "IsoWindow")
end

function TraversalQuery.IsFence(object)
    local properties
    local high
    if not object then
        return false, false
    end
    properties = object.getProperties and object:getProperties() or nil
    high = properties and properties.get and properties:get("FenceTypeHigh") ~= nil or false
    return high
        or (properties and properties.get and properties:get("FenceTypeLow") ~= nil or false)
        or objectBool(object, { "isHoppable" }, false)
        or objectBool(object, { "isTallHoppable" }, false),
        high or objectBool(object, { "isTallHoppable" }, false)
end

function TraversalQuery.GetPassageBetween(fromSquare, toSquare)
    local object
    if not fromSquare or not toSquare or fromSquare == toSquare then
        return nil
    end
    object = callFirst(fromSquare, { "getDoorTo", "getIsoDoorTo" }, toSquare)
    if object then
        return object
    end
    object = callFirst(fromSquare, { "getWindowTo", "getWindowOrWindowThumpableTo", "getWindowThumpableTo" }, toSquare)
    if object then
        return object
    end
    return nil
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
    fromX = fromSquare:getX()
    fromY = fromSquare:getY()
    toX = toSquare:getX()
    toY = toSquare:getY()
    northEdge = math.abs(toY - fromY) >= math.abs(toX - fromX)
    squares = { fromSquare, toSquare }
    for i = 1, #squares do
        square = squares[i]
        object = callFirst(square, { "getHoppableThumpable" }, northEdge)
        isFence, isTall = TraversalQuery.IsFence(object)
        if object and isFence then
            return object, isTall
        end
        object = callFirst(square, { "getWall" }, northEdge)
        isFence, isTall = TraversalQuery.IsFence(object)
        if object and isFence then
            return object, isTall
        end
    end
    return nil, false
end

function TraversalQuery.IsClosedPassage(object)
    if TraversalQuery.IsDoor(object) then
        return not objectBool(object, { "IsOpen", "isOpen" }, false)
    end
    if TraversalQuery.IsWindow(object) then
        return not objectBool(object, { "IsOpen", "isOpen" }, false)
            and not objectBool(object, { "isDestroyed", "IsDestroyed", "isSmashed" }, false)
    end
    return false
end

function TraversalQuery.CanOccupy(x, y, z, cell)
    local square = TraversalQuery.GetSquare(x, y, z, cell)
    return square ~= nil
        and square:isFree(false)
        and not square:isSolid()
        and not square:isSolidTrans()
end

function TraversalQuery.CanStep(fromX, fromY, fromZ, toX, toY, toZ, cell)
    local fromSquare
    local toSquare
    local passage
    local fence
    fromSquare = TraversalQuery.GetSquare(fromX, fromY, fromZ, cell)
    toSquare = TraversalQuery.GetSquare(toX, toY, toZ, cell)
    if not fromSquare or not toSquare then
        return false, "unloaded"
    end
    if fromSquare == toSquare then
        return TraversalQuery.CanOccupy(toX, toY, toZ, cell), "clear"
    end
    passage = TraversalQuery.GetPassageBetween(fromSquare, toSquare)
    if passage and TraversalQuery.IsWindow(passage) then
        return false, "window"
    end
    if passage and TraversalQuery.IsClosedPassage(passage) then
        return false, "door"
    end
    fence = TraversalQuery.GetFenceBetween(fromSquare, toSquare)
    if fence then
        return false, "fence"
    end
    if fromSquare.isWallTo and fromSquare:isWallTo(toSquare) then
        return false, "wall"
    end
    if fromSquare.isBlockedTo and fromSquare:isBlockedTo(toSquare) then
        return false, "blocked_edge"
    end
    if not TraversalQuery.CanOccupy(toX, toY, toZ, cell) then
        return false, "occupied"
    end
    return true, "clear"
end

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
        if candidates[i].enabled ~= false then
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
    if not landingSquare or not TraversalQuery.CanOccupy(landingSquare:getX() + 0.5, landingSquare:getY() + 0.5, landingSquare:getZ(), cell) then
        return nil
    end
    return {
        object = fence,
        tall = tall == true,
        square = fence.getSquare and fence:getSquare() or fromSquare,
        dirX = dirX,
        dirY = dirY,
        landingSquare = landingSquare,
    }
end
