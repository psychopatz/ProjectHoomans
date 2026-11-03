PNC = PNC or {}
PNC.CoreGroupTraversalBridge = PNC.CoreGroupTraversalBridge or {}

local Bridge = PNC.CoreGroupTraversalBridge
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Journey = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
local CoreTraversal = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function distance(left, right)
    left = type(left) == "table" and left or {}
    right = type(right) == "table" and right or {}
    local dx = finite(right.x, 0) - finite(left.x, 0)
    local dy = finite(right.y, 0) - finite(left.y, 0)
    local dz = finite(right.z, 0) - finite(left.z, 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function syncCompatibility(group, journey)
    if not group or not journey then return end
    group.stateStartedAt = finite(
        journey.startAt,
        group.stateStartedAt
    )
    group.stateEndsAt = finite(
        journey.eta or journey.arrivedAt,
        group.stateEndsAt
    )
end

local function legacyJourney(group, at)
    if type(group) ~= "table"
        or group.state ~= "TRAVELING"
        or type(group.location) ~= "table"
        or type(group.targetLocation) ~= "table"
    then
        return nil, "group_journey_missing"
    end
    local startedAt = finite(group.stateStartedAt, at)
    local endsAt = math.max(
        startedAt,
        finite(group.stateEndsAt, startedAt)
    )
    local duration = math.max(0.001, endsAt - startedAt)
    local total = distance(group.location, group.targetLocation)
    local journey, reason = Journey.New(
        group.id,
        {
            origin = group.location,
            destination = group.targetLocation,
            originAnchorID = group.location.id,
            destinationAnchorID = group.targetLocation.id,
            speed = math.max(0.001, total / duration),
            startAt = startedAt,
            mode = "abstract",
            ownerMod = "ProjectHoomans",
            ownerRef = "abstract_group",
        },
        startedAt
    )
    if not journey then return nil, reason end
    journey, reason = Journey.Advance(journey, at)
    if not journey then return nil, reason end
    group.journey = journey
    syncCompatibility(group, journey)
    return journey, "legacy_migrated"
end

function Bridge.Ensure(group, at)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    if type(group.journey) == "table" then
        local normalized, reason = Journey.Normalize(
            group.journey,
            group.id,
            group.journey.lastAdvancedAt
                or group.journey.lastAdvancedWorldHour
                or at
        )
        if not normalized then return nil, reason end
        group.journey = normalized
        syncCompatibility(group, normalized)
        return normalized, "existing"
    end
    return legacyJourney(group, at)
end

function Bridge.Begin(group, target, travelHours, at)
    if type(group) ~= "table"
        or type(group.location) ~= "table"
        or type(target) ~= "table"
    then
        return nil, "invalid_group_travel"
    end
    at = finite(at, 0)
    travelHours = math.max(0.001, finite(travelHours, 0.001))
    local total = distance(group.location, target)
    local journey, reason = Journey.New(
        group.id,
        {
            origin = group.location,
            destination = target,
            originAnchorID = group.location.id,
            destinationAnchorID = target.id,
            speed = math.max(0.001, total / travelHours),
            startAt = at,
            mode = "abstract",
            ownerMod = "ProjectHoomans",
            ownerRef = "abstract_group",
        },
        at
    )
    if not journey then return nil, reason end
    group.journey = journey
    syncCompatibility(group, journey)
    return journey
end

function Bridge.Advance(group, at)
    local journey, reason = Bridge.Ensure(group, at)
    if not journey then return nil, reason end
    local advanced
    advanced, reason = Journey.Advance(journey, at)
    if not advanced then return nil, reason end
    group.journey = advanced
    syncCompatibility(group, advanced)
    return advanced
end

function Bridge.Complete(group, target, at)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    local journey = type(group.journey) == "table"
        and Util.clone(group.journey) or nil
    if not journey and type(target) == "table" then
        journey = Bridge.Begin(group, target, 0.001, at)
    end
    if not journey then return nil, "group_journey_missing" end
    target = type(target) == "table"
        and target or journey.destination
    journey.distanceTravelled = journey.distanceTotal
    journey.progress = 1
    journey.state = "arrived"
    journey.waitRemainingHours = 0
    journey.segmentIndex = math.max(
        1,
        #journey.route.points - 1
    )
    journey.segmentProgress = 1
    journey.x = finite(target.x, journey.destination.x)
    journey.y = finite(target.y, journey.destination.y)
    journey.z = finite(target.z, journey.destination.z)
    journey.arrivedAt = finite(at, journey.eta)
    journey.lastAdvancedAt = journey.arrivedAt
    journey.eta = journey.arrivedAt
    journey.revision = (tonumber(journey.revision) or 1) + 1
    group.journey = journey
    syncCompatibility(group, journey)
    return journey
end

function Bridge.Cancel(group, reason)
    if type(group) ~= "table"
        or type(group.journey) ~= "table"
    then
        return nil, "group_journey_missing"
    end
    local cancelled, failure =
        Journey.Cancel(group.journey, reason)
    if not cancelled then return nil, failure end
    group.journey = cancelled
    syncCompatibility(group, cancelled)
    return cancelled
end

function Bridge.Project(group, at)
    local journey, reason = Bridge.Ensure(group, at)
    if not journey then return nil, reason end
    return Journey.ProjectPosition(journey, at)
end

local function coreGroup(group)
    if type(group) ~= "table" then return nil end
    return {
        id = group.id,
        memberActorIDs = Util.clone(
            group.memberActorIDs or group.memberIds or {}
        ),
        location = Util.clone(group.location),
        targetLocation = Util.clone(group.targetLocation),
        journey = Util.clone(group.journey),
    }
end

function Bridge.ProjectMember(group, actorID, actorWorld, at)
    local projected = coreGroup(group)
    if not projected then return nil, "group_required" end
    return CoreTraversal.ProjectMemberPosition(
        projected,
        actorID,
        actorWorld,
        at
    )
end

Bridge.Journey = Journey
Bridge.Traversal = CoreTraversal

return Bridge
