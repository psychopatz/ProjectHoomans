-- Shared-location encounter detection only. Resolution is intentionally deferred.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractEncounters = PNC.AbstractEncounters or {}

local Encounters = PNC.AbstractEncounters
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Config = PNC.DirectorConfig

local function deterministicSeed(text)
    local hash = 2166136261
    text = tostring(text or "")
    for index = 1, #text do
        hash = (hash * 16777619 + string.byte(text, index)) % 2147483647
    end
    return hash
end

function Encounters.IsPlayerNearby(location, radius)
    radius = tonumber(radius) or Config.ACTIVE_SIMULATION_RADIUS
    local candidates = PNC.SpatialIndex and PNC.SpatialIndex.QueryPlayers
        and PNC.SpatialIndex.QueryPlayers(location.x, location.y, radius) or {}
    for _, player in ipairs(candidates) do
        if player and player.getX and player.getY then
            local dx, dy = player:getX() - location.x,
                player:getY() - location.y
            if dx * dx + dy * dy <= radius * radius then return true end
        end
    end
    return false
end

local function append(report)
    local reports = Store.Registry.encounters
    reports[#reports + 1] = report
    while #reports > Config.ENCOUNTER_HISTORY_LIMIT do table.remove(reports, 1) end
    Store.Touch("abstract_encounter_detected")
    Store.Emit("ABSTRACT_ENCOUNTER_STARTED", report)
end

function Encounters.Create(location, firstGroup, secondGroup, at)
    if not location or not firstGroup or not secondGroup
        or firstGroup.id == secondGroup.id
    then return nil, "invalid_participants" end
    local serial = Store.Registry.nextEncounterSerial
    Store.Registry.nextEncounterSerial = serial + 1
    local id = "encounter_" .. tostring(serial)
    local participants = { firstGroup.id, secondGroup.id }
    table.sort(participants)
    local playerNearby = Encounters.IsPlayerNearby(location)
    local report = {
        id = id,
        timestamp = tonumber(at) or Store.WorldAgeHours(),
        locationId = location.id,
        participants = participants,
        encounterType = "GROUP_COLLISION",
        decisions = {},
        outcome = playerNearby and "MATERIALIZATION_REQUIRED" or "DETECTED",
        reasonEnded = playerNearby and "PLAYER_OBSERVATION_SAFETY"
            or "RESOLUTION_DEFERRED",
        seed = deterministicSeed(id .. ":" .. table.concat(participants, ":")),
        abstractResolutionAllowed = not playerNearby,
    }
    append(report)
    if playerNearby then
        Store.Emit("GROUP_MATERIALIZATION_REQUESTED", {
            encounterId = id, locationId = location.id,
            participantIds = participants,
        })
    end
    return report, report.outcome
end

function Encounters.DetectAt(locationOrID, arrivingGroupOrID, at)
    local location = type(locationOrID) == "table" and locationOrID
        or Locations.Get(locationOrID)
    local group = type(arrivingGroupOrID) == "table" and arrivingGroupOrID
        or Groups.Get(arrivingGroupOrID)
    if not location or not group then return {}, "invalid_context" end
    local output = {}
    for _, occupant in ipairs(Locations.GetGroupOccupants(location, group.id)) do
        local other = Groups.Get(occupant.groupId)
        if other then
            local report = Encounters.Create(location, group, other, at)
            if report then output[#output + 1] = report end
        end
    end
    return output, #output > 0 and "detected" or "none"
end

return Encounters
