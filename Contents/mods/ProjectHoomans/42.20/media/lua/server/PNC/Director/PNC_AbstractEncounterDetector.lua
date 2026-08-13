-- Shared-location collision detection, persistent report creation, and queueing.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounters = PNC.AbstractEncounters or {}

local Encounters = PNC.AbstractEncounters
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Config = PNC.DirectorConfig
local Resolver = PNC.AbstractEncounterResolver

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

function Encounters.TrimHistory()
    local reports = Store.Registry.encounters
    while #reports > Config.ENCOUNTER_HISTORY_LIMIT do
        local removable
        for index, existing in ipairs(reports) do
            if existing.outcome ~= "QUEUED" then removable = index break end
        end
        if not removable then break end
        table.remove(reports, removable)
    end
end

local function append(report)
    local reports = Store.Registry.encounters
    reports[#reports + 1] = report
    Encounters.TrimHistory()
    Store.Touch("abstract_encounter_detected")
    Store.Emit("ABSTRACT_ENCOUNTER_STARTED", report)
end

function Encounters.Create(location, firstGroup, secondGroup, at)
    if not location or not firstGroup or not secondGroup
        or firstGroup.id == secondGroup.id
    then return nil, "invalid_participants" end
    at = tonumber(at) or Store.WorldAgeHours()
    local participants = { firstGroup.id, secondGroup.id }
    table.sort(participants)
    local pairKey = location.id .. ":" .. table.concat(participants, ":")
    local playerNearby = Encounters.IsPlayerNearby(location)
    local cooldownUntil = Store.Registry.encounterCooldowns[pairKey] or 0
    if not playerNearby and at < cooldownUntil then return nil, "pair_cooldown" end
    local cooldownCount = 0
    for key, expiry in pairs(Store.Registry.encounterCooldowns) do
        if expiry <= at then Store.Registry.encounterCooldowns[key] = nil
        else cooldownCount = cooldownCount + 1 end
    end
    if cooldownCount >= Config.ENCOUNTER_HISTORY_LIMIT * 4 then
        local oldestKey, oldestExpiry
        for key, expiry in pairs(Store.Registry.encounterCooldowns) do
            if not oldestExpiry or expiry < oldestExpiry then
                oldestKey, oldestExpiry = key, expiry
            end
        end
        if oldestKey then Store.Registry.encounterCooldowns[oldestKey] = nil end
    end
    Store.Registry.encounterCooldowns[pairKey] = at
        + Config.EncounterQueue.PAIR_COOLDOWN_HOURS
    local serial = Store.Registry.nextEncounterSerial
    Store.Registry.nextEncounterSerial = serial + 1
    local id = "encounter_" .. tostring(serial)
    local report = {
        id = id,
        timestamp = at,
        locationId = location.id,
        participants = participants,
        initiatorId = firstGroup.id,
        targetId = secondGroup.id,
        encounterType = "GROUP_COLLISION",
        decisions = {},
        outcome = playerNearby and "MATERIALIZATION_REQUIRED" or "QUEUED",
        reasonEnded = playerNearby and "PLAYER_OBSERVATION_SAFETY"
            or "AWAITING_RESOLUTION",
        seed = deterministicSeed(location.id .. ":"
            .. table.concat(participants, ":") .. ":"
            .. tostring(math.floor(at * 60 + 0.5))),
        abstractResolutionAllowed = not playerNearby,
    }
    append(report)
    if playerNearby then
        Store.Emit("GROUP_MATERIALIZATION_REQUESTED", {
            encounterId = id, locationId = location.id,
            participantIds = participants,
        })
    else Resolver.Enqueue(report) end
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
