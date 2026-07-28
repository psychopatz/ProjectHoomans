-- Pluggable route and speed providers for Project Hoomans journeys.

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Providers = PNC.Travel.Providers or {}

local Providers = PNC.Travel.Providers
local Route = PNC.Travel.Route
local Const = PNC.Const

Providers.RouteProviders = Providers.RouteProviders or {}
Providers.SpeedProfiles = Providers.SpeedProfiles or {}

function Providers.RegisterRouteProvider(id, provider)
    id = tostring(id or "")
    if id == "" or type(provider) ~= "function" then return false end
    Providers.RouteProviders[id] = provider
    return true
end

function Providers.UnregisterRouteProvider(id)
    id = tostring(id or "")
    if id == "" or id == "direct"
        or Providers.RouteProviders[id] == nil
    then
        return false
    end
    Providers.RouteProviders[id] = nil
    return true
end

function Providers.RegisterSpeedProfile(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table" then return false end
    local speed = tonumber(
        definition.tilesPerWorldHour or definition.speedTilesPerWorldHour
    )
    if not speed or speed <= 0 then return false end
    Providers.SpeedProfiles[id] = {
        id = id,
        tilesPerWorldHour = speed,
        liveMode = tostring(definition.liveMode or definition.mode or "walk"),
    }
    return true
end

function Providers.UnregisterSpeedProfile(id)
    id = tostring(id or "")
    if id == "" or id == "walk" or id == "run" or id == "vehicle"
        or Providers.SpeedProfiles[id] == nil
    then
        return false
    end
    Providers.SpeedProfiles[id] = nil
    return true
end

function Providers.ResolveRoute(record, request)
    request = type(request) == "table" and request or {}
    local origin = request.origin or {
        x = record and record.x or 0,
        y = record and record.y or 0,
        z = record and record.z or 0,
    }
    local destination = request.destination or {
        x = request.x,
        y = request.y,
        z = request.z,
    }
    local providerID = tostring(request.routeProvider or "direct")
    local provider = Providers.RouteProviders[providerID]
    local supplied
    local ok
    if type(request.route) == "table" then
        supplied = request.route.points or request.route
        return Route.Build(supplied, origin, destination), providerID
    end
    if provider then
        ok, supplied = pcall(provider, record, request, origin, destination)
        if ok and type(supplied) == "table" then
            return Route.Build(
                supplied.points or supplied,
                origin,
                destination
            ), providerID
        end
        if not ok and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "PNC travel route provider failed id="
                    .. tostring(providerID)
                    .. " error=" .. tostring(supplied)
            )
        end
    end
    return Route.BuildDirect(origin, destination), "direct"
end

function Providers.ResolveSpeed(request, distance)
    request = type(request) == "table" and request or {}
    distance = math.max(0, tonumber(distance) or 0)
    local duration = tonumber(request.durationWorldHours)
    if duration and duration > 0 and distance > 0 then
        return distance / duration, tostring(request.speedProfile or "duration")
    end
    local explicit = tonumber(
        request.speedTilesPerWorldHour or request.tilesPerWorldHour
    )
    if explicit and explicit > 0 then
        return explicit, tostring(request.speedProfile or "custom")
    end
    local profileID = tostring(
        request.speedProfile or request.mode or "walk"
    )
    local profile = Providers.SpeedProfiles[profileID]
        or Providers.SpeedProfiles.walk
    return profile.tilesPerWorldHour, profile.id
end

function Providers.GetLiveMode(profileID, fallback)
    local profile = Providers.SpeedProfiles[tostring(profileID or "")]
    return profile and profile.liveMode or tostring(fallback or "walk")
end

Providers.RegisterRouteProvider("direct", function(_, request)
    return request and request.route or nil
end)
Providers.RegisterSpeedProfile("walk", {
    tilesPerWorldHour = tonumber(Const.TRAVEL_SPEED_WALK_TILES_PER_HOUR) or 300,
    liveMode = "walk",
})
Providers.RegisterSpeedProfile("run", {
    tilesPerWorldHour = tonumber(Const.TRAVEL_SPEED_RUN_TILES_PER_HOUR) or 480,
    liveMode = "run",
})
Providers.RegisterSpeedProfile("vehicle", {
    tilesPerWorldHour = tonumber(Const.TRAVEL_SPEED_VEHICLE_TILES_PER_HOUR)
        or 1500,
    liveMode = "run",
})

return Providers
