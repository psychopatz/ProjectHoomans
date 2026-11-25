-- Passage lookup and goal-directed door/window/fence discovery.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal
local DOOR_METHODS = { "getDoorTo" }
local WINDOW_METHODS = { "getWindowTo", "getWindowThumpableTo" }

function TraversalQuery.GetPassageBetween(fromSquare, toSquare)
    local object
    if not fromSquare or not toSquare or fromSquare == toSquare then
        return nil
    end
    local hit = false
    local cached
    if Internal.LookupEdgeCache then
        hit, cached = Internal.LookupEdgeCache(
            "passage",
            fromSquare,
            toSquare
        )
    end
    if hit then
        return cached ~= false and cached or nil
    end
    -- Java ground truth (zombie.iso.IsoGridSquare, PZ 42.20): getDoorTo(IsoGridSquare)
    -- and getWindowTo(IsoGridSquare)/getWindowThumpableTo(IsoGridSquare) exist;
    -- getIsoDoorTo and getWindowOrWindowThumpableTo do not exist at all. A name
    -- that exists with a non-matching signature is worse than a dead one: it
    -- fails overload resolution inside PZ's Kahlua bridge, which corrupts the
    -- shared MethodArguments pool and breaks unrelated bridged calls later.
    object = Internal.CallFirst(fromSquare, DOOR_METHODS, toSquare)
    if not object then
        object = Internal.CallFirst(toSquare, DOOR_METHODS, fromSquare)
    end
    if not object then
        object = Internal.CallFirst(fromSquare, WINDOW_METHODS, toSquare)
    end
    if not object then
        object = Internal.CallFirst(toSquare, WINDOW_METHODS, fromSquare)
    end
    if Internal.StoreEdgeCache then
        Internal.StoreEdgeCache("passage", fromSquare, toSquare, object or false)
    end
    return object
end

local function isDoorPassage(object)
    if not object then return false end
    -- Doors expose ToggleDoor / isLocked; windows expose smashWindow / isGlassRemoved.
    if object.smashWindow ~= nil or object.isGlassRemoved ~= nil then
        return false
    end
    return object.ToggleDoor ~= nil or object.ToggleDoorSilent ~= nil
        or object.isLocked ~= nil or object.IsOpen ~= nil
end

local function findAdjacentWallDoor(fromSquare, nextSquare, cell)
    if not fromSquare or not nextSquare or not cell then return nil end
    local fx, fy, fz = fromSquare:getX(), fromSquare:getY(), fromSquare:getZ()
    local nx, ny = nextSquare:getX(), nextSquare:getY()
    local perpX = (ny ~= fy) and 1 or 0
    local perpY = (nx ~= fx) and 1 or 0
    local offsets = { -1, 1 }
    for i = 1, 2 do
        local d = offsets[i]
        local adjFrom = cell:getGridSquare(fx + perpX * d, fy + perpY * d, fz)
        local adjTo = cell:getGridSquare(nx + perpX * d, ny + perpY * d, fz)
        if adjFrom and adjTo then
            local door = Internal.CallFirst(adjFrom, DOOR_METHODS, adjTo)
                or Internal.CallFirst(adjTo, DOOR_METHODS, adjFrom)
            if door and not (door.isBarricaded and door:isBarricaded() == true)
                and not (PNC.PathService and PNC.PathService.IsDoorRefused
                    and PNC.PathService.IsDoorRefused(door))
            then
                return door, adjFrom, adjTo
            end
        end
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
    local actorIndoors = fromSquare.isOutside and fromSquare:isOutside() == false or false
    local goalSquare = actorIndoors
        and TraversalQuery.GetSquare(goalX, goalY, goalZ or originZ, cell) or nil
    local keepIndoors = actorIndoors and goalSquare ~= nil
        and goalSquare.isOutside and goalSquare:isOutside() == false or false
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
    local fallbackResult = nil
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
            fence = nil
            tall = false
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
                local isWindow = passage.smashWindow ~= nil
                    or passage.isGlassRemoved ~= nil
                local exitsOutside = nextSquare and nextSquare.isOutside
                    and nextSquare:isOutside() == true or false
                if keepIndoors and isWindow and exitsOutside then
                    -- Never climb out an exterior window onto the lawn when both
                    -- the actor and the destination are indoors.
                    passage = nil
                end
            end
            if passage then
                if isDoorPassage(passage) then
                    return {
                        object = passage,
                        tall = false,
                        fromSquare = fromSquare,
                        toSquare = nextSquare,
                        dirX = dirX,
                        dirY = dirY,
                    }
                end
                if not fallbackResult then
                    fallbackResult = {
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
    end
    -- Zero-cost door-over-window preference: only when the direct passage is a
    -- window, check 1 tile left/right on the same wall for an unlocked door.
    if fallbackResult and fallbackResult.object
        and (fallbackResult.object.smashWindow ~= nil
            or fallbackResult.object.isGlassRemoved ~= nil)
    then
        local door, doorFrom, doorTo = findAdjacentWallDoor(
            fallbackResult.fromSquare,
            fallbackResult.toSquare,
            cell
        )
        if door then
            return {
                object = door,
                tall = false,
                fromSquare = doorFrom,
                toSquare = doorTo,
                dirX = dirX,
                dirY = dirY,
            }
        end
    end
    return fallbackResult
end
