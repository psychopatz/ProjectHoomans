--[[
    PNC Traversal Query
    Read-only world and passage queries shared by fake locomotion and special
    traversal. This module never moves a body or starts an animation.
]]

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}

local TraversalQuery = PNC.TraversalQuery
local VehicleAvoidance = PNC.VehicleAvoidance

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

local function listSize(list)
    if not list or not list.size then
        return 0
    end
    return list:size()
end

local function listItem(list, index)
    if not list or not list.get then
        return nil
    end
    return list:get(index)
end

local function getMaterializationObstacle(square)
    local objects
    local object
    local sprite
    local i
    if not square or not square.getObjects then
        return nil
    end
    objects = square:getObjects()
    for i = 0, listSize(objects) - 1 do
        object = listItem(objects, i)
        if object and not (object.isFloor and object:isFloor()) then
            if instanceof and instanceof(object, "IsoFeedingTrough") then
                return "feeding_trough"
            end
            if object.isTableSurface and object:isTableSurface() then
                return "table_surface"
            end
            if object.getContainer and object:getContainer() then
                return "container_object"
            end
            sprite = object.getSprite and object:getSprite() or nil
            if sprite and sprite.getSpriteGrid and sprite:getSpriteGrid() then
                return "multi_tile_object"
            end
        end
    end
    return nil
end

local function findNearestByReason(x, y, z, maxRadius, cell, reasonResolver)
    local originX = math.floor(tonumber(x) or 0)
    local originY = math.floor(tonumber(y) or 0)
    local originZ = math.floor(tonumber(z) or 0)
    local originalReason
    local radius
    local dx
    local dy
    local candidateX
    local candidateY
    local candidateDistSq
    local best
    maxRadius = math.max(0, math.floor(tonumber(maxRadius) or 3))
    originalReason = reasonResolver(
        originX + 0.5,
        originY + 0.5,
        originZ,
        cell
    )
    if not originalReason then
        return tonumber(x) or originX + 0.5,
            tonumber(y) or originY + 0.5,
            originZ,
            nil
    end
    for radius = 1, maxRadius do
        best = nil
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius then
                    candidateX = originX + dx + 0.5
                    candidateY = originY + dy + 0.5
                    if not reasonResolver(candidateX, candidateY, originZ, cell) then
                        candidateDistSq = (candidateX - (tonumber(x) or originX + 0.5)) ^ 2
                            + (candidateY - (tonumber(y) or originY + 0.5)) ^ 2
                        if not best
                            or candidateDistSq < best.distSq
                            or (
                                candidateDistSq == best.distSq
                                and (
                                    candidateX < best.x
                                    or (candidateX == best.x and candidateY < best.y)
                                )
                            )
                        then
                            best = {
                                x = candidateX,
                                y = candidateY,
                                z = originZ,
                                distSq = candidateDistSq,
                            }
                        end
                    end
                end
            end
        end
        if best then
            return best.x, best.y, best.z, originalReason
        end
    end
    return nil, nil, nil, originalReason
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
    object = callFirst(toSquare, { "getDoorTo", "getIsoDoorTo" }, fromSquare)
    if object then
        return object
    end
    object = callFirst(fromSquare, { "getWindowTo", "getWindowOrWindowThumpableTo", "getWindowThumpableTo" }, toSquare)
    if object then
        return object
    end
    object = callFirst(toSquare, { "getWindowTo", "getWindowOrWindowThumpableTo", "getWindowThumpableTo" }, fromSquare)
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
        if candidate.enabled then
            nextSquare = cell:getGridSquare(candidate.x, candidate.y, originZ)
            passage = TraversalQuery.GetPassageBetween(fromSquare, nextSquare)
            if passage then
                return {
                    object = passage,
                    fromSquare = fromSquare,
                    toSquare = nextSquare,
                }
            end
        end
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

function TraversalQuery.GetOccupancyReason(x, y, z, cell)
    local square = TraversalQuery.GetSquare(x, y, z, cell)
    local vehicleReason
    if not square then return "unloaded" end
    if VehicleAvoidance and VehicleAvoidance.GetReason then
        vehicleReason = VehicleAvoidance.GetReason(x, y, z, cell, false)
    elseif objectBool(square, { "isVehicleIntersecting" }, false) then
        vehicleReason = "vehicle"
    end
    if vehicleReason then return vehicleReason end
    if square:isSolid() then return "solid" end
    if square:isSolidTrans() then return "solid_trans" end
    if not square:isFree(false) then return "occupied" end
    return nil
end

function TraversalQuery.CanOccupy(x, y, z, cell)
    return TraversalQuery.GetOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.GetTraversalOccupancyReason(x, y, z, cell)
    local reason = TraversalQuery.GetOccupancyReason(x, y, z, cell)
    if reason then return reason end
    if VehicleAvoidance and VehicleAvoidance.GetReason then
        return VehicleAvoidance.GetReason(x, y, z, cell, true)
    end
    return nil
end

function TraversalQuery.CanTraverseAt(x, y, z, cell)
    return TraversalQuery.GetTraversalOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.FindNearestOccupable(x, y, z, maxRadius, cell)
    return findNearestByReason(
        x,
        y,
        z,
        maxRadius,
        cell,
        TraversalQuery.GetOccupancyReason
    )
end

function TraversalQuery.GetMaterializationOccupancyReason(x, y, z, cell)
    local square = TraversalQuery.GetSquare(x, y, z, cell)
    local reason = TraversalQuery.GetOccupancyReason(x, y, z, cell)
    if reason then
        return reason
    end
    if VehicleAvoidance and VehicleAvoidance.GetReason then
        reason = VehicleAvoidance.GetReason(x, y, z, cell, true)
        if reason then return reason end
    end
    if square.hasFloor and not square:hasFloor() then
        return "no_floor"
    end
    return getMaterializationObstacle(square)
end

function TraversalQuery.CanMaterializeAt(x, y, z, cell)
    return TraversalQuery.GetMaterializationOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.FindNearestMaterializationSquare(x, y, z, maxRadius, cell)
    return findNearestByReason(
        x,
        y,
        z,
        maxRadius,
        cell,
        TraversalQuery.GetMaterializationOccupancyReason
    )
end

function TraversalQuery.CanStep(fromX, fromY, fromZ, toX, toY, toZ, cell)
    local fromSquare
    local toSquare
    local passage
    local fence
    local fromReason
    local toReason
    fromSquare = TraversalQuery.GetSquare(fromX, fromY, fromZ, cell)
    toSquare = TraversalQuery.GetSquare(toX, toY, toZ, cell)
    if not fromSquare or not toSquare then
        return false, "unloaded"
    end
    toReason = TraversalQuery.GetTraversalOccupancyReason(
        toX,
        toY,
        toZ,
        cell
    )
    -- Vehicle safety must win over passage handling. Otherwise a window or
    -- fence on the same edge can start a traversal whose landing tile is a
    -- synchronized vehicle footprint.
    if toReason == "vehicle" then
        return false, toReason
    end
    if toReason == "vehicle_clearance" then
        fromReason = TraversalQuery.GetTraversalOccupancyReason(
            fromX,
            fromY,
            fromZ,
            cell
        )
        if fromReason ~= "vehicle_clearance" then
            return false, toReason
        end
    end
    if fromSquare == toSquare then
        if not toReason then return true, "clear" end
        if toReason == "vehicle_clearance"
            and fromReason == "vehicle_clearance"
        then
            return true, "clear"
        end
        return false, toReason
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
    if toReason then
        if toReason == "vehicle_clearance"
            and fromReason == "vehicle_clearance"
        then
            return true, "clear"
        end
        return false, toReason
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
        dirX = dirX,
        dirY = dirY,
        landingSquare = landingSquare,
    }
end
