-- Pure journey advancement and ETA projection.

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Projection = PNC.Travel.Projection or {}

local Projection = PNC.Travel.Projection
local Route = PNC.Travel.Route

local function rebuildRoute(journey)
    local raw = journey and journey.route or nil
    if type(raw) ~= "table" then return nil end
    if type(raw.segments) == "table" and type(raw.points) == "table" then
        return raw
    end
    journey.route = Route.Build(
        raw.points or raw,
        journey.origin,
        journey.destination
    )
    journey.distanceTotal = journey.route.totalDistance
    return journey.route
end

local function setProjectedPosition(journey)
    local projected = Route.Project(
        journey.route,
        journey.distanceTravelled,
        journey.segmentIndex
    )
    journey.segmentIndex = projected.segmentIndex
    journey.segmentProgress = projected.segmentProgress
    journey.x = projected.x
    journey.y = projected.y
    journey.z = projected.z
    return projected
end

function Projection.UpdateETA(journey, worldHour)
    if type(journey) ~= "table" then return nil end
    worldHour = tonumber(worldHour)
        or tonumber(journey.lastAdvancedWorldHour)
        or 0
    local speed = math.max(
        0.0001,
        tonumber(journey.speedTilesPerWorldHour) or 0.0001
    )
    if journey.state == "arrived" then
        journey.etaWorldHour = tonumber(journey.arrivedWorldHour) or worldHour
        return journey.etaWorldHour
    end
    if journey.state == "cancelled" or journey.state == "blocked" then
        journey.etaWorldHour = nil
        return nil
    end
    local route = rebuildRoute(journey)
    local remainingDistance = math.max(
        0,
        (tonumber(journey.distanceTotal) or 0)
            - (tonumber(journey.distanceTravelled) or 0)
    )
    local remainingWait = math.max(
        0,
        tonumber(journey.waitRemainingWorldHours) or 0
    ) + Route.RemainingWaitHours(route, journey.segmentIndex)
    journey.etaWorldHour = worldHour
        + remainingDistance / speed
        + remainingWait
    return journey.etaWorldHour
end

function Projection.AdvanceMutable(journey, worldHour)
    if type(journey) ~= "table" then return nil, false end
    local route = rebuildRoute(journey)
    if not route then return nil, false end
    worldHour = tonumber(worldHour)
        or tonumber(journey.lastAdvancedWorldHour)
        or 0
    local lastHour = tonumber(journey.lastAdvancedWorldHour) or worldHour
    local elapsed = math.max(0, worldHour - lastHour)
    local speed = math.max(
        0.0001,
        tonumber(journey.speedTilesPerWorldHour) or 0.0001
    )
    local changed = false
    local segment
    local remainingDistance
    local travelHours
    local waitHours

    journey.lastAdvancedWorldHour = worldHour
    if journey.state == "planned" then
        journey.state = "en_route"
        changed = true
    end
    if journey.state == "paused"
        or journey.state == "cancelled"
        or journey.state == "blocked"
        or journey.state == "arrived"
    then
        setProjectedPosition(journey)
        Projection.UpdateETA(journey, worldHour)
        return journey, changed
    end

    while elapsed > 0
        and journey.state ~= "arrived"
        and journey.state ~= "paused"
    do
        if journey.state == "waiting" then
            waitHours = math.max(
                0,
                tonumber(journey.waitRemainingWorldHours) or 0
            )
            if elapsed < waitHours then
                journey.waitRemainingWorldHours = waitHours - elapsed
                elapsed = 0
                changed = true
            else
                elapsed = elapsed - waitHours
                journey.waitRemainingWorldHours = 0
                journey.state = "en_route"
                changed = true
            end
        else
            setProjectedPosition(journey)
            segment = route.segments[journey.segmentIndex]
            if not segment then
                journey.distanceTravelled = journey.distanceTotal
                journey.state = "arrived"
                journey.arrivedWorldHour = worldHour - elapsed
                changed = true
                break
            end
            remainingDistance = math.max(
                0,
                segment.distanceEnd - journey.distanceTravelled
            )
            travelHours = remainingDistance / speed
            if elapsed + 0.0000001 < travelHours then
                journey.distanceTravelled = journey.distanceTravelled
                    + speed * elapsed
                elapsed = 0
                changed = true
            else
                journey.distanceTravelled = segment.distanceEnd
                elapsed = math.max(0, elapsed - travelHours)
                changed = true
                if journey.distanceTravelled
                    >= journey.distanceTotal - 0.0001
                then
                    journey.distanceTravelled = journey.distanceTotal
                    journey.state = "arrived"
                    journey.arrivedWorldHour = worldHour - elapsed
                else
                    journey.segmentIndex = math.min(
                        #route.segments,
                        journey.segmentIndex + 1
                    )
                    journey.segmentProgress = 0
                    waitHours = math.max(
                        0,
                        tonumber(segment.waitWorldHours) or 0
                    )
                    if waitHours > 0 then
                        journey.state = "waiting"
                        journey.waitRemainingWorldHours = waitHours
                    end
                end
            end
        end
    end

    setProjectedPosition(journey)
    Projection.UpdateETA(journey, worldHour)
    return journey, changed
end

function Projection.Project(journey, worldHour)
    if type(journey) ~= "table" then return nil end
    -- Geometry and metadata are immutable by contract. A shallow state copy is
    -- therefore enough for UI prediction and avoids rebuilding/deep-copying a
    -- route for every NPC on every world-map frame.
    local copy = {}
    local key
    local value
    for key, value in pairs(journey) do
        copy[key] = value
    end
    Projection.AdvanceMutable(copy, worldHour)
    return copy
end

return Projection
