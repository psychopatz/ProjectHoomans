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

function H.EnsureIndex()
    if Locations.IndexedRevision < 0 then Locations.RebuildIndex() end
end

function Locations.Get(locationID)
    Store.EnsureLoaded()
    return Store.Registry.locationsByID[tostring(locationID or "")]
end

function Locations.List()
    Store.EnsureLoaded()
    local output = {}
    for _, location in pairs(Store.Registry.locationsByID) do
        output[#output + 1] = location
    end
    table.sort(output, function(a, b) return a.id < b.id end)
    return output
end

return Locations

