-- Cross-runtime room discovery and identity matching for semantic camps.
--
-- The adapter returns only primitive descriptors. Java room/building/square
-- objects are used briefly during discovery and are never retained in a plan,
-- order, cache, or network payload.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Geometry = PNC.Semantics.CampSiteGeometry or {}
PNC.Semantics.CampSiteGeometry = Geometry
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"

Geometry.VERSION = 1
Geometry.MAX_ROOMS = 128
Geometry.MAX_LOCAL_ROOM_CANDIDATES = 64
Geometry.MAX_ROOM_SQUARES = 512
Geometry.MAX_FALLBACK_SCAN = 4096

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function field(object, name)
    if not object then return nil end
    local ok, value = pcall(function() return object[name] end)
    return ok and value or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
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

local function values(list, maximum)
    local output = {}
    local size = math.min(listSize(list), tonumber(maximum) or 512)
    for index = 0, size - 1 do
        local value = listItem(list, index)
        if value then output[#output + 1] = value end
    end
    return output
end

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ")) or 0
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function cellFor(options)
    options = type(options) == "table" and options or {}
    if options.cell then return options.cell end
    if type(getCell) == "function" then
        local ok, cell = pcall(getCell)
        if ok then return cell end
    end
    return nil
end

function Geometry.GetSquare(cell, x, y, z)
    cell = cell or cellFor()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ix = number(x)
    local iy = number(y)
    local iz = number(z) or 0
    if ix == nil or iy == nil then return nil end
    local ok, square = pcall(cell.getGridSquare, cell,
        math.floor(ix), math.floor(iy), math.floor(iz))
    return ok and square or nil
end

local function roomFor(value)
    if not value then return nil end
    local room = call(value, "getRoom")
    if room then return room end
    room = call(value, "getIsoRoom")
    if room then return room end
    -- IsoGridSquare exposes getRoomDef(), but that is not itself the room.
    -- Prefer an object with room squares so square -> room identity remains
    -- correct for arrival verification and room-scoped resource scans.
    if call(value, "getSquares") or field(value, "squares")
        or field(value, "tileList")
    then
        return value
    end
    return nil
end

local function roomDefFor(value)
    if not value then return nil end
    local definition = call(value, "getRoomDef")
        or field(value, "roomDef")
        or field(value, "def")
    if definition then return definition end
    local room = roomFor(value)
    if room and room ~= value then
        return call(room, "getRoomDef")
            or field(room, "roomDef") or field(room, "def")
    end
    return nil
end

local function buildingFor(room, definition)
    return call(room, "getBuilding")
        or call(definition, "getBuilding")
        or field(room, "building")
end

local function buildingDefinition(building)
    return call(building, "getDef")
        or field(building, "def")
end

local function identifier(value, methods)
    for _, method in ipairs(methods or {}) do
        local result = call(value, method)
        if result ~= nil and tostring(result) ~= "" then
            return tostring(result)
        end
    end
    return nil
end

local function boundsFor(definition)
    local minX = number(call(definition, "getX") or field(definition, "x"))
    local minY = number(call(definition, "getY") or field(definition, "y"))
    local maxX = number(call(definition, "getX2") or field(definition, "x2"))
    local maxY = number(call(definition, "getY2") or field(definition, "y2"))
    local z = number(call(definition, "getZ") or field(definition, "z"))
    if minX == nil or minY == nil or maxX == nil or maxY == nil then
        return nil
    end
    -- RoomDef X2/Y2 are the upper edge in the engine rectangle contract.
    -- Store the last occupied square as an inclusive bound.
    if maxX > minX then maxX = maxX - 1 end
    if maxY > minY then maxY = maxY - 1 end
    return CampSite.NormalizeBounds({
        minX = minX, minY = minY, maxX = maxX, maxY = maxY, z = z,
    })
end

local function roomName(room, definition)
    return text(call(room, "getName")
        or call(definition, "getName")
        or field(room, "name") or field(definition, "name"), 64)
end

local function roomSquares(room)
    return call(room, "getSquares")
        or field(room, "squares")
        or field(room, "tileList")
end

local function isIndoor(square)
    if not square then return false end
    local result = call(square, "isInARoom")
    if result ~= nil then return result == true end
    return call(square, "getRoom") ~= nil
end

local function isUsable(square)
    if not square or not isIndoor(square) then return false end
    local free = call(square, "isFree", true)
    return free ~= false
end

local function roomIdentity(room, definition, building, bounds, name)
    local buildingDef = buildingDefinition(building)
    local roomID = identifier(definition, { "getIDString", "getID" })
        or identifier(room, { "getIDString", "getID" })
    -- BuildingDef ids survive reloads; IsoBuilding ids are runtime-local.
    local buildingID = identifier(buildingDef, { "getIDString", "getID" })
        or identifier(building, { "getID", "getIDString" })
    local roomType = CampSite.ResolveRoomType(name)
    if not roomType then
        roomType = CampSite.ResolveRoomType(identifier(
            definition, { "getIDString", "getID" }))
    end
    return roomID, buildingID, roomType
end

local function deriveBounds(room, definition, squares)
    local bounds = boundsFor(definition)
    if bounds then return bounds end
    local minX
    local minY
    local maxX
    local maxY
    local z
    local size = math.min(listSize(squares), Geometry.MAX_ROOM_SQUARES)
    for index = 0, size - 1 do
        local square = listItem(squares, index)
        local x, y, squareZ = position(square)
        if x and y then
            minX = minX and math.min(minX, x) or x
            minY = minY and math.min(minY, y) or y
            maxX = maxX and math.max(maxX, x) or x
            maxY = maxY and math.max(maxY, y) or y
            z = z or squareZ
        end
    end
    if not minX then return nil end
    return CampSite.NormalizeBounds({
        minX = minX, minY = minY, maxX = maxX, maxY = maxY, z = z,
    })
end

local function anchorFor(room, bounds, cell, origin)
    local originX, originY, originZ = position(origin)
    local best
    local bestDistance
    local squares = roomSquares(room)
    local size = math.min(listSize(squares), Geometry.MAX_ROOM_SQUARES)
    local function consider(square)
        local x, y, z
        local dx
        local dy
        local distance
        if not isUsable(square) then return end
        x, y, z = position(square)
        if not x or not y then return end
        dx = originX and x - originX or 0
        dy = originY and y - originY or 0
        distance = dx * dx + dy * dy
        if not best or distance < bestDistance then
            best = { x = x + 0.5, y = y + 0.5, z = z }
            bestDistance = distance
        end
    end

    -- getFreeTile is cheap and handles room-specific engine constraints. It
    -- is only accepted after the same indoor/free checks as list scanning.
    consider(call(room, "getFreeTile"))
    for index = 0, size - 1 do consider(listItem(squares, index)) end

    if best or not bounds or not cell then return best end
    local minX = math.floor(bounds.minX)
    local minY = math.floor(bounds.minY)
    local maxX = math.floor(bounds.maxX)
    local maxY = math.floor(bounds.maxY)
    local inspected = 0
    for x = minX, maxX do
        for y = minY, maxY do
            if inspected >= Geometry.MAX_FALLBACK_SCAN then return best end
            inspected = inspected + 1
            consider(Geometry.GetSquare(cell, x, y, bounds.z or originZ))
        end
    end
    return best
end

function Geometry.DescribeRoom(roomLike, building, cell, origin, options)
    options = type(options) == "table" and options or {}
    local room = roomFor(roomLike)
    local definition = roomDefFor(room)
    local actualBuilding = building or buildingFor(room, definition)
    local name = roomName(room, definition)
    local bounds
    local anchor
    local roomID
    local buildingID
    local roomType
    local requestedType = CampSite.ResolveRoomType(options.roomType
        or options.query)
    local query = CampSite.NormalizeText(options.query)
    local normalizedName = CampSite.NormalizeText(name)
    if not room then return nil, "room_unavailable" end
    if actualBuilding and call(actualBuilding, "isToxic") == true then
        return nil, "room_toxic"
    end
    bounds = deriveBounds(room, definition, roomSquares(room))
    if not bounds then return nil, "room_bounds_unavailable" end
    roomID, buildingID, roomType = roomIdentity(
        room, definition, actualBuilding, bounds, name)
    if requestedType and roomType ~= requestedType then
        return nil, "room_type_mismatch"
    end
    if query ~= "" and not requestedType then
        if normalizedName == ""
            or (not string.find(normalizedName, query, 1, true)
                and not string.find(query, normalizedName, 1, true))
        then
            return nil, "room_query_mismatch"
        end
    end
    anchor = anchorFor(room, bounds, cell, origin)
    if not anchor then return nil, "room_no_free_anchor" end
    return {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.ROOM,
        siteScope = CampSite.SCOPES.ROOM,
        siteID = "room:" .. tostring(buildingID or "unknown") .. ":"
            .. tostring(roomID or (bounds.minX .. ":" .. bounds.minY)),
        roomID = roomID,
        buildingID = buildingID,
        roomType = roomType,
        roomName = name,
        roomBounds = bounds,
        x = anchor.x,
        y = anchor.y,
        z = anchor.z,
        label = CampSite.RoomLabel(roomType, name),
        labelKey = "semantic.camp.room",
        risk = "sheltered",
        mode = "walk",
        stopDistance = 0.7,
        radius = 3,
        resourceRadius = 12,
    }
end

function Geometry.EnumerateRooms(cell, callback, options)
    options = type(options) == "table" and options or {}
    local roomList = cell and call(cell, "getRoomList") or nil
    local roomValues = values(roomList, options.maxRooms or Geometry.MAX_ROOMS)
    local count = 0
    for _, room in ipairs(roomValues) do
        local definition = roomDefFor(room)
        local building = buildingFor(room, definition)
        if not building or call(building, "isToxic") ~= true then
            count = count + 1
            if type(callback) == "function" then
                callback(room, building, count)
            end
            if count >= Geometry.MAX_ROOMS then return count end
        end
    end
    if count > 0 then return count end

    local buildings = cell and call(cell, "getBuildingList") or nil
    local buildingValues = values(buildings, options.maxBuildings or 128)
    for _, building in ipairs(buildingValues) do
        if call(building, "isToxic") ~= true then
            local definition = buildingDefinition(building)
            local rooms = call(building, "getRooms")
                or field(building, "rooms")
                or call(definition, "getRooms")
            for _, room in ipairs(values(rooms, Geometry.MAX_ROOMS)) do
                count = count + 1
                if type(callback) == "function" then
                    callback(room, building, count)
                end
                if count >= Geometry.MAX_ROOMS then return count end
            end
        end
    end
    return count
end

local function candidateQuery(query)
    if type(query) ~= "table" then
        return CampSite.ResolveRoomType(query), CampSite.NormalizeText(query)
    end
    return CampSite.ResolveRoomType(query.roomType or query.concept or query.text),
        CampSite.NormalizeText(query.text or query.value or query.roomQuery)
end

function Geometry.FindNearestRoom(cell, origin, query, options)
    options = type(options) == "table" and options or {}
    cell = cell or cellFor(options)
    local originX, originY, originZ = position(origin)
    local wantedType, wantedText = candidateQuery(query)
    local maximum = math.max(4, math.min(64,
        number(options.radius) or 32))
    local best
    local bestScore
    local bestDistance
    local originSquare = origin and call(origin, "getCurrentSquare")
        or (originX and Geometry.GetSquare(cell, originX, originY, originZ))
    local originRoom = originSquare and roomFor(originSquare) or nil
    local originRoomDef = originRoom and roomDefFor(originRoom) or nil
    local originRoomID = identifier(originRoomDef, { "getIDString", "getID" })

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
    local seenRooms = {}
    local localRoomCandidates = 0
    local localRoomLimit = math.max(1, math.min(
        Geometry.MAX_LOCAL_ROOM_CANDIDATES,
        math.floor(number(options.maxLocalRooms)
            or Geometry.MAX_LOCAL_ROOM_CANDIDATES)))

    local function considerRoom(room, building)
        local site
        local dx
        local dy
        local distance
        local sameRoom
        local preferred
        local score
        if not room or seenRooms[room] then return end
        seenRooms[room] = true
        site = Geometry.DescribeRoom(room, building, cell, origin, {
            roomType = wantedType,
            query = wantedText,
        })
        if not site then return end
        dx = site.x - originX
        dy = site.y - originY
        distance = math.sqrt(dx * dx + dy * dy)
        sameRoom = originRoomID ~= nil
            and tostring(site.roomID or "") == tostring(originRoomID)
        preferred = options.preferredSiteID
            and tostring(site.siteID or "")
                == tostring(options.preferredSiteID)
            or options.preferredRoomID
            and tostring(site.roomID or "")
                == tostring(options.preferredRoomID)
        if math.abs(site.z - originZ) > 1 or distance > maximum then
            return
        end
        score = distance
        if sameRoom then score = score - 1000 end
        if preferred then score = score - 100 end
        if call(building, "isResidential") == true then score = score - 2 end
        if not best or score < bestScore
            or score == bestScore
                and tostring(site.siteID) < tostring(best.siteID)
        then
            best = site
            bestScore = score
            bestDistance = distance
        end
    end

    local function inspectNearbySquare(x, y)
        local square = Geometry.GetSquare(cell, x, y, originZ)
        local room = roomFor(square)
        if room and not seenRooms[room]
            and localRoomCandidates < localRoomLimit
        then
            localRoomCandidates = localRoomCandidates + 1
            considerRoom(room, buildingFor(room, roomDefFor(room)))
        end
    end

    local baseX = math.floor(originX)
    local baseY = math.floor(originY)
    for ring = 0, math.floor(maximum) do
        if ring == 0 then
            inspectNearbySquare(baseX, baseY)
        else
            for dx = -ring, ring do
                inspectNearbySquare(baseX + dx, baseY - ring)
                inspectNearbySquare(baseX + dx, baseY + ring)
            end
            for dy = -ring + 1, ring - 1 do
                inspectNearbySquare(baseX - ring, baseY + dy)
                inspectNearbySquare(baseX + ring, baseY + dy)
            end
        end
    end

    -- A local scan is enough for the normal visible-house case. Retain the
    -- bounded room-list/building fallback for rooms whose loaded squares do
    -- not expose room identity on this engine/version.
    if best then
        best.distance = bestDistance
        best.selectionScore = bestScore
        return best
    end

    Geometry.EnumerateRooms(cell, function(room, building)
        considerRoom(room, building)
    end, options)
    if not best then return nil, "room_not_found" end
    best.distance = bestDistance
    best.selectionScore = bestScore
    return best
end

function Geometry.RoomIdentity(square)
    if not square or not isIndoor(square) then return nil end
    local room = roomFor(square)
    local definition = roomDefFor(room)
    local building = buildingFor(room, definition)
    local bounds = deriveBounds(room, definition, roomSquares(room))
    local name = roomName(room, definition)
    local roomID, buildingID, roomType = roomIdentity(
        room, definition, building, bounds, name)
    local x, y, z = position(square)
    return {
        roomID = roomID,
        buildingID = buildingID,
        roomType = roomType,
        roomName = name,
        roomBounds = bounds,
        x = x,
        y = y,
        z = z,
    }
end

function Geometry.MatchesRoom(square, site)
    if type(site) ~= "table" or site.scope ~= CampSite.SCOPES.ROOM
        and site.siteScope ~= CampSite.SCOPES.ROOM
    then
        return false
    end
    local identity = Geometry.RoomIdentity(square)
    if not identity then return false end
    if site.buildingID and identity.buildingID
        and tostring(site.buildingID) ~= tostring(identity.buildingID)
    then
        return false
    end
    if site.roomID and identity.roomID then
        return tostring(site.roomID) == tostring(identity.roomID)
    end
    if site.roomType and identity.roomType
        and tostring(site.roomType) ~= tostring(identity.roomType)
    then
        return false
    end
    if site.roomBounds then
        return CampSite.BoundsContain(site.roomBounds,
            identity.x, identity.y, identity.z)
    end
    return site.roomType == nil or identity.roomType == site.roomType
end

-- Shared primitive membership check for camp activity and resource targets.
-- Room sites are area/identity based; campfire sites retain their bounded
-- Euclidean radius. Java objects are optional and are only consulted when a
-- live square is available.
function Geometry.ContainsPoint(site, x, y, z, options)
    options = type(options) == "table" and options or {}
    if type(site) ~= "table" then return false end
    x, y, z = number(x), number(y), number(z) or 0
    if x == nil or y == nil then return false end

    local scope = CampSite.NormalizeScope(site.scope or site.siteScope)
    if not scope then
        scope = site.roomBounds and CampSite.SCOPES.ROOM
            or CampSite.SCOPES.CAMPFIRE
    end
    if scope == CampSite.SCOPES.ROOM then
        if not CampSite.BoundsContain(site.roomBounds,
            math.floor(x), math.floor(y), z)
        then
            return false
        end
        if options.checkRoomIdentity ~= false then
            local square = options.square
                or Geometry.GetSquare(options.cell, x, y, z)
            if square and not Geometry.MatchesRoom(square, site) then
                return false
            end
        end
        return true
    end
    if scope == CampSite.SCOPES.CAMPFIRE then
        local anchorX = number(site.x)
        local anchorY = number(site.y)
        local anchorZ = number(site.z) or 0
        local radius = number(options.radius)
            or number(site.radius) or 3
        if anchorX == nil or anchorY == nil
            or math.abs(z - anchorZ) > 0.5
        then
            return false
        end
        local dx, dy = x - anchorX, y - anchorY
        return dx * dx + dy * dy
            <= (radius + 0.5) * (radius + 0.5)
    end
    return false
end

Geometry._Internal = Geometry._Internal or {}
Geometry._Internal.Call = call
Geometry._Internal.Position = position
Geometry._Internal.RoomFor = roomFor
Geometry._Internal.RoomDefFor = roomDefFor
Geometry._Internal.BoundsFor = boundsFor

return Geometry
