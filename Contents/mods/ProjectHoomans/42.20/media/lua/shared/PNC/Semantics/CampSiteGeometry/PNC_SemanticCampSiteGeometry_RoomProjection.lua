-- Projects one engine room into the stable primitive camp-site contract.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Internal.BuildRoomIdentity) ~= "function"
    or type(Internal.AnalyzeRoom) ~= "function"
then
    error("camp-site room projection requires room records and analysis")
end

local CampSite = Internal.CampSite
local call = Internal.Call
local roomFor = Internal.RoomFor
local roomDefFor = Internal.RoomDefFor
local buildingFor = Internal.BuildingFor
local roomName = Internal.RoomName
local roomSquares = Internal.RoomSquares
local deriveBounds = Internal.DeriveBounds
local roomIdentity = Internal.BuildRoomIdentity
local analyzeRoom = Internal.AnalyzeRoom

-- Cheap identity/filter projection: RoomDef bounds and names only, no square
-- iteration. Room selection ranks many rooms with this before paying for the
-- full floor analysis on a handful of finalists.
function Geometry.SummarizeRoom(roomLike, building, options)
    options = type(options) == "table" and options or {}
    local room = roomFor(roomLike)
    local definition = roomDefFor(room)
    local actualBuilding = building or buildingFor(room, definition)
    local name = roomName(room, definition)
    local bounds
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
    bounds = deriveBounds(room, definition)
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
    return {
        room = room,
        building = actualBuilding,
        name = name,
        bounds = bounds,
        roomID = roomID,
        buildingID = buildingID,
        roomType = roomType,
    }
end

local function copySlots(slots)
    local output = {}
    for index = 1, #(slots or {}) do
        local slot = slots[index]
        output[index] = { x = slot.x, y = slot.y, z = slot.z }
    end
    return output
end

function Geometry.DescribeRoom(roomLike, building, cell, origin, options)
    local summary, reason = Geometry.SummarizeRoom(roomLike, building, options)
    if not summary then return nil, reason end
    local bounds = summary.bounds
    local analysis = analyzeRoom(summary.room, bounds, cell)
    local anchor = analysis and analysis.anchor
    if not anchor then return nil, "room_no_free_anchor" end
    return {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.ROOM,
        siteScope = CampSite.SCOPES.ROOM,
        siteID = "room:" .. tostring(summary.buildingID or "unknown") .. ":"
            .. tostring(summary.roomID or (bounds.minX .. ":" .. bounds.minY)),
        roomID = summary.roomID,
        buildingID = summary.buildingID,
        roomType = summary.roomType,
        roomName = summary.name,
        roomBounds = bounds,
        x = anchor.x,
        y = anchor.y,
        z = anchor.z,
        -- The anchor is the most open, door-distant reachable floor tile.
        -- `slots` are spaced per-member standing tiles (slot 1 == anchor) so
        -- a group spreads through the room instead of piling at one point.
        movementX = anchor.x,
        movementY = anchor.y,
        movementZ = anchor.z,
        slots = copySlots(analysis.slots),
        capacity = analysis.capacity,
        campCapacity = analysis.campCapacity,
        narrow = analysis.narrow == true,
        exitCount = analysis.exitCount,
        label = CampSite.DisplayLabel({
            scope = CampSite.SCOPES.ROOM,
            roomType = summary.roomType,
            roomName = summary.name,
        }),
        labelKey = "semantic.camp.room",
        risk = "sheltered",
        mode = "walk",
        stopDistance = 0.7,
        radius = 3,
        resourceRadius = 12,
    }
end


return Geometry
