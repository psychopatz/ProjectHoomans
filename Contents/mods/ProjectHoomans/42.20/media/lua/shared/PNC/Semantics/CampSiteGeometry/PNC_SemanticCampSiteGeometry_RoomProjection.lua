-- Projects one engine room into the stable primitive camp-site contract.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Internal.BuildRoomIdentity) ~= "function" then
    error("camp-site room projection requires room records")
end

local CampSite = Internal.CampSite
local call = Internal.Call
local number = Internal.Number
local listSize = Internal.ListSize
local listItem = Internal.ListItem
local position = Internal.Position
local roomFor = Internal.RoomFor
local roomDefFor = Internal.RoomDefFor
local buildingFor = Internal.BuildingFor
local roomName = Internal.RoomName
local roomSquares = Internal.RoomSquares
local isUsable = Internal.IsUsable
local deriveBounds = Internal.DeriveBounds
local roomIdentity = Internal.BuildRoomIdentity

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
        if not isUsable(square, cell) then return end
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
        -- Keep the movement point explicit. The room identity/label is the
        -- semantic contract; this is only the bounded server/client walking
        -- anchor chosen from the room's usable tiles.
        movementX = anchor.x,
        movementY = anchor.y,
        movementZ = anchor.z,
        label = CampSite.RoomLabel(roomType, name),
        labelKey = "semantic.camp.room",
        risk = "sheltered",
        mode = "walk",
        stopDistance = 0.7,
        radius = 3,
        resourceRadius = 12,
    }
end


return Geometry
