-- Room collection enumeration used by semantic camp and perception adapters.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" or type(Internal.Values) ~= "function" then
    error("camp-site room enumeration requires runtime access")
end

local call = Internal.Call
local field = Internal.Field
local values = Internal.Values
local roomDefFor = Internal.RoomDefFor
local buildingFor = Internal.BuildingFor
local buildingDefinition = Internal.BuildingDefinition

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

return Geometry
