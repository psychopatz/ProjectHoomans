-- Canonical journey construction, validation, and compact view payloads.

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Model = PNC.Travel.Model or {}

local Model = PNC.Travel.Model
local Const = PNC.Const
local Core = PNC.Core
local Route = PNC.Travel.Route
local Providers = PNC.Travel.Providers

Model.ActiveStates = {
    planned = true,
    en_route = true,
    waiting = true,
    paused = true,
}

local function copyMetadata(value, depth, budget)
    local valueType = type(value)
    local output
    local key
    local copied
    if valueType == "nil"
        or valueType == "boolean"
        or valueType == "number"
        or valueType == "string"
    then
        return value
    end
    if valueType ~= "table"
        or depth >= (tonumber(Const.TRAVEL_METADATA_MAX_DEPTH) or 3)
        or budget.count >= (tonumber(Const.TRAVEL_METADATA_MAX_ENTRIES) or 64)
    then
        return nil
    end
    output = {}
    for key, value in pairs(value) do
        if budget.count >= (tonumber(Const.TRAVEL_METADATA_MAX_ENTRIES) or 64)
        then
            break
        end
        if type(key) == "string" or type(key) == "number" then
            copied = copyMetadata(value, depth + 1, budget)
            if copied ~= nil then
                output[key] = copied
                budget.count = budget.count + 1
            end
        end
    end
    return output
end

function Model.CopyMetadata(value)
    return copyMetadata(value, 0, { count = 0 }) or {}
end

function Model.IsActive(journey)
    return type(journey) == "table"
        and Model.ActiveStates[tostring(journey.state or "")] == true
end

function Model.New(record, request, worldHour)
    request = type(request) == "table" and request or {}
    worldHour = tonumber(worldHour) or 0
    local destination = Route.NormalizePoint(
        request.destination or {
            x = request.x,
            y = request.y,
            z = request.z,
        },
        record
    )
    local origin = Route.NormalizePoint(
        request.origin,
        record
    )
    local route, routeProvider = Providers.ResolveRoute(record, {
        origin = origin,
        destination = destination,
        route = request.route,
        routeProvider = request.routeProvider,
    })
    local speed, speedProfile = Providers.ResolveSpeed(
        request,
        route.totalDistance
    )
    local id = request.journeyId
        or Core.GenerateID("journey")
    local journey = {
        schemaVersion = tonumber(Const.TRAVEL_SCHEMA_VERSION) or 1,
        journeyId = tostring(id),
        npcId = tostring(record.id),
        ownerMod = request.ownerMod and tostring(request.ownerMod) or nil,
        ownerRef = request.ownerRef and tostring(request.ownerRef) or nil,
        state = "en_route",
        mode = tostring(request.mode or "walk"),
        speedProfile = tostring(speedProfile),
        speedTilesPerWorldHour = speed,
        routeProvider = routeProvider,
        routeVersion = 1,
        origin = origin,
        destination = destination,
        route = route,
        distanceTotal = route.totalDistance,
        distanceTravelled = 0,
        segmentIndex = 1,
        segmentProgress = 0,
        waitRemainingWorldHours = 0,
        departedWorldHour = worldHour,
        lastAdvancedWorldHour = worldHour,
        etaWorldHour = worldHour,
        arrivalRadius = math.max(
            0.1,
            tonumber(request.arrivalRadius)
                or tonumber(Const.TRAVEL_ARRIVAL_RADIUS)
                or 1
        ),
        visibility = tostring(request.visibility or "all"),
        controller = record.presenceState == Const.PRESENCE_LIVE
            and "live" or "abstract",
        metadata = Model.CopyMetadata(request.metadata),
        revision = 1,
        lastStateReason = "started",
    }
    if route.totalDistance <= journey.arrivalRadius then
        journey.distanceTravelled = route.totalDistance
        journey.state = "arrived"
        journey.arrivedWorldHour = worldHour
    end
    return journey
end

function Model.Normalize(raw, record, worldHour)
    if type(raw) ~= "table" or not record then return nil end
    local request = {
        journeyId = raw.journeyId,
        ownerMod = raw.ownerMod,
        ownerRef = raw.ownerRef,
        origin = raw.origin,
        destination = raw.destination,
        route = raw.route and raw.route.points or raw.route,
        routeProvider = raw.routeProvider,
        mode = raw.mode,
        speedProfile = raw.speedProfile,
        speedTilesPerWorldHour = raw.speedTilesPerWorldHour,
        arrivalRadius = raw.arrivalRadius,
        visibility = raw.visibility,
        metadata = raw.metadata,
    }
    local journey = Model.New(
        record,
        request,
        tonumber(raw.departedWorldHour) or tonumber(worldHour) or 0
    )
    journey.state = tostring(raw.state or journey.state)
    if not Model.ActiveStates[journey.state]
        and journey.state ~= "arrived"
        and journey.state ~= "cancelled"
        and journey.state ~= "blocked"
    then
        journey.state = "cancelled"
    end
    journey.distanceTravelled = math.max(
        0,
        math.min(
            journey.distanceTotal,
            tonumber(raw.distanceTravelled) or 0
        )
    )
    journey.segmentIndex = math.max(
        1,
        math.floor(tonumber(raw.segmentIndex) or 1)
    )
    journey.segmentProgress = math.max(
        0,
        math.min(1, tonumber(raw.segmentProgress) or 0)
    )
    journey.waitRemainingWorldHours = math.max(
        0,
        tonumber(raw.waitRemainingWorldHours) or 0
    )
    journey.lastAdvancedWorldHour = tonumber(raw.lastAdvancedWorldHour)
        or tonumber(worldHour)
        or journey.departedWorldHour
    journey.etaWorldHour = tonumber(raw.etaWorldHour)
        or journey.lastAdvancedWorldHour
    journey.arrivedWorldHour = tonumber(raw.arrivedWorldHour)
    journey.pausedWorldHour = tonumber(raw.pausedWorldHour)
    journey.controller = tostring(raw.controller or "abstract")
    journey.revision = math.max(1, math.floor(tonumber(raw.revision) or 1))
    journey.routeVersion = math.max(
        1,
        math.floor(tonumber(raw.routeVersion) or 1)
    )
    journey.lastStateReason = raw.lastStateReason
        and tostring(raw.lastStateReason)
        or "loaded"
    return journey
end

function Model.BuildSummary(journey, includeRoute)
    if type(journey) ~= "table" then return nil end
    local summary = {
        schemaVersion = journey.schemaVersion,
        journeyId = journey.journeyId,
        npcId = journey.npcId,
        ownerMod = journey.ownerMod,
        ownerRef = journey.ownerRef,
        state = journey.state,
        mode = journey.mode,
        speedProfile = journey.speedProfile,
        speedTilesPerWorldHour = journey.speedTilesPerWorldHour,
        routeProvider = journey.routeProvider,
        routeVersion = journey.routeVersion,
        origin = Core.DeepCopy(journey.origin),
        destination = Core.DeepCopy(journey.destination),
        distanceTotal = journey.distanceTotal,
        distanceTravelled = journey.distanceTravelled,
        segmentIndex = journey.segmentIndex,
        segmentProgress = journey.segmentProgress,
        waitRemainingWorldHours = journey.waitRemainingWorldHours,
        departedWorldHour = journey.departedWorldHour,
        lastAdvancedWorldHour = journey.lastAdvancedWorldHour,
        etaWorldHour = journey.etaWorldHour,
        arrivedWorldHour = journey.arrivedWorldHour,
        pausedWorldHour = journey.pausedWorldHour,
        arrivalRadius = journey.arrivalRadius,
        visibility = journey.visibility,
        controller = journey.controller,
        revision = journey.revision,
        lastStateReason = journey.lastStateReason,
        metadata = Model.CopyMetadata(journey.metadata),
    }
    if includeRoute ~= false then
        summary.route = {
            schemaVersion = journey.route and journey.route.schemaVersion or 1,
            totalDistance = journey.route
                and journey.route.totalDistance or journey.distanceTotal,
            points = Core.DeepCopy(
                journey.route and journey.route.points or {}
            ),
        }
    end
    return summary
end

return Model
