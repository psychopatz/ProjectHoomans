PNC = PNC or {}
PNC.CoreGroupTraversalBridge = PNC.CoreGroupTraversalBridge or {}

local Bridge = PNC.CoreGroupTraversalBridge
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Travel = (PsychopatzCore and PsychopatzCore.Travel)
    or require "PsychopatzCore/Travel/PsychopatzTravel"
local Journey = Travel.GroupJourney
local CoreTraversal = Travel.Group

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
    local adapter = PNC.CoreSurvivorWorldAdapter
    if adapter and adapter.CommitGroup then
        local canonical, syncReason = adapter.CommitGroup(
            group,
            "pnc_group_journey_advanced"
        )
        if not canonical then
            return nil, syncReason or "core_group_sync_failed"
        end
    end
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

-- Extract remaining road-corridor waypoints from a traveling group's canonical
-- journey so a materialized member can seamlessly continue walking on-screen.
function Bridge.ExtractRemainingWaypoints(group, fromX, fromY, fromZ)
    if type(group) ~= "table" or type(group.journey) ~= "table" then
        return nil
    end
    local journey = group.journey
    if journey.state ~= "en_route" then
        return nil
    end
    local route = type(journey.route) == "table" and journey.route or nil
    local points = route and route.points or nil
    if type(points) ~= "table" or #points < 2 then
        return nil
    end
    local startIdx = math.max(2, math.min(#points, (tonumber(journey.segmentIndex) or 1) + 1))
    local out = {}
    local fx = tonumber(fromX)
    local fy = tonumber(fromY)
    local fz = tonumber(fromZ) or 0
    for i = startIdx, #points do
        local pt = points[i]
        if type(pt) == "table" and tonumber(pt.x) and tonumber(pt.y) then
            local skip = false
            if i == startIdx and fx ~= nil and fy ~= nil then
                local dx = pt.x - fx
                local dy = pt.y - fy
                if (dx * dx + dy * dy) < 4 then
                    skip = true
                end
            end
            if not skip then
                out[#out + 1] = {
                    x = pt.x,
                    y = pt.y,
                    z = tonumber(pt.z) or fz,
                    tag = pt.tag or (i == #points and "destination" or "corridor"),
                }
            end
        end
    end
    if #out == 0 then
        local last = points[#points]
        if type(last) == "table" and tonumber(last.x) and tonumber(last.y) then
            out[1] = {
                x = last.x,
                y = last.y,
                z = tonumber(last.z) or fz,
                tag = "destination",
            }
        end
    end
    return #out > 0 and out or nil
end

-- Sync a materialized group member's live world position back onto the group's
-- canonical journey when abstracting, only advancing forward along the corridor.
function Bridge.SyncMemberLivePosition(group, x, y, z, at)
    if type(group) ~= "table" or type(group.journey) ~= "table" then
        return false, "group_journey_missing"
    end
    local journey = group.journey
    if journey.state ~= "en_route" then
        return false, "not_en_route"
    end
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then
        return false, "invalid_position"
    end
    local route = type(journey.route) == "table" and journey.route or nil
    local points = route and route.points or nil
    local cumulative = route and route.cumulative or nil
    if type(points) ~= "table" or #points < 2 or type(cumulative) ~= "table" then
        return false, "route_missing"
    end
    local bestDistSq = math.huge
    local bestTravelled = nil
    for i = 1, #points - 1 do
        local a = points[i]
        local b = points[i + 1]
        local abx = b.x - a.x
        local aby = b.y - a.y
        local abLenSq = abx * abx + aby * aby
        local t = 0
        if abLenSq > 0.0001 then
            t = ((x - a.x) * abx + (y - a.y) * aby) / abLenSq
            if t < 0 then t = 0 elseif t > 1 then t = 1 end
        end
        local px = a.x + abx * t
        local py = a.y + aby * t
        local dx = x - px
        local dy = y - py
        local dSq = dx * dx + dy * dy
        if dSq < bestDistSq then
            bestDistSq = dSq
            local segStart = tonumber(cumulative[i]) or 0
            local segEnd = tonumber(cumulative[i + 1]) or segStart
            bestTravelled = segStart + (segEnd - segStart) * t
        end
    end
    -- Only snap forward if the body stayed reasonably near the corridor (<= 64 tiles).
    if bestTravelled == nil or bestDistSq > (64 * 64) then
        return false, "off_corridor"
    end
    local currentTravelled = tonumber(journey.distanceTravelled) or 0
    if bestTravelled <= currentTravelled then
        return false, "not_advanced"
    end
    local total = math.max(0, tonumber(journey.distanceTotal) or 0)
    journey.distanceTravelled = math.min(total, bestTravelled)
    journey.progress = total > 0 and (journey.distanceTravelled / total) or 1
    journey.x = x
    journey.y = y
    journey.z = tonumber(z) or tonumber(journey.z) or 0
    journey.lastAdvancedAt = finite(at, journey.lastAdvancedAt)
    local speed = math.max(0.001, tonumber(journey.speed) or 1)
    journey.eta = journey.lastAdvancedAt + math.max(0, total - journey.distanceTravelled) / speed
    journey.revision = (tonumber(journey.revision) or 1) + 1
    syncCompatibility(group, journey)
    return true, "synced"
end

Bridge.Journey = Journey
Bridge.Traversal = CoreTraversal

return Bridge
