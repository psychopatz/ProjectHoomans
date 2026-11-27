-- Shared-location collision detection, persistent report creation, and queueing.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounters = PNC.AbstractEncounters or {}

local Encounters = PNC.AbstractEncounters
local Store = PNC.HoomansWorldView
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Config = PNC.DirectorConfig
local Resolver = PNC.AbstractEncounterResolver

local function getWorldSeed()
    local cg = PsychopatzCore and PsychopatzCore.SurvivorWorld
        and PsychopatzCore.SurvivorWorld.CorridorGraph or nil
    if cg and type(cg.GetWorldSeed) == "function" then
        return tonumber(cg.GetWorldSeed()) or 0
    end
    if Store and type(Store.WorldSeed) == "function" then
        return tonumber(Store.WorldSeed()) or 0
    end
    return 0
end

local function deterministicSeed(text)
    local hash = (2166136261 + math.floor(getWorldSeed())) % 2147483647
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

Encounters.CORRIDOR_CELL_SIZE = 48
Encounters.CORRIDOR_COLLISION_RADIUS = 36

local function cellKey(cx, cy)
    return tostring(cx) .. ":" .. tostring(cy)
end

-- Coarse 48-tile cell hash over TRAVELING AI groups and abstracted traveling
-- player colonists so mid-route encounters trigger off-camera at O(N) cost.
function Encounters.ScanTravelingCollisions(at, maxCollisions)
    at = tonumber(at) or (Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0)
    maxCollisions = math.max(1, math.floor(tonumber(maxCollisions) or 4))
    local cellSize = Encounters.CORRIDOR_CELL_SIZE
    local radiusSq = Encounters.CORRIDOR_COLLISION_RADIUS * Encounters.CORRIDOR_COLLISION_RADIUS
    local grid = {}
    local entries = {}

    local function addEntry(entry)
        local cx = math.floor(entry.x / cellSize)
        local cy = math.floor(entry.y / cellSize)
        entry.cx = cx
        entry.cy = cy
        local key = cellKey(cx, cy)
        grid[key] = grid[key] or {}
        grid[key][#grid[key] + 1] = entry
        entries[#entries + 1] = entry
    end

    if Groups and type(Groups.List) == "function" then
        for _, group in ipairs(Groups.List()) do
            if type(group) == "table" and group.state == "TRAVELING" and type(group.journey) == "table" then
                local gx = tonumber(group.journey.x) or (group.location and tonumber(group.location.x))
                local gy = tonumber(group.journey.y) or (group.location and tonumber(group.location.y))
                if gx and gy then
                    addEntry({ kind = "group", id = tostring(group.id), x = gx, y = gy, group = group })
                end
            end
        end
    end

    if PNC.Registry and type(PNC.Registry.List) == "function" then
        for _, record in ipairs(PNC.Registry.List()) do
            if type(record) == "table"
                and record.alive ~= false
                and record.recruited == true
                and record.presenceState ~= (PNC.Const and PNC.Const.PRESENCE_LIVE)
                and type(record.travel) == "table"
                and record.travel.state == "en_route"
                and tonumber(record.x) and tonumber(record.y)
            then
                addEntry({ kind = "colonist", id = "col:" .. tostring(record.id), x = record.x, y = record.y, record = record })
            end
        end
    end

    local seenPairs = {}
    local reports = {}
    for i = 1, #entries do
        if #reports >= maxCollisions then break end
        local a = entries[i]
        for dxCell = -1, 1 do
            for dyCell = -1, 1 do
                local bucket = grid[cellKey(a.cx + dxCell, a.cy + dyCell)]
                if bucket then
                    for j = 1, #bucket do
                        if #reports >= maxCollisions then break end
                        local b = bucket[j]
                        if a.id < b.id then
                            local pk = a.id .. "|" .. b.id
                            if not seenPairs[pk] then
                                seenPairs[pk] = true
                                local dx = a.x - b.x
                                local dy = a.y - b.y
                                if (dx * dx + dy * dy) <= radiusSq then
                                    local midX = math.floor((a.x + b.x) * 0.5 + 0.5)
                                    local midY = math.floor((a.y + b.y) * 0.5 + 0.5)
                                    local corridorLoc = {
                                        id = "corridor_" .. tostring(a.cx) .. "_" .. tostring(a.cy),
                                        x = midX,
                                        y = midY,
                                        z = 0,
                                        type = "ROAD",
                                    }
                                    if a.kind == "group" and b.kind == "group" then
                                        local report = Encounters.Create(corridorLoc, a.group, b.group, at)
                                        if report then
                                            report.midRoute = true
                                            report.x = midX
                                            report.y = midY
                                            reports[#reports + 1] = report
                                        end
                                    elseif (a.kind == "colonist" and b.kind == "group")
                                        or (a.kind == "group" and b.kind == "colonist")
                                    then
                                        local col = a.kind == "colonist" and a.record or b.record
                                        local grp = a.kind == "group" and a.group or b.group
                                        local nearby = Encounters.IsPlayerNearby(corridorLoc)
                                        if nearby then
                                            Store.Emit("GROUP_MATERIALIZATION_REQUESTED", {
                                                locationId = corridorLoc.id,
                                                x = midX, y = midY,
                                                participantIds = { col.id, grp.id },
                                                midRoute = true,
                                            })
                                            reports[#reports + 1] = {
                                                id = "midroute_col_" .. tostring(col.id) .. "_" .. tostring(grp.id),
                                                outcome = "MATERIALIZATION_REQUIRED",
                                                x = midX, y = midY,
                                                midRoute = true,
                                            }
                                        elseif PNC.AbstractHazardResolver and PNC.AbstractCombatProfile then
                                            local grpProfile = PNC.AbstractCombatProfile.Get(grp, false)
                                            local threatVal = math.max(30, (tonumber(grpProfile and grpProfile.overallPower) or 1) * 28)
                                            local res = PNC.AbstractHazardResolver.ResolveForParticipants(
                                                { col }, midX, midY, at,
                                                {
                                                    entityId = "col_vs_grp:" .. tostring(col.id) .. ":" .. tostring(grp.id),
                                                    isPlayerColonist = true,
                                                    threatOverride = { totalThreat = threatVal },
                                                }
                                            )
                                            reports[#reports + 1] = {
                                                id = "midroute_col_" .. tostring(col.id) .. "_" .. tostring(grp.id),
                                                outcome = res and res.outcome or "CLEAR",
                                                policyOutcome = res and res.policyOutcome or nil,
                                                x = midX, y = midY,
                                                midRoute = true,
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return reports
end

return Encounters
