if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Bounded room discovery and resource enrichment for camp zones.
local Service = PNC.CampZoneService
local Internal = Service.Internal
local CampSite = Internal.CampSite
local Geometry = Internal.Geometry
local number = Internal.number
local text = Internal.text
local call = Internal.call
local field = Internal.field
local identifier = Internal.identifier
local listSize = Internal.listSize
local listItem = Internal.listItem
local primitiveCopy = Internal.primitiveCopy
local cellFor = Internal.cellFor
local copySite = Internal.copySite
local zoneID = Internal.zoneID
local roomFor = Internal.roomFor
local roomBuilding = Internal.roomBuilding
local roomSquares = Internal.roomSquares
local siteDistanceSq = Internal.siteDistanceSq
local providerIDs = Internal.providerIDs

local function scanRoom(zone, room, cell, record)
    local resources = PNC.CampResourceService
    local output = {}
    local seen = {}
    local squares = room and roomSquares(room) or nil
    local squareCount = math.min(listSize(squares), Service.MAX_ROOM_SQUARES)
    local providerList = providerIDs(resources)
    local live = record and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local function addResource(resource)
        local copy
        local key
        if type(resource) ~= "table" then return end
        copy = primitiveCopy(resource)
        key = text(copy and (copy.resourceKey or copy.key), nil, 160)
        if not key or seen[key] then return end
        seen[key] = true
        copy.resourceKey = key
        output[#output + 1] = copy
    end
    local function inspect(square, trustedRoom)
        local provider
        local id
        local matchesRoom
        if not square then return end
        if not trustedRoom and zone.scope == CampSite.SCOPES.ROOM
            and Geometry.MatchesRoom
        then
            matchesRoom = Geometry.MatchesRoom(square, zone)
            if matchesRoom ~= true then return end
        end
        for index = 1, #providerList do
            id = providerList[index]
            provider = resources and resources.Providers[id]
            if provider and type(provider.CaptureSquare) == "function" then
                pcall(provider.CaptureSquare, square, addResource, {
                    record = record,
                    character = live,
                    zone = zone,
                })
            end
        end
    end
    for index = 0, squareCount - 1 do
        -- A square returned by the room's own list already carries the room
        -- identity. Avoid calling Geometry.MatchesRoom here: on some engine
        -- builds that recomputes room bounds, turning a bounded scan into an
        -- accidental O(n^2) operation.
        inspect(listItem(squares, index), true)
    end
    if squareCount == 0 and zone.roomBounds and cell
        and Geometry.GetSquare
    then
        local minX = math.floor(number(zone.roomBounds.minX, zone.x or 0))
        local minY = math.floor(number(zone.roomBounds.minY, zone.y or 0))
        local maxX = math.floor(number(zone.roomBounds.maxX, minX))
        local maxY = math.floor(number(zone.roomBounds.maxY, minY))
        local inspected = 0
        for x = minX, maxX do
            for y = minY, maxY do
                if inspected >= Service.MAX_ROOM_SQUARES then break end
                inspected = inspected + 1
                inspect(Geometry.GetSquare(cell, x, y, zone.roomBounds.z
                    or zone.z))
            end
            if inspected >= Service.MAX_ROOM_SQUARES then break end
        end
    end
    return output
end

local function capabilities(zone, resources)
    local kinds = {}
    local hasSeat = false
    local hasSleep = false
    local hasWater = false
    local roomType = tostring(zone.roomType or "")
    local resource
    for index = 1, #(resources or {}) do
        resource = resources[index]
        local kind = tostring(resource.resourceKind or "")
        kinds[kind] = (tonumber(kinds[kind]) or 0) + 1
        if kind == "seating_surface" then hasSeat = true end
        if kind == "sleep_surface" then hasSleep = true end
        if kind == "water_source" then hasWater = true end
    end
    return {
        sleep = hasSleep,
        water = hasWater,
        food = roomType == "KITCHEN" or roomType == "DINING_ROOM",
        social = roomType == "LIVING_ROOM"
            or roomType == "KITCHEN"
            or roomType == "DINING_ROOM"
            or hasSeat,
        seating = hasSeat,
        resourceKinds = kinds,
    }
end

local function addZone(directory, roomsByID, site, room, rootSite)
    local id
    local copy
    local existing
    if type(site) ~= "table" then return false end
    if #directory.zones >= Service.MAX_ZONES then return false end
    copy = copySite(site)
    if copy.x == nil or copy.y == nil then return false end
    if math.abs(number(copy.z, 0) - number(rootSite.z, 0)) > 0.5 then
        return false
    end
    copy.siteID = zoneID(copy)
    copy.distance = math.sqrt(siteDistanceSq(copy, rootSite))
    id = tostring(copy.siteID)
    existing = directory.zoneByID[id]
    if existing then
        if room then roomsByID[id] = room end
        return false
    end
    if copy.distance > Service.MAX_DISCOVERY_RADIUS then return false end
    directory.zoneByID[id] = copy
    roomsByID[id] = room
    directory.zones[#directory.zones + 1] = copy
    return true
end

local function rootRoomInfo(cell, rootSite)
    local room
    if not cell or not Geometry or not Geometry.GetSquare then
        return nil, nil
    end
    local square = Geometry.GetSquare(cell, rootSite.x, rootSite.y, rootSite.z)
    room = roomFor(square)
    return room, roomBuilding(room)
end

local function sameBuilding(rootBuilding, rootBuildingID,
    candidateBuilding, candidateBuildingID)
    if rootBuilding and candidateBuilding
        and rootBuilding == candidateBuilding
    then
        return true
    end
    if rootBuildingID ~= "" and candidateBuildingID ~= "" then
        return rootBuildingID == candidateBuildingID
    end
    -- If one runtime exposes a building object but not an id, do not widen a
    -- room-group scan to unrelated buildings. The only permissive case is
    -- when neither side exposes an identity at all.
    if rootBuilding or candidateBuilding then return false end
    return true
end

local function discoverZones(rootSite, options)
    local directory = {
        zones = {},
        zoneByID = {},
        assignments = {},
        rejected = {},
    }
    local roomsByID = {}
    local cell = cellFor(options)
    local rootRoom
    local rootBuilding
    local rootBuildingID = tostring(rootSite.buildingID or "")
    rootRoom, rootBuilding = rootRoomInfo(cell, rootSite)
    if rootBuildingID == "" then
        rootBuildingID = tostring(identifier(rootBuilding) or "")
    end
    addZone(directory, roomsByID, rootSite, rootRoom, rootSite)
    if options.rootOnly ~= true
        and rootSite.scope == CampSite.SCOPES.ROOM and cell
        and Geometry and type(Geometry.EnumerateRooms) == "function"
    then
        Geometry.EnumerateRooms(cell, function(room, building)
            local candidate
            local candidateBuilding
            local candidateBuildingID
            if #directory.zones >= Service.MAX_ZONES then
                return
            end
            candidateBuilding = building or roomBuilding(room)
            candidateBuildingID = tostring(identifier(candidateBuilding) or "")
            if not sameBuilding(rootBuilding, rootBuildingID,
                candidateBuilding, candidateBuildingID)
            then
                return
            end
            candidate = Geometry.DescribeRoom(
                room, candidateBuilding, cell, rootSite, {})
            if not candidate then return end
            if rootBuildingID ~= ""
                and tostring(candidate.buildingID or "") ~= rootBuildingID
                and not (rootBuilding and candidateBuilding
                    and rootBuilding == candidateBuilding)
            then
                return
            end
            addZone(directory, roomsByID, candidate, room, rootSite)
        end, { maxRooms = Service.MAX_ROOM_CANDIDATES })
    end
    directory.zoneByID = nil
    table.sort(directory.zones, function(left, right)
        if number(left.distance, 0) ~= number(right.distance, 0) then
            return number(left.distance, 0) < number(right.distance, 0)
        end
        return tostring(left.siteID or "") < tostring(right.siteID or "")
    end)
    return directory, roomsByID, cell, rootRoom
end

local function enrichZones(directory, roomsByID, cell, rootRoom, record)
    local zone
    local room
    local resources
    for index = 1, #directory.zones do
        zone = directory.zones[index]
        room = roomsByID[tostring(zone.siteID or "")] or nil
        if not room and index == 1 then room = rootRoom end
        if not room and cell and Geometry.GetSquare then
            room = roomFor(Geometry.GetSquare(cell, zone.x, zone.y, zone.z))
        end
        resources = scanRoom(zone, room, cell, record)
        zone.resources = resources
        zone.capabilities = capabilities(zone, resources)
        zone.resourceCount = #resources
        -- This is a bounded primitive debug projection. The Java room is kept
        -- only in the local roomsByID map and never enters the directory.
    end
end

Internal.scanRoom = scanRoom
Internal.capabilities = capabilities
Internal.addZone = addZone
Internal.rootRoomInfo = rootRoomInfo
Internal.sameBuilding = sameBuilding
Internal.discoverZones = discoverZones
Internal.enrichZones = enrichZones

return Service
