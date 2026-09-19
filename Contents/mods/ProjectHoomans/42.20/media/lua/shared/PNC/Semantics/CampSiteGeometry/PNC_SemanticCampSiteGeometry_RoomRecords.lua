-- Converts engine room objects into bounded primitive room identity data.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Internal.Call) ~= "function" then
    error("camp-site room records require runtime access")
end

local CampSite = Internal.CampSite
local call = Internal.Call
local field = Internal.Field
local number = Internal.Number
local text = Internal.Text
local listSize = Internal.ListSize
local listItem = Internal.ListItem
local position = Internal.Position

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

local function isUsable(square, cell)
    local traversal
    local x
    local y
    local z
    local ok
    local reason
    if not square or not isIndoor(square) then return false end
    -- Geometry is loaded before the traversal package, so consult it lazily
    -- when available. This keeps the semantic module load-order safe while
    -- preventing a merely `isFree(true)` tile (for example a furniture or
    -- dynamic-occupancy edge case) from becoming a movement anchor.
    traversal = PNC.TraversalQuery
    if traversal and type(traversal.GetOccupancyReason) == "function" then
        x, y, z = position(square)
        if x ~= nil and y ~= nil then
            ok, reason = pcall(
                traversal.GetOccupancyReason,
                x + 0.5,
                y + 0.5,
                z or 0,
                cell
            )
            if ok and reason ~= nil then return false end
        end
    end
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


Internal.RoomFor = roomFor
Internal.RoomDefFor = roomDefFor
Internal.BuildingFor = buildingFor
Internal.BuildingDefinition = buildingDefinition
Internal.Identifier = identifier
Internal.BoundsFor = boundsFor
Internal.RoomName = roomName
Internal.RoomSquares = roomSquares
Internal.IsIndoor = isIndoor
Internal.IsUsable = isUsable
Internal.BuildRoomIdentity = roomIdentity
Internal.DeriveBounds = deriveBounds
Internal.RoomIdentity = Geometry.RoomIdentity
return Geometry
