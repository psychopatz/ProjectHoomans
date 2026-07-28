-- Bounded local navigation for embodied long-distance travel.
--
-- Abstract travel remains a cheap route projection. Once an NPC is live this
-- planner searches only loaded squares near the body, strongly preferring
-- outdoor paths so a straight world-map route does not cut through buildings.

PNC = PNC or {}
PNC.LocalPathPlanner = PNC.LocalPathPlanner or {}

local Planner = PNC.LocalPathPlanner
local Const = PNC.Const
local Core = PNC.Core
local Query = PNC.TraversalQuery
local LiveBodyControl = PNC.LiveBodyControl

local CARDINAL = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

local WAYPOINT_REACHED_RADIUS = 0.55
local TRAVERSAL_WAYPOINT_RADIUS = 0.38
local ROUTE_LOOKAHEAD_WAYPOINTS = 3
local ROUTE_LOOKAHEAD_DISTANCE = 2.75

local function key(x, y)
    return tostring(x) .. ":" .. tostring(y)
end

local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt((dx * dx) + (dy * dy))
end

local function isInterior(square)
    if not square then return false end
    if square.getBuilding and square:getBuilding() then return true end
    return square.getRoom and square:getRoom() ~= nil or false
end

local function canTraverseAt(x, y, z, cell)
    if Query and Query.CanTraverseAt then
        return Query.CanTraverseAt(x, y, z, cell)
    end
    return Query and Query.CanOccupy
        and Query.CanOccupy(x, y, z, cell) or false
end

local function heapPush(heap, node)
    local index = #heap + 1
    heap[index] = node
    while index > 1 do
        local parent = math.floor(index / 2)
        if heap[parent].score <= node.score then break end
        heap[index] = heap[parent]
        index = parent
    end
    heap[index] = node
end

local function heapPop(heap)
    local root = heap[1]
    local tail = table.remove(heap)
    local index = 1
    if #heap <= 0 then return root end
    while true do
        local left = index * 2
        local right = left + 1
        local child
        if left > #heap then break end
        child = right <= #heap
            and heap[right].score < heap[left].score
            and right or left
        if heap[child].score >= tail.score then break end
        heap[index] = heap[child]
        index = child
    end
    heap[index] = tail
    return root
end

local function reconstruct(nodes, current)
    local reversed = {}
    local output = {}
    while current and current.parent do
        reversed[#reversed + 1] = {
            x = current.x + 0.5,
            y = current.y + 0.5,
            z = current.z,
            traversalKind = current.traversalKind,
        }
        current = nodes[current.parent]
    end
    for i = #reversed, 1, -1 do
        output[#output + 1] = reversed[i]
    end
    return output
end

local function proxyGoal(startX, startY, goalX, goalY)
    local lookahead = math.max(
        4,
        tonumber(Const.LOCAL_PATH_LOOKAHEAD_TILES) or 14
    )
    local dx = goalX - startX
    local dy = goalY - startY
    local length = math.sqrt((dx * dx) + (dy * dy))
    if length <= lookahead then
        return math.floor(goalX), math.floor(goalY)
    end
    return math.floor(startX + (dx / length) * lookahead),
        math.floor(startY + (dy / length) * lookahead)
end

-- Cheap bounded probe used before A*. It follows a cardinalized line toward
-- the lookahead goal and stops at the first wall/passage edge. Long open runs
-- therefore stay on direct fake locomotion without paying for a search.
local function hasClearDirectRoute(
    startX,
    startY,
    startZ,
    goalX,
    goalY,
    cell
)
    local currentX = math.floor(startX)
    local currentY = math.floor(startY)
    local targetX
    local targetY
    local deltaX
    local deltaY
    local stepX
    local stepY
    local error
    local doubled
    local nextX
    local nextY
    local ok
    targetX, targetY = proxyGoal(
        currentX,
        currentY,
        tonumber(goalX) or currentX,
        tonumber(goalY) or currentY
    )
    deltaX = math.abs(targetX - currentX)
    deltaY = math.abs(targetY - currentY)
    stepX = currentX < targetX and 1 or -1
    stepY = currentY < targetY and 1 or -1
    error = deltaX - deltaY
    while currentX ~= targetX or currentY ~= targetY do
        doubled = error * 2
        nextX = currentX
        nextY = currentY
        if doubled > -deltaY then
            error = error - deltaY
            nextX = currentX + stepX
        end
        -- Keep every probe cardinal. If Bresenham wants both axes, validate
        -- the X edge now and the Y edge on the next loop.
        if nextX == currentX and doubled < deltaX then
            error = error + deltaX
            nextY = currentY + stepY
        end
        ok = Query.CanStep(
            currentX + 0.5,
            currentY + 0.5,
            startZ,
            nextX + 0.5,
            nextY + 0.5,
            startZ,
            cell
        )
        if not ok then return false end
        currentX = nextX
        currentY = nextY
    end
    return true
end

local function hasPassedWaypoint(navigation, path, index, x, y)
    local waypoint = path and path[index] or nil
    local previous = index and index > 1 and path[index - 1] or nil
    local previousX = previous and previous.x
        or navigation and navigation.planStartX
    local previousY = previous and previous.y
        or navigation and navigation.planStartY
    local segmentX
    local segmentY
    if not waypoint or waypoint.traversalKind
        or previousX == nil or previousY == nil
    then
        return false
    end
    segmentX = waypoint.x - previousX
    segmentY = waypoint.y - previousY
    if (segmentX * segmentX) + (segmentY * segmentY) <= 0.0001 then
        return false
    end
    return ((x - waypoint.x) * segmentX)
        + ((y - waypoint.y) * segmentY) >= 0
end

local function advanceReachedWaypoints(navigation, x, y)
    local path = navigation and navigation.path or nil
    local index = navigation and navigation.index or nil
    local waypoint
    local radius
    while path and index and path[index] do
        waypoint = path[index]
        radius = waypoint.traversalKind
            and TRAVERSAL_WAYPOINT_RADIUS
            or WAYPOINT_REACHED_RADIUS
        if distance(x, y, waypoint.x, waypoint.y) > radius
            and not hasPassedWaypoint(
                navigation,
                path,
                index,
                x,
                y
            )
        then
            break
        end
        index = index + 1
    end
    if navigation then
        navigation.index = index
    end
    return path and index and path[index] or nil
end

local function selectLookaheadWaypoint(
    navigation,
    x,
    y,
    z,
    cell
)
    local path = navigation and navigation.path or nil
    local baseIndex = navigation and navigation.index or nil
    local selected
    local selectedIndex
    local lastIndex
    local candidate
    local index
    if not path or not baseIndex or not path[baseIndex] then
        return nil, nil
    end
    selected = path[baseIndex]
    selectedIndex = baseIndex
    if selected.traversalKind
        or not cell
        or not Query
        or not Query.CanStep
    then
        return selected, selectedIndex
    end
    lastIndex = math.min(
        #path,
        baseIndex + ROUTE_LOOKAHEAD_WAYPOINTS
    )
    for index = baseIndex + 1, lastIndex do
        candidate = path[index]
        if distance(x, y, candidate.x, candidate.y)
            > ROUTE_LOOKAHEAD_DISTANCE
        then
            break
        end
        if not hasClearDirectRoute(
            x,
            y,
            z,
            candidate.x,
            candidate.y,
            cell
        ) then
            break
        end
        selected = candidate
        selectedIndex = index
        -- A traversal entry is a precision point. It may be looked toward,
        -- but steering must never skip through it to a later route point.
        if candidate.traversalKind then
            break
        end
    end
    return selected, selectedIndex
end

function Planner.Plan(startX, startY, startZ, goalX, goalY, goalZ, options)
    local cell = options and options.cell
        or getCell and getCell() or nil
    local radius = math.max(
        4,
        math.floor(tonumber(
            options and options.radius
                or Const.LOCAL_PATH_SEARCH_RADIUS
        ) or 18)
    )
    local maxNodes = math.max(
        32,
        math.floor(tonumber(
            options and options.maxNodes
                or Const.LOCAL_PATH_MAX_NODES
        ) or 768)
    )
    local interiorPenalty = math.max(
        0,
        tonumber(
            options and options.interiorPenalty
                or Const.LOCAL_PATH_INTERIOR_PENALTY
        ) or 10
    )
    local sx = math.floor(tonumber(startX) or 0)
    local sy = math.floor(tonumber(startY) or 0)
    local sz = math.floor(tonumber(startZ) or 0)
    local gx
    local gy
    local open = {}
    local nodes = {}
    local closed = {}
    local expanded = 0
    local start
    local current
    local best
    local direction
    local nx
    local ny
    local neighborKey
    local neighbor
    local stepOK
    local stepKind
    local actionCost
    local square
    local cost
    local heuristic
    local i
    if not cell or not Query or not Query.CanStep then
        return nil, "world_unavailable"
    end
    gx, gy = proxyGoal(
        sx,
        sy,
        tonumber(goalX) or sx,
        tonumber(goalY) or sy
    )
    start = {
        x = sx,
        y = sy,
        z = sz,
        cost = 0,
        heuristic = math.abs(gx - sx) + math.abs(gy - sy),
    }
    start.score = start.heuristic
    nodes[key(sx, sy)] = start
    heapPush(open, start)
    best = start

    while #open > 0 and expanded < maxNodes do
        current = heapPop(open)
        local currentKey = key(current.x, current.y)
        if not closed[currentKey] then
            closed[currentKey] = true
            expanded = expanded + 1
            if current.heuristic < best.heuristic then best = current end
            if current.x == gx and current.y == gy then
                return reconstruct(nodes, current), "planned"
            end
            for i = 1, #CARDINAL do
                direction = CARDINAL[i]
                nx = current.x + direction[1]
                ny = current.y + direction[2]
                neighborKey = key(nx, ny)
                if not closed[neighborKey]
                    and math.max(math.abs(nx - sx), math.abs(ny - sy))
                        <= radius
                then
                    if Query.CanPlanStep then
                        stepOK, stepKind, actionCost =
                            Query.CanPlanStep(
                                current.x + 0.5,
                                current.y + 0.5,
                                sz,
                                nx + 0.5,
                                ny + 0.5,
                                sz,
                                cell,
                                options and options.body or nil,
                                options
                            )
                    else
                        stepOK = Query.CanStep(
                            current.x + 0.5,
                            current.y + 0.5,
                            sz,
                            nx + 0.5,
                            ny + 0.5,
                            sz,
                            cell
                        )
                        stepKind = "walk"
                        actionCost = 0
                    end
                    if stepOK then
                        square = cell:getGridSquare(nx, ny, sz)
                        cost = current.cost + 1 + (
                            tonumber(actionCost) or 0
                        )
                            + (isInterior(square) and interiorPenalty or 0)
                        neighbor = nodes[neighborKey]
                        if not neighbor or cost < neighbor.cost then
                            heuristic = math.abs(gx - nx) + math.abs(gy - ny)
                            neighbor = {
                                x = nx,
                                y = ny,
                                z = sz,
                            }
                            neighbor.cost = cost
                            neighbor.heuristic = heuristic
                            neighbor.score = cost + heuristic
                            neighbor.parent = currentKey
                            neighbor.traversalKind = stepKind ~= "walk"
                                and stepKind or nil
                            nodes[neighborKey] = neighbor
                            heapPush(open, neighbor)
                        end
                    end
                end
            end
        end
    end
    if best and best ~= start and best.heuristic <= start.heuristic - 2 then
        return reconstruct(nodes, best), "partial"
    end
    return nil, "no_path"
end

local function clearNavigation(record)
    if record and record.runtime then
        record.runtime.localNavigation = nil
    end
end

local function updateProgress(navigation, x, y, finalX, finalY, now)
    local remaining = distance(x, y, finalX, finalY)
    local moved = navigation.lastObservedX ~= nil
        and distance(
            x,
            y,
            navigation.lastObservedX,
            navigation.lastObservedY
        )
        or 0
    if navigation.lastObservedX == nil or moved >= 0.35 then
        navigation.lastObservedX = x
        navigation.lastObservedY = y
        navigation.lastMovementAt = now
    end
    if navigation.bestRemaining == nil
        or remaining <= navigation.bestRemaining - 0.25
    then
        navigation.bestRemaining = remaining
        navigation.lastProgressAt = now
    end
    return remaining
end

local function recordRecovery(record, fromX, fromY, fromZ, x, y, z, now)
    local recovery
    record.runtime = record.runtime or {}
    recovery = record.runtime.positionRecovery or {}
    record.runtime.positionRecovery = recovery
    recovery.count = (tonumber(recovery.count) or 0) + 1
    recovery.lastAt = now
    recovery.lastEvent = "travel_last_resort"
    recovery.lastReason = "local_path_stalled"
    recovery.fromX = fromX
    recovery.fromY = fromY
    recovery.fromZ = fromZ
    recovery.toX = x
    recovery.toY = y
    recovery.toZ = z
    record.runtime.forceSyncEvent = "position_recovery"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "position_recovery")
    end
end

function Planner.TryLastResortRecovery(
    record,
    body,
    finalTarget,
    navigation,
    now
)
    local delay = math.max(
        5000,
        tonumber(Const.LOCAL_PATH_LAST_RESORT_DELAY_MS) or 15000
    )
    local cooldown = math.max(
        delay,
        tonumber(Const.LOCAL_PATH_LAST_RESORT_COOLDOWN_MS) or 20000
    )
    local radius = math.max(
        2,
        math.floor(tonumber(
            Const.LOCAL_PATH_LAST_RESORT_RADIUS
        ) or 4)
    )
    local fromX = body:getX()
    local fromY = body:getY()
    local fromZ = body:getZ()
    local goalX = tonumber(finalTarget.x) or fromX
    local goalY = tonumber(finalTarget.y) or fromY
    local currentDistance = distance(fromX, fromY, goalX, goalY)
    local cell = getCell and getCell() or nil
    local best
    local ring
    local dx
    local dy
    local x
    local y
    local candidateDistance
    local square
    if not cell or not Query or not Query.CanOccupy
        or now - (tonumber(navigation.lastProgressAt) or now) < delay
        or (
            (tonumber(navigation.lastRecoveryAt) or 0) > 0
            and now - (tonumber(navigation.lastRecoveryAt) or 0) < cooldown
        )
    then
        return false
    end
    for ring = 2, radius do
        for dx = -ring, ring do
            for dy = -ring, ring do
                if math.max(math.abs(dx), math.abs(dy)) == ring then
                    x = math.floor(fromX) + dx + 0.5
                    y = math.floor(fromY) + dy + 0.5
                    candidateDistance = distance(x, y, goalX, goalY)
                    if candidateDistance <= currentDistance - 1
                        and canTraverseAt(x, y, fromZ, cell)
                    then
                        square = cell:getGridSquare(
                            math.floor(x),
                            math.floor(y),
                            math.floor(fromZ)
                        )
                        if not best
                            or (
                                isInterior(best.square)
                                and not isInterior(square)
                            )
                            or isInterior(best.square) == isInterior(square)
                                and candidateDistance < best.distance
                        then
                            best = {
                                x = x,
                                y = y,
                                z = fromZ,
                                distance = candidateDistance,
                                square = square,
                            }
                        end
                    end
                end
            end
        end
        if best and not isInterior(best.square) then break end
    end
    if not best then
        navigation.lastRecoveryAt = now
        return false
    end
    if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
        LiveBodyControl.SetAuthoritativePosition(
            body,
            best.x,
            best.y,
            best.z
        )
    else
        body:setX(best.x)
        body:setY(best.y)
        body:setZ(best.z)
    end
    record.x = best.x
    record.y = best.y
    record.z = best.z
    navigation.lastRecoveryAt = now
    navigation.lastProgressAt = now
    navigation.bestRemaining = best.distance
    navigation.lastObservedX = best.x
    navigation.lastObservedY = best.y
    navigation.path = nil
    navigation.index = nil
    if PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(body, record)
    end
    recordRecovery(
        record,
        fromX,
        fromY,
        fromZ,
        best.x,
        best.y,
        best.z,
        now
    )
    if Core and Core.LogWarn then
        Core.LogWarn(
            "PNC travel last-resort recovery npc="
                .. tostring(record.id)
                .. " from=" .. tostring(fromX) .. "," .. tostring(fromY)
                .. " to=" .. tostring(best.x) .. "," .. tostring(best.y)
        )
    end
    return true
end

function Planner.GetSteeringTarget(record, body, finalTarget, options)
    local now
    local navigation
    local signature
    local x
    local y
    local z
    local remaining
    local waypoint
    local path
    local reason
    local recovered
    local cell
    local replanInterval
    local replanDue
    local steeringIndex
    if not record or not body or type(finalTarget) ~= "table" then
        return finalTarget
    end
    record.runtime = record.runtime or {}
    now = Core.Now()
    x = body:getX()
    y = body:getY()
    z = body:getZ()
    if math.floor(tonumber(finalTarget.z) or z) ~= math.floor(z) then
        clearNavigation(record)
        return finalTarget
    end
    signature = tostring(math.floor(tonumber(finalTarget.x) or x))
        .. ":" .. tostring(math.floor(tonumber(finalTarget.y) or y))
        .. ":" .. tostring(math.floor(tonumber(finalTarget.z) or z))
    navigation = record.runtime.localNavigation
    if not navigation or navigation.signature ~= signature then
        navigation = {
            signature = signature,
            plannedAt = 0,
            lastProgressAt = now,
            lastRecoveryAt = 0,
        }
        record.runtime.localNavigation = navigation
    end
    remaining = updateProgress(
        navigation,
        x,
        y,
        tonumber(finalTarget.x) or x,
        tonumber(finalTarget.y) or y,
        now
    )
    recovered = options and options.allowRecovery == true
        and Planner.TryLastResortRecovery(
            record,
            body,
            finalTarget,
            navigation,
            now
        )
    if recovered then
        x = body:getX()
        y = body:getY()
        z = body:getZ()
        remaining = distance(
            x,
            y,
            tonumber(finalTarget.x) or x,
            tonumber(finalTarget.y) or y
        )
    end
    if remaining <= 3 then
        cell = getCell and getCell() or nil
        if not cell
            or not Query
            or not Query.CanStep
            or hasClearDirectRoute(
                x,
                y,
                z,
                finalTarget.x,
                finalTarget.y,
                cell
            )
        then
            navigation.path = nil
            navigation.index = nil
            navigation.steeringIndex = nil
            navigation.steeringKind = "final_near"
            navigation.currentTraversalKind = nil
            return finalTarget
        end
    end
    waypoint = advanceReachedWaypoints(navigation, x, y)
    if navigation.path and not waypoint then
        navigation.path = nil
        navigation.index = nil
        navigation.steeringIndex = nil
        navigation.plannedAt = 0
    end
    replanInterval = tonumber(Const.LOCAL_PATH_REPLAN_MS) or 2500
    replanDue = (tonumber(navigation.plannedAt) or 0) <= 0
        or now - (tonumber(navigation.plannedAt) or 0) >= replanInterval
    if replanDue then
        cell = cell or (getCell and getCell() or nil)
        if not waypoint
            and cell
            and Query
            and Query.CanStep
            and hasClearDirectRoute(
                x,
                y,
                z,
                finalTarget.x,
                finalTarget.y,
                cell
            )
        then
            navigation.plannedAt = now
            navigation.lastPlanReason = "direct_clear"
            navigation.planFailures = 0
            navigation.steeringKind = "final_direct"
            navigation.steeringIndex = nil
            navigation.currentTraversalKind = nil
            return finalTarget
        end
        path, reason = Planner.Plan(
            x,
            y,
            z,
            finalTarget.x,
            finalTarget.y,
            finalTarget.z,
            {
                body = body,
                radius = options and options.radius,
                maxNodes = options and options.maxNodes,
                interiorPenalty = options
                    and options.interiorPenalty,
                allowDoors = not options
                    or options.allowDoors ~= false,
                allowWindows = not options
                    or options.allowWindows ~= false,
                allowFences = not options
                    or options.allowFences ~= false,
            }
        )
        navigation.path = path
        navigation.index = path and 1 or nil
        navigation.steeringIndex = navigation.index
        navigation.planStartX = x
        navigation.planStartY = y
        navigation.plannedAt = now
        navigation.lastPlanReason = reason
        navigation.planFailures = path
            and 0 or (tonumber(navigation.planFailures) or 0) + 1
        waypoint = path and path[1] or nil
    end
    if not waypoint then
        navigation.steeringKind = "final_fallback"
        navigation.steeringIndex = nil
        navigation.currentTraversalKind = nil
        return finalTarget
    end
    cell = cell or (getCell and getCell() or nil)
    waypoint, steeringIndex = selectLookaheadWaypoint(
        navigation,
        x,
        y,
        z,
        cell
    )
    navigation.steeringIndex = steeringIndex
    navigation.steeringKind = steeringIndex
        and navigation.index
        and steeringIndex > navigation.index
        and "waypoint_lookahead" or "waypoint"
    navigation.currentTraversalKind = waypoint.traversalKind
    return {
        x = waypoint.x,
        y = waypoint.y,
        z = waypoint.z,
        mode = finalTarget.mode,
        stopDistance = 0.35,
        localNavigation = true,
        traversalKind = waypoint.traversalKind,
        waypointIndex = navigation.index,
        steeringIndex = steeringIndex,
        steeringKind = navigation.steeringKind,
        finalTarget = finalTarget,
    }
end

function Planner.Clear(record)
    clearNavigation(record)
end

function Planner.Invalidate(record, reason)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if not navigation then return false end
    navigation.path = nil
    navigation.index = nil
    navigation.steeringIndex = nil
    navigation.plannedAt = 0
    navigation.lastPlanReason = "invalidated:"
        .. tostring(reason or "unknown")
    navigation.invalidations =
        (tonumber(navigation.invalidations) or 0) + 1
    return true
end

return Planner
