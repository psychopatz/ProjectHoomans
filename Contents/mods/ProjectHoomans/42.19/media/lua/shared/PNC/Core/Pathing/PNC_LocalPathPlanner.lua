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
                    stepOK = Query.CanStep(
                        current.x + 0.5,
                        current.y + 0.5,
                        sz,
                        nx + 0.5,
                        ny + 0.5,
                        sz,
                        cell
                    )
                    if stepOK then
                        square = cell:getGridSquare(nx, ny, sz)
                        cost = current.cost + 1
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
        navigation.lastProgressAt = now
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

function Planner.GetSteeringTarget(record, body, finalTarget)
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
    recovered = Planner.TryLastResortRecovery(
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
        navigation.path = nil
        navigation.index = nil
        return finalTarget
    end
    while navigation.path and navigation.index
        and navigation.path[navigation.index]
    do
        waypoint = navigation.path[navigation.index]
        if distance(x, y, waypoint.x, waypoint.y) > 0.7 then break end
        navigation.index = navigation.index + 1
    end
    waypoint = navigation.path
        and navigation.index
        and navigation.path[navigation.index] or nil
    if not waypoint
        or now - (tonumber(navigation.plannedAt) or 0)
            >= (tonumber(Const.LOCAL_PATH_REPLAN_MS) or 2500)
    then
        path, reason = Planner.Plan(
            x,
            y,
            z,
            finalTarget.x,
            finalTarget.y,
            finalTarget.z,
            nil
        )
        navigation.path = path
        navigation.index = path and 1 or nil
        navigation.plannedAt = now
        navigation.lastPlanReason = reason
        navigation.planFailures = path
            and 0 or (tonumber(navigation.planFailures) or 0) + 1
        waypoint = path and path[1] or nil
    end
    if not waypoint then return finalTarget end
    return {
        x = waypoint.x,
        y = waypoint.y,
        z = waypoint.z,
        mode = finalTarget.mode,
        stopDistance = 0.35,
        localNavigation = true,
        finalTarget = finalTarget,
    }
end

function Planner.Clear(record)
    clearNavigation(record)
end

return Planner
