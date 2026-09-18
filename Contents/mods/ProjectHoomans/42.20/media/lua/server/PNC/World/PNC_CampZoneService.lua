-- Server-owned allocation of a validated camp into nearby loaded room zones.
--
-- The client still decides which nearby NPC ids it can see. This service is
-- only invoked after the server has validated the shared camp site and the
-- command registry has filtered those ids to owned, live, materialized
-- followers. Room discovery is bounded and happens once per group-camp
-- command; it is never a per-tick perception scan.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.CampZoneService = PNC.CampZoneService or {}

local Service = PNC.CampZoneService
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"

Service.VERSION = 1
Service.MAX_ZONES = 32
Service.MAX_ROOM_CANDIDATES = 128
Service.MAX_ROOM_SQUARES = 1024
Service.MAX_DISCOVERY_RADIUS = 48
Service.MAX_RETAINED_CAMPS = 32
Service.Runtime = Service.Runtime or {}
Service.Runtime.camps = Service.Runtime.camps or {}
Service.Runtime.sequence = tonumber(Service.Runtime.sequence) or 0

local PROVIDER_ORDER = { "bed", "sofa", "faucet", "seat" }
local NEED_ORDER = { "sleep", "hydration", "hunger" }
local NEED_KIND = {
    sleep = "sleep",
    hydration = "water",
    hunger = "food",
}

local function number(value, fallback)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return fallback
end

local function text(value, fallback, maximum)
    if value == nil then return fallback end
    value = tostring(value)
    if maximum then value = string.sub(value, 1, maximum) end
    return value ~= "" and value or fallback
end

local function call(object, method, ...)
    local fn = object and object[method]
    local ok
    local value
    if type(fn) ~= "function" then return nil end
    ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function field(object, name)
    local ok
    local value
    if not object then return nil end
    ok, value = pcall(function() return object[name] end)
    return ok and value or nil
end

local function identifier(value)
    local result
    result = call(value, "getIDString") or call(value, "getID")
        or field(value, "id") or field(value, "ID")
    return text(result, nil, 128)
end

local function listSize(list)
    local size = number(call(list, "size"))
    if size ~= nil then return math.max(0, math.floor(size)) end
    if type(list) == "table" then return #list end
    return 0
end

local function listItem(list, index)
    local value = call(list, "get", index)
    if value ~= nil then return value end
    if type(list) == "table" then return list[index + 1] end
    return nil
end

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ"), 0)
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ, 0)
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function primitiveCopy(value, depth)
    local valueType = type(value)
    local output
    local child
    local copied
    if value == nil then return nil end
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or (depth or 0) >= 5 then return nil end
    output = {}
    for key, childValue in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            child = childValue
            copied = primitiveCopy(child, (depth or 0) + 1)
            if copied ~= nil then output[key] = copied end
        end
    end
    return output
end

local function copyBounds(bounds)
    if not bounds then return nil end
    if CampSite and CampSite.NormalizeBounds then
        return CampSite.NormalizeBounds(bounds)
    end
    return primitiveCopy(bounds)
end

local function copySite(site)
    local output = primitiveCopy(site) or {}
    output.kind = CampSite.KIND
    output.scope = CampSite.NormalizeScope(site and (
        site.scope or site.siteScope)) or CampSite.SCOPES.CAMPFIRE
    output.siteScope = output.scope
    output.siteID = text(site and site.siteID, nil, 128)
    output.roomID = text(site and site.roomID, nil, 128)
    output.buildingID = text(site and site.buildingID, nil, 128)
    output.roomType = text(site and site.roomType, nil, 48)
    output.roomName = text(site and site.roomName, nil, 64)
    output.roomBounds = copyBounds(site and site.roomBounds)
    output.campfireID = text(site and site.campfireID, nil, 128)
    output.x = number(site and site.x)
    output.y = number(site and site.y)
    output.z = number(site and site.z, 0)
    output.label = text(site and site.label, "room", 64)
    output.risk = text(site and site.risk, nil, 32)
    output.radius = number(site and site.radius, 3)
    output.resourceRadius = number(site and site.resourceRadius, 12)
    output.stopDistance = number(site and site.stopDistance, 0.7)
    return output
end

local function cellFor(options)
    if type(options) == "table" and options.cell then return options.cell end
    if type(getCell) == "function" then
        local ok, cell = pcall(getCell)
        if ok then return cell end
    end
    return nil
end

local function roomFor(square)
    local internal = Geometry and Geometry._Internal
    if internal and type(internal.RoomFor) == "function" then
        return internal.RoomFor(square)
    end
    return call(square, "getRoom") or call(square, "getIsoRoom")
end

local function roomBuilding(room)
    return call(room, "getBuilding") or field(room, "building")
end

local function roomSquares(room)
    local internal = Geometry and Geometry._Internal
    if internal and type(internal.Call) == "function" then
        return internal.Call(room, "getSquares")
            or field(room, "squares") or field(room, "tileList")
    end
    return call(room, "getSquares")
        or field(room, "squares") or field(room, "tileList")
end

local function siteDistanceSq(left, right)
    local dx = number(left and left.x, 0) - number(right and right.x, 0)
    local dy = number(left and left.y, 0) - number(right and right.y, 0)
    return dx * dx + dy * dy
end

local function zoneID(site)
    return text(site and site.siteID,
        "room:" .. tostring(site and site.roomID or "unknown"), 160)
end

local function providerIDs(resources)
    local output = {}
    local seen = {}
    local providers = resources and resources.Providers or {}
    local id
    local provider
    for index = 1, #PROVIDER_ORDER do
        id = PROVIDER_ORDER[index]
        provider = providers[id]
        if provider and type(provider.CaptureSquare) == "function" then
            output[#output + 1] = id
            seen[id] = true
        end
    end
    -- Future perception providers can participate without editing this
    -- allocator. Their capability mapping is intentionally separate below.
    for id, provider in pairs(providers) do
        if not seen[id] and provider
            and type(provider.CaptureSquare) == "function"
        then
            output[#output + 1] = tostring(id)
        end
    end
    table.sort(output)
    return output
end

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
        local ok
        local matchesRoom
        if not square then return end
        if not trustedRoom and zone.scope == CampSite.SCOPES.ROOM
            and Geometry.MatchesRoom
        then
            ok, matchesRoom = pcall(Geometry.MatchesRoom, square, zone)
            if not ok or matchesRoom ~= true then return end
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

local function evaluateNeed(definitions, record, id)
    local definition
    local ok
    local actionable
    local metadata
    if not definitions or type(definitions.Get) ~= "function"
        or type(definitions.Evaluate) ~= "function"
    then
        return nil
    end
    definition = definitions.Get(id)
    if not definition then return nil end
    ok, actionable, metadata = pcall(
        definitions.Evaluate, definition, record, false)
    if not ok or actionable ~= true then return nil end
    metadata = type(metadata) == "table" and metadata or {}
    return {
        id = id,
        kind = NEED_KIND[id] or "social",
        value = number(metadata.value, 0),
        urgency = number(metadata.urgency, number(metadata.value, 0)),
        critical = tostring(metadata.precedence or "")
            == "CRITICAL_NEED",
        precedence = text(metadata.precedence, "NORMAL_NEED", 32),
    }
end

local function needProfile(record)
    local definitions = PNC.NeedFacilityTriggerDefinitions
    local candidates = {}
    local candidate
    local best
    for index = 1, #NEED_ORDER do
        candidate = evaluateNeed(definitions, record, NEED_ORDER[index])
        if candidate then candidates[#candidates + 1] = candidate end
    end
    table.sort(candidates, function(left, right)
        if left.critical ~= right.critical then return left.critical end
        if left.urgency ~= right.urgency then
            return left.urgency > right.urgency
        end
        if left.value ~= right.value then return left.value > right.value end
        return tostring(left.id) < tostring(right.id)
    end)
    best = candidates[1]
    if best then
        best.reason = "need_" .. tostring(best.kind)
        return best
    end
    return {
        id = "social",
        kind = "social",
        value = 0,
        urgency = 0,
        critical = false,
        precedence = "NORMAL_NEED",
        reason = "social_rotation",
    }
end

local function matches(profile, zone)
    local capabilities = zone and zone.capabilities or {}
    if profile.kind == "sleep" then return capabilities.sleep == true end
    if profile.kind == "water" then return capabilities.water == true end
    if profile.kind == "food" then return capabilities.food == true end
    return capabilities.social == true
end

local function preferredRoomBonus(profile, zone)
    local roomType = tostring(zone and zone.roomType or "")
    if profile.kind == "sleep" then
        if roomType == "BEDROOM" then return 700 end
        if zone.capabilities and zone.capabilities.sleep then return 500 end
    elseif profile.kind == "water" then
        if zone.capabilities and zone.capabilities.water then return 900 end
    elseif profile.kind == "food" then
        if roomType == "KITCHEN" then return 700 end
        if roomType == "DINING_ROOM" then return 500 end
    else
        if roomType == "LIVING_ROOM" then return 700 end
        if roomType == "KITCHEN" or roomType == "DINING_ROOM" then
            return 450
        end
        if zone.capabilities and zone.capabilities.seating then return 180 end
    end
    return 0
end

local function assignmentScore(profile, zone, occupancy, rootSite)
    local score = 0
    if matches(profile, zone) then score = score + 2000 end
    score = score + preferredRoomBonus(profile, zone)
    if (tonumber(occupancy) or 0) == 0 then score = score + 350 end
    score = score - (tonumber(occupancy) or 0) * 400
    score = score - math.sqrt(siteDistanceSq(zone, rootSite))
    return score
end

local function bestZone(profile, directory, occupancy, rootSite)
    local best
    local bestScore
    local zone
    local score
    local hasMatch = false
    for index = 1, #directory.zones do
        if matches(profile, directory.zones[index]) then
            hasMatch = true
            break
        end
    end
    for index = 1, #directory.zones do
        zone = directory.zones[index]
        if not hasMatch or matches(profile, zone) then
            score = assignmentScore(profile, zone,
                occupancy[tostring(zone.siteID or "")] or 0, rootSite)
            if not best or score > bestScore
                or (score == bestScore
                    and tostring(zone.siteID or "")
                        < tostring(best.siteID or ""))
            then
                best = zone
                bestScore = score
            end
        end
    end
    return best, bestScore, hasMatch
end

local function sortRecords(records, profiles)
    table.sort(records, function(left, right)
        local leftProfile = profiles[tostring(left.id or "")]
        local rightProfile = profiles[tostring(right.id or "")]
        if leftProfile.critical ~= rightProfile.critical then
            return leftProfile.critical
        end
        if leftProfile.urgency ~= rightProfile.urgency then
            return leftProfile.urgency > rightProfile.urgency
        end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
end

local function nextRuntimeSequence()
    local sequence = tonumber(Service.Runtime.sequence) or 0
    if sequence >= 2147483646 then
        sequence = 1
    else
        sequence = sequence + 1
    end
    Service.Runtime.sequence = sequence
    return sequence
end

local function pruneRuntime(currentID)
    local camps = Service.Runtime.camps
    local maximum = math.max(1, math.floor(number(
        Service.MAX_RETAINED_CAMPS, 32)))
    local count = 0
    local oldestID
    local oldestUse
    local oldestKey
    local key
    local directory
    local use
    for key, directory in pairs(camps) do
        if type(directory) == "table" then
            count = count + 1
        else
            camps[key] = nil
        end
    end
    while count > maximum do
        oldestID = nil
        oldestUse = nil
        oldestKey = nil
        for key, directory in pairs(camps) do
            if tostring(key) ~= tostring(currentID)
                and type(directory) == "table"
            then
                use = tonumber(directory.lastUsed) or 0
                if not oldestID or use < oldestUse
                    or use == oldestUse
                        and tostring(key) < tostring(oldestKey)
                then
                    oldestID = key
                    oldestUse = use
                    oldestKey = key
                end
            end
        end
        if not oldestID then break end
        camps[oldestID] = nil
        count = count - 1
    end
end

local function retainRuntime(campID, directory)
    directory.lastUsed = nextRuntimeSequence()
    Service.Runtime.camps[campID] = directory
    pruneRuntime(campID)
end

function Service.BuildGroup(rootSite, records, options)
    local directory
    local roomsByID
    local cell
    local rootRoom
    local root
    local occupancy = {}
    local assignments
    local profiles = {}
    local previous
    local campID
    local revision
    local orderedRecords = {}
    options = type(options) == "table" and options or {}
    if type(rootSite) ~= "table" or type(records) ~= "table"
        or #records == 0
    then
        return nil, "camp_zone_input_invalid"
    end
    root = copySite(rootSite)
    root.siteID = zoneID(root)
    campID = tostring(options.campId or "camp")
    previous = Service.Runtime.camps[campID]
    revision = (tonumber(previous and previous.revision) or 0) + 1
    directory, roomsByID, cell, rootRoom = discoverZones(
        root, options)
    directory.version = Service.VERSION
    directory.campId = campID
    directory.revision = revision
    directory.createdAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    directory.source = "server_loaded_rooms"
    directory.rootSite = copySite(root)
    enrichZones(directory, roomsByID, cell, rootRoom, records[1])
    assignments = directory.assignments
    for index = 1, #records do
        orderedRecords[index] = records[index]
        profiles[tostring(records[index].id or "")] =
            needProfile(records[index])
    end
    sortRecords(orderedRecords, profiles)
    for index = 1, #orderedRecords do
        local record = orderedRecords[index]
        local profile = profiles[tostring(record.id or "")]
        local zone
        local score
        local hasMatch
        local id = tostring(record.id or "")
        zone, score, hasMatch = bestZone(
            profile, directory, occupancy, root)
        if zone and id ~= "" then
            local zoneKey = tostring(zone.siteID or "")
            occupancy[zoneKey] = (tonumber(occupancy[zoneKey]) or 0) + 1
            zone.occupancy = occupancy[zoneKey]
            assignments[id] = {
                npcID = id,
                zoneID = zoneKey,
                zoneLabel = text(zone.label, "room", 64),
                zone = copySite(zone),
                needKind = profile.kind,
                needValue = profile.value,
                urgency = profile.urgency,
                critical = profile.critical,
                reason = hasMatch and profile.reason
                    or "fallback_no_" .. tostring(profile.kind) .. "_zone",
                score = score,
                assignmentRevision = revision,
            }
        elseif id ~= "" then
            directory.rejected[id] = "no_loaded_zone"
        end
    end
    directory.zoneCount = #directory.zones
    directory.targetCount = #records
    -- Remove the temporary dedupe table before exposing the directory to any
    -- debug projection or future caller.
    retainRuntime(campID, directory)
    return directory
end

function Service.Get(campID)
    local directory = Service.Runtime.camps[tostring(campID or "")]
    if directory then directory.lastUsed = nextRuntimeSequence() end
    return directory
end

function Service.GetAssignment(campID, npcID)
    local directory = Service.Get(campID)
    return directory and directory.assignments
        and directory.assignments[tostring(npcID or "")] or nil
end

function Service.Release(campID)
    Service.Runtime.camps[tostring(campID or "")] = nil
    return true
end

return Service
