-- Nearby room selection with deterministic scoring and bounded world scans.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table"
    or type(Geometry.DescribeRoom) ~= "function"
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

local function candidateQuery(query)
    if type(query) ~= "table" then
        return CampSite.ResolveRoomType(query), CampSite.NormalizeText(query)
    end
    return CampSite.ResolveRoomType(query.roomType or query.concept or query.text),
        CampSite.NormalizeText(query.text or query.value or query.roomQuery)
end

local function considerRoom(search, room, building)
    local site
    local dx
    local dy
    local distance
    local sameRoom
    local preferred
    local score
    if not room or search.seenRooms[room] then return false end
    search.seenRooms[room] = true
    site = Geometry.DescribeRoom(room, building, search.cell, search.origin, {
        roomType = search.wantedType,
        query = search.wantedText,
    })
    if not site then return true end
    dx = site.x - search.originX
    dy = site.y - search.originY
    distance = math.sqrt(dx * dx + dy * dy)
    sameRoom = search.originRoomID ~= nil
        and tostring(site.roomID or "") == tostring(search.originRoomID)
    preferred = search.options.preferredSiteID
        and tostring(site.siteID or "")
            == tostring(search.options.preferredSiteID)
        or search.options.preferredRoomID
        and tostring(site.roomID or "")
            == tostring(search.options.preferredRoomID)
    if math.abs(site.z - search.originZ) > 1
        or distance > search.maximum
    then
        return true
    end
    score = distance
    if sameRoom then score = score - 1000 end
    if preferred then score = score - 100 end
    if call(building, "isResidential") == true then score = score - 2 end
    if not search.best or score < search.bestScore
        or score == search.bestScore
            and tostring(site.siteID) < tostring(search.best.siteID)
    then
        search.best = site
        search.bestScore = score
        search.bestDistance = distance
    end
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

function Geometry.FindNearestRoom(cell, origin, query, options)
    options = type(options) == "table" and options or {}
    cell = cell or cellFor(options)
    local originX, originY, originZ = position(origin)
    local wantedType, wantedText = candidateQuery(query)
    local maximum = math.max(4, math.min(64,
        number(options.radius) or 32))
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
    -- index on some runtime versions.  Resolve the player's current room
    -- directly before enumerating buildings so a valid nearby living room is
    -- not rejected merely because getBuildingList()/getRooms() is incomplete.
    if originRoom then
        local directSite, directReason = Geometry.DescribeRoom(originRoom,
            buildingFor(originRoom, originRoomDef), cell, origin, {
                roomType = wantedType,
                query = wantedText,
            })
        if directSite then
            local dx = directSite.x - originX
            local dy = directSite.y - originY
            local distance = math.sqrt(dx * dx + dy * dy)
            local preferred = not options.preferredSiteID
                and not options.preferredRoomID
                or options.preferredSiteID
                and tostring(directSite.siteID or "")
                    == tostring(options.preferredSiteID)
                or options.preferredRoomID
                and tostring(directSite.roomID or "")
                    == tostring(options.preferredRoomID)
            if preferred and math.abs(directSite.z - originZ) <= 1
                and distance <= maximum
            then
                directSite.distance = distance
                directSite.selectionScore = distance - 1000
                return directSite
            end
        end
    end

    -- When the player is outside, the cell building list is not a spatial
    -- index and may be capped or ordered independently of the player's
    -- position. Discover rooms from nearby loaded squares first. This keeps
    -- the client-first camp decision local while making a visible house
    -- authoritative for the same action that requested it.
    local localRoomLimit = math.max(1, math.min(
        Geometry.MAX_LOCAL_ROOM_CANDIDATES,
        math.floor(number(options.maxLocalRooms)
            or Geometry.MAX_LOCAL_ROOM_CANDIDATES)))
    scanNearbyRooms(search, localRoomLimit)

    -- A local scan is enough for the normal visible-house case. Retain the
    -- bounded room-list/building fallback for rooms whose loaded squares do
    -- not expose room identity on this engine/version.
    if search.best then
        search.best.distance = search.bestDistance
        search.best.selectionScore = search.bestScore
        return search.best
    end

    Geometry.EnumerateRooms(cell, function(room, building)
        considerRoom(search, room, building)
    end, options)
    if not search.best then return nil, "room_not_found" end
    search.best.distance = search.bestDistance
    search.best.selectionScore = search.bestScore
    return search.best
end


return Geometry
