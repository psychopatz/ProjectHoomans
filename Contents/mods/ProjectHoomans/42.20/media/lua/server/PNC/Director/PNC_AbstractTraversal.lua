-- Timer-based building/POI traversal. No individual pathfinding is performed.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractTraversal = PNC.AbstractTraversal or {}

local Traversal = PNC.AbstractTraversal
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Config = PNC.DirectorConfig

Traversal.TravelCursor = Traversal.TravelCursor or 0
Traversal.DecisionCursor = Traversal.DecisionCursor or 0

local function resourceValue(group, location)
    local potential = location.resourcePotential or {}
    local needs = Groups.GetNeeds(group) or {}
    local foodShortage = (100 - (tonumber(needs.hunger) or 100)) / 100
    local waterShortage = (100 - (tonumber(needs.hydration) or 100)) / 100
    return (tonumber(potential.food) or 0) * (0.5 + foodShortage)
        + (tonumber(potential.water) or 0) * (0.5 + waterShortage)
        + (tonumber(potential.medical) or 0) * 0.45
        + (tonumber(potential.weapons) or 0) * 0.35
        + (tonumber(potential.materials) or 0) * 0.2
end

function Traversal.ScoreDestination(group, location, distance)
    local tuning = Config.GetArchetype(group.groupType)
    local components = {}
    components.resources = resourceValue(group, location) * tuning.resourceWeight
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
    components.scavenged = -(tonumber(location.scavengedLevel) or 0) * 0.35
    components.mission = group.mission == "RETURN_HOME"
        and group.homeCommunityId and location.type == "SETTLEMENT" and 40
        or group.mission == "REST" and location.tags.SAFE and 30
        or group.mission == "SCAVENGE" and components.resources * 0.35 or 0
    local total = 0
    for _, value in pairs(components) do total = total + value end
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

function Traversal.CalculateTravelHours(group, target)
    local dx, dy = target.x - group.location.x, target.y - group.location.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local needs = Groups.GetNeeds(group) or {}
    local fatigue = tonumber(needs.fatigue) or 100
    local fatigueModifier = 0.65 + math.max(0, math.min(100, fatigue)) / 100 * 0.35
    local speed = Config.TRAVEL_SPEED_TILES_PER_HOUR * fatigueModifier
    return math.max(Config.MIN_TRAVEL_HOURS,
        math.min(Config.MAX_TRAVEL_HOURS, distance / math.max(1, speed))), distance
end

function Traversal.Begin(groupOrID, targetOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    local target = type(targetOrID) == "table" and targetOrID
        or Locations.Get(targetOrID)
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not target then return false, "invalid_travel" end
    if group.state == "TRAVELING" then return false, "already_traveling" end
    if group.location.id == target.id then return false, "already_there" end
    local hours, distance = Traversal.CalculateTravelHours(group, target)
    Locations.Depart(group, at)
    group.targetLocation = Locations.Ref(target)
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.travel = { from = group.location.id, to = target.id,
        distance = distance, travelHours = hours }
    Groups.SetState(group, "TRAVELING", at, at + hours)
    Store.Emit("GROUP_DESTINATION_SELECTED", { groupId = group.id,
        fromLocationId = group.location.id, targetLocationId = target.id,
        arrivalAt = at + hours })
    return true, "travel_started"
end

function Traversal.Arrive(groupOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not group.targetLocation then return false, "no_target" end
    local target = Locations.Get(group.targetLocation.id)
    if not target then
        group.targetLocation = nil
        Groups.SetState(group, "IDLE", at, at)
        return false, "target_missing"
    end
    group.location = Locations.Ref(target)
    group.targetLocation = nil
    group.visited[target.id] = true
    Groups.SetState(group, "ARRIVED", at, at)
    Groups.SynchronizeMembersAtLocation(group)
    local faction = group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if faction and PNC.Factions.IsMobileGroup(faction)
        and target.sourceSite and PNC.Factions.UpdateMobileGroup
    then
        PNC.Factions.UpdateMobileGroup(faction.id, {
            site = target.sourceSite, lastMovedAt = at,
            nextMoveAt = at + (tonumber(faction.mobile.relocationHours) or 1),
            relocationCount = (tonumber(faction.mobile.relocationCount) or 0) + 1,
        }, "abstract_group_arrival")
    end
    local reports = Encounters.DetectAt(target, group, at)
    Locations.Arrive(group, at, 0)
    Store.Emit("GROUP_ARRIVED", { groupId = group.id,
        locationId = target.id, encounters = #reports })
    return true, "arrived", reports
end

function Traversal.Advance(group, at)
    local lod = Groups.RefreshLOD(group, at)
    if lod == "ACTIVE" then return false, "active_simulation" end
    if group.state == "TRAVELING" then
        if at >= (tonumber(group.stateEndsAt) or 0) then
            return Traversal.Arrive(group, at)
        end
        return false, "in_transit"
    end
    if group.state == "IDLE" or group.state == "ARRIVED"
        or group.state == "WAITING"
    then
        local target = Traversal.ChooseDestination(group)
        if target then return Traversal.Begin(group, target, at) end
        return false, "no_destination"
    end
    return false, "state_not_traversable"
end

local function runBatch(at, budget, cursorName, predicate)
    local groups = Groups.List()
    if #groups == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.DIRECTOR_JOB_BUDGET))
    local processed = 0
    local visited = 0
    while processed < budget and visited < #groups do
        Traversal[cursorName] = (Traversal[cursorName] % #groups) + 1
        local group = groups[Traversal[cursorName]]
        if predicate(group) then
            Traversal.Advance(group, at)
            processed = processed + 1
        end
        visited = visited + 1
    end
    return processed
end

function Traversal.AdvanceTravelBatch(at, budget)
    return runBatch(at, budget, "TravelCursor",
        function(group) return group.state == "TRAVELING"
            or group.state == "ACTIVE" end)
end

function Traversal.DecideBatch(at, budget)
    return runBatch(at, budget, "DecisionCursor",
        function(group) return group.state ~= "TRAVELING"
            and group.state ~= "ACTIVE" end)
end

function Traversal.AdvanceBatch(at, budget)
    return Traversal.AdvanceTravelBatch(at, budget)
        + Traversal.DecideBatch(at, budget)
end

function Traversal.ForceArrival(groupID, at)
    local group = Groups.Get(groupID)
    if not group or group.state ~= "TRAVELING" then
        return false, "not_traveling"
    end
    return Traversal.Arrive(group, tonumber(at) or Store.WorldAgeHours())
end

return Traversal
