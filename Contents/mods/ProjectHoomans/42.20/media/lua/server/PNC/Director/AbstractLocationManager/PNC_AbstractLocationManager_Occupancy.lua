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

function Locations.ReconcileOccupancy()
    Store.EnsureLoaded()
    local expected = {}
    for _, group in pairs(Store.Registry.groupsByID) do
        local lod = group.simulation and group.simulation.lod or "ABSTRACT"
        if lod == "ABSTRACT" and group.state ~= "TRAVELING"
            and group.state ~= "ACTIVE" and group.location
            and Store.Registry.locationsByID[group.location.id]
        then
            expected[group.location.id] = expected[group.location.id] or {}
            expected[group.location.id][group.id] = true
        end
    end
    local changed = false
    for _, location in pairs(Store.Registry.locationsByID) do
        local occupants = location.occupants.groups
        for groupID in pairs(occupants) do
            if not (expected[location.id] and expected[location.id][groupID]) then
                occupants[groupID] = nil
                changed = true
            end
        end
        for groupID in pairs(expected[location.id] or {}) do
            if not occupants[groupID] then
                occupants[groupID] = { arrivedAt = Store.WorldAgeHours(),
                    plannedDepartureAt = 0 }
                changed = true
            end
        end
    end
    if changed then Store.Touch("occupancy_reconciled") end
    return changed
end

function Locations.Depart(group, at)
    local location = group and group.location and Locations.Get(group.location.id)
    local visit = location and location.occupants.groups[group.id] or nil
    if not visit then return false end
    location.occupants.groups[group.id] = nil
    location.visitHistory[#location.visitHistory + 1] = {
        groupId = group.id, arrivedAt = visit.arrivedAt,
        departedAt = tonumber(at) or Store.WorldAgeHours(),
    }
    while #location.visitHistory > Config.OCCUPANCY_HISTORY_LIMIT do
        table.remove(location.visitHistory, 1)
    end
    location.revision = location.revision + 1
    Store.Touch("group_departed")
    return true
end

function Locations.Arrive(group, at, plannedDepartureAt)
    local location = group and group.location and Locations.Get(group.location.id)
    if not location then return nil, "location_not_found" end
    location.occupants.groups[group.id] = {
        arrivedAt = tonumber(at) or Store.WorldAgeHours(),
        plannedDepartureAt = tonumber(plannedDepartureAt) or 0,
    }
    location.revision = location.revision + 1
    Store.Touch("group_arrived")
    return location, "arrived"
end

function Locations.GetGroupOccupants(locationOrID, excludeGroupID)
    local location = type(locationOrID) == "table" and locationOrID
        or Locations.Get(locationOrID)
    local output = {}
    for groupID, visit in pairs(location and location.occupants.groups or {}) do
        if groupID ~= excludeGroupID then
            output[#output + 1] = { groupId = groupID, visit = visit }
        end
    end
    table.sort(output, function(a, b) return a.groupId < b.groupId end)
    return output
end

return Locations

