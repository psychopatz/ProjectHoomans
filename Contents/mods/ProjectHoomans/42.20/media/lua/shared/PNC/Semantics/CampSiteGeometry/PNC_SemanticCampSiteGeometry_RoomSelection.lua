-- Space-aware nearby room selection with deterministic scoring and bounded
-- world scans.
--
-- Phase 1 ranks every nearby room cheaply from its RoomDef rectangle (no
-- square iteration). Phase 2 runs the full floor analysis only on the best
-- few finalists and re-scores them by real usable, door-reachable floor.
-- Large open rooms in the current building win over hallways, vestibules,
-- and rooms too small for the group; distance still breaks near-ties.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table"
    or type(Geometry.DescribeRoom) ~= "function"
    or type(Geometry.SummarizeRoom) ~= "function"
    or type(Geometry.EnumerateRooms) ~= "function"
then
    error("camp-site room selection requires room enumeration and projection")
end

local CampSite = Internal.CampSite
local call = Internal.Call
local number = Internal.Number
local cellFor = Internal.CellFor
local position = Internal.Position
local roomFor = Internal.RoomFor
local roomDefFor = Internal.RoomDefFor
local buildingFor = Internal.BuildingFor
local identifier = Internal.Identifier

Geometry.MAX_DETAILED_ROOMS = 4
Geometry.MAX_DETAIL_ATTEMPTS = 8
Geometry.SPACE_SCORE_CAP = 64

local function candidateQuery(query)
    if type(query) ~= "table" then
        return CampSite.ResolveRoomType(query), CampSite.NormalizeText(query)
    end
    return CampSite.ResolveRoomType(query.roomType or query.concept or query.text),
        CampSite.NormalizeText(query.text or query.value or query.roomQuery)
end

local function boundsDistance(bounds, x, y)
    local dx = 0
    local dy = 0
    if x < bounds.minX then dx = bounds.minX - x
    elseif x > bounds.maxX + 1 then dx = x - bounds.maxX - 1 end
    if y < bounds.minY then dy = bounds.minY - y
    elseif y > bounds.maxY + 1 then dy = y - bounds.maxY - 1 end
    return math.sqrt(dx * dx + dy * dy)
end

-- Lower is better. `space` is usable floor tiles (bounds area before the
-- finalist analysis). Weights keep "camp here" inside the current building:
-- a different building must be far roomier to beat a usable local room.
local function placementScore(search, info)
    local score = info.distance
    score = score - math.min(info.space, Geometry.SPACE_SCORE_CAP) * 0.5
    if info.space < search.minCapacity then score = score + 30 end
    if info.narrow then score = score + 20 end
    if info.roomType == "HALLWAY" then score = score + 20 end
    if info.sameRoom then score = score - 8 end
    if search.originBuildingID then
        if info.sameBuilding then score = score - 15 else score = score + 25 end
    end
    if info.preferred then score = score - 100 end
    if info.residential then score = score - 2 end
    return score
end

local function isRoomy(search, site)
    return site and (tonumber(site.capacity) or 0) >= search.minCapacity
        and site.narrow ~= true and site.roomType ~= "HALLWAY"
end

local function candidateFor(search, room, building, summary)
    local options = search.options
    local bounds = summary.bounds
    local width = bounds.maxX - bounds.minX + 1
    local height = bounds.maxY - bounds.minY + 1
    local roomID = summary.roomID and tostring(summary.roomID) or nil
    local siteID = "room:" .. tostring(summary.buildingID or "unknown") .. ":"
        .. tostring(roomID or (bounds.minX .. ":" .. bounds.minY))
    local info = {
        room = room,
        building = building or summary.building,
        siteID = siteID,
        roomType = summary.roomType,
        distance = boundsDistance(bounds, search.originX, search.originY),
        space = width * height,
        narrow = math.min(width, height) <= 2,
        sameRoom = search.originRoomID ~= nil
            and tostring(roomID or "") == tostring(search.originRoomID),
        sameBuilding = search.originBuildingID ~= nil
            and tostring(summary.buildingID or "")
                == tostring(search.originBuildingID),
        preferred = options.preferredSiteID
            and siteID == tostring(options.preferredSiteID)
            or options.preferredRoomID
            and tostring(roomID or "") == tostring(options.preferredRoomID)
            or false,
        residential = call(building or summary.building,
            "isResidential") == true,
    }
    info.cheapScore = placementScore(search, info)
    return info
end

local function considerRoom(search, room, building)
    local summary
    local z
    local info
    if not room or search.seenRooms[room] then return false end
    search.seenRooms[room] = true
    summary = Geometry.SummarizeRoom(room, building, {
        roomType = search.wantedType,
        query = search.wantedText,
    })
    if not summary then return true end
    z = number(summary.bounds.z) or search.originZ
    if math.abs(z - search.originZ) > 1 then return true end
    info = candidateFor(search, room, building, summary)
    if info.distance > search.maximum then return true end
    search.candidates[#search.candidates + 1] = info
    return true
end

local function scanNearbyRooms(search, localRoomLimit)
    local localRoomCandidates = 0
    local function inspectNearbySquare(x, y)
        local square
        local room
        if localRoomCandidates >= localRoomLimit then return false end
        square = Geometry.GetSquare(search.cell, x, y, search.originZ)
        room = roomFor(square)
        if room and not search.seenRooms[room]
            and localRoomCandidates < localRoomLimit
        then
            if considerRoom(search, room,
                buildingFor(room, roomDefFor(room)))
            then
                localRoomCandidates = localRoomCandidates + 1
                if localRoomCandidates >= localRoomLimit then return false end
            end
        end
        return true
    end

    local baseX = math.floor(search.originX)
    local baseY = math.floor(search.originY)
    for ring = 0, math.floor(search.maximum) do
        if ring == 0 then
            if not inspectNearbySquare(baseX, baseY) then return end
        else
            for dx = -ring, ring do
                if not inspectNearbySquare(baseX + dx, baseY - ring) then
                    return
                end
                if not inspectNearbySquare(baseX + dx, baseY + ring) then
                    return
                end
            end
            for dy = -ring + 1, ring - 1 do
                if not inspectNearbySquare(baseX - ring, baseY + dy) then
                    return
                end
                if not inspectNearbySquare(baseX + ring, baseY + dy) then
                    return
                end
            end
        end
    end
end

local function siteDistance(search, site)
    local dx = site.x - search.originX
    local dy = site.y - search.originY
    return math.sqrt(dx * dx + dy * dy)
end

-- Full floor analysis on the cheapest-ranked finalists only.
local function chooseBest(search)
    local candidates = search.candidates
    local best
    local bestScore
    local described = 0
    local attempts = 0
    table.sort(candidates, function(left, right)
        if left.cheapScore ~= right.cheapScore then
            return left.cheapScore < right.cheapScore
        end
        return left.siteID < right.siteID
    end)
    for index = 1, #candidates do
        if described >= Geometry.MAX_DETAILED_ROOMS
            or attempts >= Geometry.MAX_DETAIL_ATTEMPTS
        then
            break
        end
        local info = candidates[index]
        local site = info.site
        if not site then
            attempts = attempts + 1
            site = Geometry.DescribeRoom(info.room, info.building,
                search.cell, search.origin, {
                    roomType = search.wantedType,
                    query = search.wantedText,
                })
        end
        if site and math.abs((number(site.z) or search.originZ)
            - search.originZ) <= 1
        then
            described = described + 1
            info.space = tonumber(site.capacity) or info.space
            info.narrow = site.narrow == true
            local score = placementScore(search, info)
            if not best or score < bestScore
                or score == bestScore
                    and tostring(site.siteID) < tostring(best.siteID)
            then
                best = site
                bestScore = score
            end
        end
    end
    if not best then return nil end
    best.distance = siteDistance(search, best)
    best.selectionScore = bestScore
    return best
end

function Geometry.FindNearestRoom(cell, origin, query, options)
    options = type(options) == "table" and options or {}
    cell = cell or cellFor(options)
    local originX, originY, originZ = position(origin)
    local wantedType, wantedText = candidateQuery(query)
    local maximum = math.max(4, math.min(64,
        number(options.radius) or 32))
    local groupSize = math.max(1, math.floor(number(options.groupSize)
        or Geometry.DEFAULT_GROUP_SIZE))
    local search = {
        cell = cell,
        origin = origin,
        originX = originX,
        originY = originY,
        originZ = originZ,
        wantedType = wantedType,
        wantedText = wantedText,
        maximum = maximum,
        options = options,
        seenRooms = {},
        candidates = {},
        minCapacity = math.max(6, groupSize * Geometry.TILES_PER_MEMBER),
    }
    local originSquare = origin and call(origin, "getCurrentSquare")
        or (originX and Geometry.GetSquare(cell, originX, originY, originZ))
    local originRoom = originSquare and roomFor(originSquare) or nil
    local originRoomDef = originRoom and roomDefFor(originRoom) or nil
    search.originRoomID = identifier(originRoomDef, { "getIDString", "getID" })

    if not cell or originX == nil or originY == nil then
        return nil, "room_origin_unavailable"
    end

    -- Loaded-square room identity is more reliable than the cell building
    -- index on some runtime versions. The player's own room is accepted
    -- outright when it is explicitly requested or genuinely roomy; a cramped
    -- vestibule/hallway only competes as a candidate against nearby rooms.
    if originRoom then
        local originBuilding = buildingFor(originRoom, originRoomDef)
        local identity = Geometry.SummarizeRoom(originRoom, originBuilding, {})
        search.originBuildingID = identity and identity.buildingID
            and tostring(identity.buildingID) or nil
        local directSite = Geometry.DescribeRoom(originRoom,
            originBuilding, cell, origin, {
                roomType = wantedType,
                query = wantedText,
            })
        if directSite then
            local distance = siteDistance(search, directSite)
            local explicit = options.preferredSiteID
                and tostring(directSite.siteID or "")
                    == tostring(options.preferredSiteID)
                or options.preferredRoomID
                and tostring(directSite.roomID or "")
                    == tostring(options.preferredRoomID)
            local unconstrained = not options.preferredSiteID
                and not options.preferredRoomID
            local usable = math.abs(directSite.z - originZ) <= 1
                and distance <= maximum
            if usable and (explicit
                or unconstrained and isRoomy(search, directSite))
            then
                directSite.distance = distance
                directSite.selectionScore = distance - 1000
                return directSite
            end
            if usable and identity then
                do
                    local info = candidateFor(search, originRoom,
                        originBuilding, identity)
                    info.site = directSite
                    info.space = tonumber(directSite.capacity) or info.space
                    info.narrow = directSite.narrow == true
                    info.cheapScore = placementScore(search, info)
                    search.candidates[#search.candidates + 1] = info
                end
            end
        end
        search.seenRooms[originRoom] = true
    end

    -- Discover rooms from nearby loaded squares first: the cell building
    -- list is not a spatial index and may be capped or ordered arbitrarily.
    local localRoomLimit = math.max(1, math.min(
        Geometry.MAX_LOCAL_ROOM_CANDIDATES,
        math.floor(number(options.maxLocalRooms)
            or Geometry.MAX_LOCAL_ROOM_CANDIDATES)))
    scanNearbyRooms(search, localRoomLimit)

    -- Retain the bounded room-list/building fallback for rooms whose loaded
    -- squares do not expose room identity on this engine/version.
    if #search.candidates == 0 then
        Geometry.EnumerateRooms(cell, function(room, building)
            considerRoom(search, room, building)
        end, options)
    end
    local best = chooseBest(search)
    if not best then return nil, "room_not_found" end
    return best
end


return Geometry
