if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}
PNC.AbstractLocationManagerInternal =
    PNC.AbstractLocationManagerInternal or {}

local Locations = PNC.AbstractLocations
local H = PNC.AbstractLocationManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

Locations.Cells = Locations.Cells or {}
Locations.Membership = Locations.Membership or {}
Locations.IndexedRevision = Locations.IndexedRevision or -1
Locations.DiscoveryCursor = Locations.DiscoveryCursor or 0
Locations.LastMetaDiscovery = Locations.LastMetaDiscovery or nil

function H.Authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function H.CellKey(x, y)
    local size = Config.LOCATION_CELL_SIZE
    return tostring(math.floor((tonumber(x) or 0) / size)) .. ":"
        .. tostring(math.floor((tonumber(y) or 0) / size))
end

function H.Ref(location)
    return location and { id = location.id, type = location.type,
        x = location.x, y = location.y, z = location.z } or nil
end

function H.Index(location)
    local key = H.CellKey(location.x, location.y)
    Locations.Cells[key] = Locations.Cells[key] or {}
    Locations.Cells[key][location.id] = location
    Locations.Membership[location.id] = key
end

function Locations.RebuildIndex()
    Store.EnsureLoaded()
    Locations.Cells, Locations.Membership = {}, {}
    for _, location in pairs(Store.Registry.locationsByID) do H.Index(location) end
    Locations.IndexedRevision = Store.Registry.revision
end

Locations.Ref = H.Ref

return Locations

