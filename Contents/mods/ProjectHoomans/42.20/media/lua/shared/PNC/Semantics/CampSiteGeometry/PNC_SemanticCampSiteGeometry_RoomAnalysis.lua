-- Bounded room-shape analysis for camp placement.
--
-- One pass over the room's own square list (no cell scans) produces the
-- usable floor, door/opening tiles, and the door-reachable floor component.
-- Two O(n) breadth-first passes then rank tiles by openness (distance from
-- walls/furniture) and by distance from exits so the anchor and per-member
-- slots sit in the open middle of the room instead of the doorway.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Internal.IsUsable) ~= "function" then
    error("camp-site room analysis requires room records")
end

local call = Internal.Call
local listSize = Internal.ListSize
local listItem = Internal.ListItem
local position = Internal.Position
local roomSquares = Internal.RoomSquares
local isUsable = Internal.IsUsable

Geometry.MAX_CAMP_SLOTS = 12
Geometry.TILES_PER_MEMBER = 3
Geometry.DEFAULT_GROUP_SIZE = 4
Geometry.ANALYSIS_CACHE_MS = 2000
Geometry.MAX_ANALYSIS_CACHE = 48

local DEPTH_CAP = 4
local EXIT_CAP = 8
local NEIGHBORS = {
    { 0, -1, "getN" }, { 0, 1, "getS" }, { 1, 0, "getE" }, { -1, 0, "getW" },
}

local cache = {}
local cacheCount = 0

local function tileKey(x, y)
    return x * 65536 + y
end

-- Internal.Call collapses `false` into nil; edge predicates need the boolean.
local function predicate(object, method, argument)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, argument)
    if not ok then return nil end
    return value
end

local function nowMs()
    if type(getTimestampMs) ~= "function" then return nil end
    local ok, value = pcall(getTimestampMs)
    return ok and tonumber(value) or nil
end

local function collect(room, bounds, cell)
    local tiles = {}
    local usableAt = {}
    local roomAt = {}
    local squares = roomSquares(room)
    local size = math.min(listSize(squares), Geometry.MAX_ROOM_SQUARES)
    local function add(square)
        local x, y, z
        local key
        if not square then return end
        x, y, z = position(square)
        if not x or not y then return end
        x = math.floor(x)
        y = math.floor(y)
        key = tileKey(x, y)
        if roomAt[key] then return end
        roomAt[key] = true
        if isUsable(square, cell) then
            tiles[#tiles + 1] = { x = x, y = y, z = z, square = square }
            usableAt[key] = #tiles
        end
    end
    for index = 0, size - 1 do add(listItem(squares, index)) end
    add(call(room, "getFreeTile"))
    if #tiles > 0 or not bounds or not cell then
        return tiles, usableAt, roomAt
    end
    -- Runtime builds without a room square list: bounded rectangle scan.
    local inspected = 0
    for x = math.floor(bounds.minX), math.floor(bounds.maxX) do
        for y = math.floor(bounds.minY), math.floor(bounds.maxY) do
            if inspected >= Geometry.MAX_FALLBACK_SCAN then
                return tiles, usableAt, roomAt
            end
            inspected = inspected + 1
            add(Geometry.GetSquare(cell, x, y, bounds.z))
        end
    end
    return tiles, usableAt, roomAt
end

local function classifyEdges(tiles, usableAt, roomAt)
    local exits = 0
    for index = 1, #tiles do
        local tile = tiles[index]
        local open = 0
        for n = 1, 4 do
            local offset = NEIGHBORS[n]
            local key = tileKey(tile.x + offset[1], tile.y + offset[2])
            if usableAt[key] then
                open = open + 1
            elseif not roomAt[key] then
                -- Leaving the room: a door or an unwalled opening is traffic.
                local other = call(tile.square, offset[3])
                if other and (predicate(tile.square, "isDoorTo", other) == true
                    or predicate(tile.square, "isBlockedTo", other) == false)
                then
                    tile.exit = true
                end
            end
        end
        tile.edge = open < 4
        if tile.exit then exits = exits + 1 end
    end
    return exits
end

local function flood(tiles, usableAt, seedField, outField, cap, allowed)
    local queue = {}
    local head = 1
    for index = 1, #tiles do
        local tile = tiles[index]
        if tile[seedField] and (not allowed or allowed[index]) then
            tile[outField] = 0
            queue[#queue + 1] = index
        end
    end
    while head <= #queue do
        local tile = tiles[queue[head]]
        local distance = tile[outField]
        head = head + 1
        if distance < cap then
            for n = 1, 4 do
                local offset = NEIGHBORS[n]
                local other = usableAt[tileKey(tile.x + offset[1],
                    tile.y + offset[2])]
                if other and tiles[other][outField] == nil
                    and (not allowed or allowed[other])
                then
                    tiles[other][outField] = distance + 1
                    queue[#queue + 1] = other
                end
            end
        end
    end
    for index = 1, #tiles do
        if tiles[index][outField] == nil then tiles[index][outField] = cap end
    end
end

-- Furniture can split a room. Keep only the floor component reachable from
-- the most doors (or the largest one) so no slot sits behind a counter.
local function reachableComponent(tiles, usableAt)
    local label = {}
    local bestMembers
    local bestExits = -1
    for start = 1, #tiles do
        if not label[start] then
            local members = { start }
            local exits = tiles[start].exit and 1 or 0
            local head = 1
            label[start] = true
            while head <= #members do
                local tile = tiles[members[head]]
                head = head + 1
                for n = 1, 4 do
                    local offset = NEIGHBORS[n]
                    local other = usableAt[tileKey(tile.x + offset[1],
                        tile.y + offset[2])]
                    if other and not label[other] then
                        label[other] = true
                        members[#members + 1] = other
                        if tiles[other].exit then exits = exits + 1 end
                    end
                end
            end
            if not bestMembers or exits > bestExits
                or exits == bestExits and #members > #bestMembers
            then
                bestMembers = members
                bestExits = exits
            end
        end
    end
    local allowed = {}
    for index = 1, #(bestMembers or {}) do allowed[bestMembers[index]] = true end
    return allowed, #(bestMembers or {})
end

local function better(left, right)
    if not right then return true end
    if left.score ~= right.score then return left.score > right.score end
    if left.y ~= right.y then return left.y < right.y end
    return left.x < right.x
end

local function pickSlots(candidates, maximum)
    local chosen = {}
    local spacings = { 2, 1 }
    for pass = 1, #spacings do
        local spacing = spacings[pass]
        while #chosen < maximum do
            local best
            for index = 1, #candidates do
                local tile = candidates[index]
                if not tile.taken and better(tile, best) then
                    local clear = true
                    for c = 1, #chosen do
                        local other = chosen[c]
                        if math.max(math.abs(other.x - tile.x),
                            math.abs(other.y - tile.y)) < spacing
                        then
                            clear = false
                            break
                        end
                    end
                    if clear then best = tile end
                end
            end
            if not best then break end
            best.taken = true
            chosen[#chosen + 1] = best
        end
    end
    return chosen
end

local function analyze(room, bounds, cell)
    local tiles, usableAt, roomAt = collect(room, bounds, cell)
    if #tiles == 0 then return nil end
    local exitCount = classifyEdges(tiles, usableAt, roomAt)
    local allowed, capacity = reachableComponent(tiles, usableAt)
    flood(tiles, usableAt, "edge", "depth", DEPTH_CAP, allowed)
    flood(tiles, usableAt, "exit", "exitDistance", EXIT_CAP, allowed)

    local candidates = {}
    local sumX, sumY = 0, 0
    local minX, minY, maxX, maxY
    local maxDepth = 0
    for index = 1, #tiles do
        if allowed[index] then
            local tile = tiles[index]
            candidates[#candidates + 1] = tile
            sumX = sumX + tile.x
            sumY = sumY + tile.y
            minX = minX and math.min(minX, tile.x) or tile.x
            minY = minY and math.min(minY, tile.y) or tile.y
            maxX = maxX and math.max(maxX, tile.x) or tile.x
            maxY = maxY and math.max(maxY, tile.y) or tile.y
            if tile.depth > maxDepth then maxDepth = tile.depth end
        end
    end
    local centerX = sumX / #candidates
    local centerY = sumY / #candidates
    for index = 1, #candidates do
        local tile = candidates[index]
        local dx = tile.x - centerX
        local dy = tile.y - centerY
        tile.score = math.min(tile.depth, 3) * 3
            + math.min(tile.exitDistance, 6) * 2
            - math.sqrt(dx * dx + dy * dy) * 0.15
    end

    local chosen = pickSlots(candidates,
        math.min(Geometry.MAX_CAMP_SLOTS, #candidates))
    local slots = {}
    for index = 1, #chosen do
        slots[index] = {
            x = chosen[index].x + 0.5,
            y = chosen[index].y + 0.5,
            z = chosen[index].z,
        }
    end
    local width = maxX - minX + 1
    local height = maxY - minY + 1
    return {
        anchor = slots[1],
        slots = slots,
        capacity = capacity,
        campCapacity = math.max(1,
            math.floor(capacity / Geometry.TILES_PER_MEMBER)),
        exitCount = exitCount,
        maxDepth = maxDepth,
        width = width,
        height = height,
        narrow = math.min(width, height) <= 2 or maxDepth == 0,
    }
end

-- Returns a primitive-only analysis table (no Java references), or nil when
-- the room has no usable floor. Briefly cached per room so the client hint,
-- server validation, and zone discovery do not repeat the same scan.
function Geometry.AnalyzeRoom(room, bounds, cell)
    if not room then return nil end
    local at = nowMs()
    local cached = at and cache[room]
    if cached and at - cached.at <= Geometry.ANALYSIS_CACHE_MS then
        return cached.analysis
    end
    local analysis = analyze(room, bounds, cell)
    if at then
        if cacheCount >= Geometry.MAX_ANALYSIS_CACHE then
            cache = {}
            cacheCount = 0
        end
        if not cache[room] then cacheCount = cacheCount + 1 end
        cache[room] = { at = at, analysis = analysis }
    end
    return analysis
end

function Geometry.ClearRoomAnalysisCache()
    cache = {}
    cacheCount = 0
end

Internal.AnalyzeRoom = Geometry.AnalyzeRoom
return Geometry
