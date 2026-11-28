if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Traversal = PNC.AbstractTraversal
local H = Traversal.Internal
local Store = PNC.HoomansWorldView
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Actions = PNC.AbstractActions
local ResourceNeeds = PNC.AbstractResourceNeeds
local Config = PNC.DirectorConfig
local ScavengeLedger = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"
local RoutePlanner = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local Diplomacy = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiplomacy"

function H.ResourceValue(group, location)
    return ResourceNeeds.ValuePotential(group, location.resourcePotential or {})
end

function Traversal.ScoreDestination(group, location, distance)
    local tuning = Config.GetArchetype(group.groupType)
    local components = {}
    local resourceScore, resourceNeeds = H.ResourceValue(group, location)
    components.resourceNeeds = resourceNeeds
    components.resources = resourceScore * tuning.resourceWeight
    components.distance = -(tonumber(distance) or 0) / 10 * tuning.distanceWeight
    components.danger = -(tonumber(location.danger) or 0) * tuning.dangerWeight
    components.unvisited = group.visited[location.id]
        and 0 or tuning.unvisitedBonus
    components.tags = 0
    for tag, enabled in pairs(location.tags or {}) do
        if enabled == true then
            components.tags = components.tags
                + (tonumber(tuning.tagWeights[tag]) or 0)
        end
    end
    components.scavenged = -(tonumber(location.scavengedLevel) or 0) * 0.65
    if ScavengeLedger and type(ScavengeLedger.GetDepletion) == "function"
        and location.type ~= "SETTLEMENT"
    then
        local dep = ScavengeLedger.GetDepletion(location.x, location.y, Store.WorldAgeHours())
        if dep >= ScavengeLedger.EXHAUSTED_THRESHOLD then
            components.ledgerDepletion = -180
        elseif dep > 0 then
            components.ledgerDepletion = -(dep * 90)
        end
    end
    local avoidedUntil = group.recentAvoidedLocations
        and group.recentAvoidedLocations[location.id] or 0
    components.recentThreat = avoidedUntil > Store.WorldAgeHours() and -250 or 0
    local loadedReturn = group.homeCommunityId
        and (tonumber(group.carriedSupplies) or 0) >= 24
        and (location.type == "SETTLEMENT" or location.communityId == group.homeCommunityId)
    components.mission = loadedReturn and 120
        or group.mission == "RETURN_HOME"
        and group.homeCommunityId and location.type == "SETTLEMENT" and 40
        or group.mission == "REST" and location.tags.SAFE and 30
        or group.mission == "SCAVENGE" and components.resources * 0.35 or 0
    -- Looters specifically target settlements (both AI and Player) for raids.
    if Diplomacy and Diplomacy.IsLooterType(group.groupType) and location.type == "SETTLEMENT" then
        components.looterRaid = 65
    end
    -- Traders & Caravans prioritize settlements signaling food/water shortages in Core.
    local upType = string.upper(tostring(group.groupType or ""))
    if (upType == "TRADER" or upType == "CARAVAN")
        and location.type == "SETTLEMENT"
        and CorridorGraph and CorridorGraph.State and CorridorGraph.State.anchors
    then
        local cid = location.communityId or location.communityID
            or (location.sourceSite and location.sourceSite.occupantCommunityID)
        local anchor = cid and CorridorGraph.State.anchors[tostring(cid)] or nil
        if anchor then
            if anchor.demandLevel == "critical" then
                components.tradeDemand = 140
            elseif anchor.demandLevel == "shortage" then
                components.tradeDemand = 85
            end
        end
    end
    -- Starving/desperate Refugees or Scavengers push harder toward high-resource targets.
    if Diplomacy and type(Diplomacy.ComputeDesperation) == "function" then
        local desp = Diplomacy.ComputeDesperation(group)
        if desp >= Diplomacy.DESPERATION_HOSTILE_THRESHOLD then
            components.desperation = components.resources * 0.50
        end
    end
    local total = 0
    for _, value in pairs(components) do
        if type(value) == "number" then total = total + value end
    end
    components.final = total
    return total, components
end

function Traversal.ChooseDestination(group)
    if not group or not group.location then return nil, "invalid_group" end
    Locations.DiscoverLoadedNear(group.location.x, group.location.y,
        group.location.z, Config.DESTINATION_QUERY_RADIUS,
        Config.LOADED_BUILDING_DISCOVERY_LIMIT)
    local nearby = Locations.GetNearby(group.location.x, group.location.y,
        Config.DESTINATION_QUERY_RADIUS, Config.DESTINATION_CANDIDATE_LIMIT)
    local best, bestScore, evaluations
    evaluations = {}
    for _, candidate in ipairs(nearby) do
        if candidate.location.id ~= group.location.id then
            local score, components = Traversal.ScoreDestination(
                group, candidate.location, candidate.distance)
            evaluations[#evaluations + 1] = { locationId = candidate.location.id,
                distance = candidate.distance, components = components }
            if not best or score > bestScore
                or score == bestScore and candidate.location.id < best.id
            then best, bestScore = candidate.location, score end
        end
    end
    table.sort(evaluations, function(a, b)
        return a.components.final > b.components.final
    end)
    if (not best or (bestScore and bestScore < -120)) then
        -- Looters stalk the hottest Trader/Scavenger supply corridor when no settlement is in range.
        if Diplomacy and Diplomacy.IsLooterType(group.groupType)
            and CorridorGraph and type(CorridorGraph.FindHottestCorridorPoint) == "function"
        then
            local hot = CorridorGraph.FindHottestCorridorPoint(
                group.location.x, group.location.y, 1200, Store.WorldAgeHours()
            )
            if hot and hot.heat >= 0.4 then
                local ambushLoc = {
                    id = "ambush_corridor:" .. tostring(math.floor(hot.x)) .. ":" .. tostring(math.floor(hot.y)),
                    type = "AMBUSH_POINT",
                    x = hot.x,
                    y = hot.y,
                    z = 0,
                    danger = 0,
                    tags = { ROAD = true, AMBUSH = true },
                    resourcePotential = { food = 30, water = 20, supplies = 30 },
                }
                if Locations and type(Locations.Register) == "function" then
                    pcall(Locations.Register, ambushLoc)
                end
                best = ambushLoc
            end
        end
        if not best and RoutePlanner and type(RoutePlanner.SelectNextScavengePOI) == "function" then
            local poi = RoutePlanner.SelectNextScavengePOI(
                group.location.x,
                group.location.y,
                { worldAgeHours = Store.WorldAgeHours() }
            )
            if poi then
                local poiLoc = {
                    id = "poi_loc:" .. tostring(poi.id),
                    type = "SCAVENGE_POI",
                    x = poi.x,
                    y = poi.y,
                    z = poi.z or 0,
                    danger = 0,
                    tags = { BUILDING = poi.kind == "poi", WILDERNESS = poi.kind == "wilderness" },
                    resourcePotential = { food = 25, water = 20, supplies = 18 },
                }
                if Locations and type(Locations.Register) == "function" then
                    pcall(Locations.Register, poiLoc)
                end
                best = poiLoc
            end
        end
    end
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.destinationEvaluations = evaluations
    return best, best and "selected" or "no_candidate"
end

function Traversal.ChooseFallback(group, threatLocationID)
    if not group or not group.location then return nil, "invalid_group" end
    local nearby = Locations.GetNearby(group.location.x, group.location.y,
        Config.DESTINATION_QUERY_RADIUS, Config.DESTINATION_CANDIDATE_LIMIT)
    local best, bestScore
    for _, candidate in ipairs(nearby) do
        local location = candidate.location
        if location.id ~= group.location.id and location.id ~= threatLocationID then
            local occupied = #Locations.GetGroupOccupants(location, group.id)
            local safe = (location.tags.SAFE and 80 or 0)
                + (location.tags.FRIENDLY and 45 or 0)
                - (tonumber(location.danger) or 0) * 1.5
                - occupied * 35 - candidate.distance * 0.025
            if not best or safe > bestScore
                or safe == bestScore and location.id < best.id
            then best, bestScore = location, safe end
        end
    end
    return best, best and "fallback_selected" or "no_fallback"
end

local MAP_MIN_X, MAP_MAX_X = 3000, 15000
local MAP_MIN_Y, MAP_MAX_Y = 1000, 13500

local function clampCoord(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function seededIndex(seedText, count)
    if count <= 1 then return 1 end
    local h = 17
    local s = tostring(seedText or "")
    for i = 1, #s do
        h = (h * 31 + string.byte(s, i)) % 100003
    end
    return (h % count) + 1
end

-- Far-migration destination selector for fleeing looters & displaced squads.
-- Prefers distant safe locations (>= minDistance away from threat) with seeded
-- randomization among top candidates, and synthesizes a valid bounded far
-- waypoint if no pre-discovered AbstractLocation exists far enough away.
function Traversal.ChooseFarMigrationDestination(group, threatX, threatY, opts)
    if not group or not group.location then return nil, "invalid_group" end
    opts = type(opts) == "table" and opts or {}
    local tx = tonumber(threatX) or tonumber(group.location.x) or 8000
    local ty = tonumber(threatY) or tonumber(group.location.y) or 8000
    local minDist = tonumber(opts.minDistance) or 350
    local maxDist = tonumber(opts.maxDistance) or 1400
    local nowHours = Store and type(Store.WorldAgeHours) == "function" and Store.WorldAgeHours() or 0

    local pool = {}
    if Locations and type(Locations.GetNearby) == "function" then
        local wide = Locations.GetNearby(tx, ty, maxDist, 48) or {}
        for i = 1, #wide do
            local entry = wide[i]
            local loc = entry and entry.location
            local dist = tonumber(entry and entry.distance) or 0
            if loc and loc.id ~= group.location.id and dist >= minDist then
                local avoidedUntil = group.recentAvoidedLocations and group.recentAvoidedLocations[loc.id] or 0
                if avoidedUntil <= nowHours then
                    local occupied = Locations.GetGroupOccupants and #Locations.GetGroupOccupants(loc, group.id) or 0
                    local score = dist * 0.08
                        - (tonumber(loc.danger) or 0) * 1.5
                        - occupied * 40
                        + ((loc.tags and loc.tags.SAFE) and 50 or 0)
                    pool[#pool + 1] = { location = loc, score = score, distance = dist }
                end
            end
        end
    end

    if #pool > 0 then
        table.sort(pool, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            return tostring(a.location.id) < tostring(b.location.id)
        end)
        local topCount = math.min(#pool, 5)
        local pick = seededIndex(tostring(group.id or "") .. ":" .. tostring(math.floor(nowHours * 10)), topCount)
        return pool[pick].location, "far_location_selected"
    end

    -- Synthetic bounded far waypoint along the away-bearing so migration never stalls.
    local gx = tonumber(group.location.x) or tx
    local gy = tonumber(group.location.y) or ty
    local dx, dy = gx - tx, gy - ty
    local len = math.sqrt(dx * dx + dy * dy)
    local angle
    if len < 1 then
        local idx = seededIndex(tostring(group.id or "") .. ":bearing", 360)
        angle = math.rad(idx)
    else
        local jitter = (seededIndex(tostring(group.id or "") .. ":jit", 61) - 31)
        angle = math.atan2(dy, dx) + math.rad(jitter)
    end
    local hop = minDist + seededIndex(tostring(group.id or "") .. ":hop", math.max(50, maxDist - minDist))
    local destX = math.floor(clampCoord(tx + math.cos(angle) * hop, MAP_MIN_X, MAP_MAX_X))
    local destY = math.floor(clampCoord(ty + math.sin(angle) * hop, MAP_MIN_Y, MAP_MAX_Y))
    local synthID = "far_migrate:" .. tostring(destX) .. ":" .. tostring(destY)
    local synth = {
        id = synthID,
        type = "MIGRATION_WAYPOINT",
        x = destX,
        y = destY,
        z = 0,
        danger = 0,
        tags = { SAFE = true, MIGRATION = true },
    }
    if Locations and type(Locations.Register) == "function" then
        pcall(Locations.Register, synth)
    end
    return synth, "far_waypoint_synthesized"
end
