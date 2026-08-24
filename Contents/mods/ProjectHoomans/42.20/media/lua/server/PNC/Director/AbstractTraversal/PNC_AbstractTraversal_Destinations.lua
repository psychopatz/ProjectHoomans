if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Traversal = PNC.AbstractTraversal
local H = Traversal.Internal
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Actions = PNC.AbstractActions
local ResourceNeeds = PNC.AbstractResourceNeeds
local Config = PNC.DirectorConfig

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
    local avoidedUntil = group.recentAvoidedLocations
        and group.recentAvoidedLocations[location.id] or 0
    components.recentThreat = avoidedUntil > Store.WorldAgeHours() and -250 or 0
    components.mission = group.mission == "RETURN_HOME"
        and group.homeCommunityId and location.type == "SETTLEMENT" and 40
        or group.mission == "REST" and location.tags.SAFE and 30
        or group.mission == "SCAVENGE" and components.resources * 0.35 or 0
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
