PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}

local API = PNC.API
local Internal = API.Internal
local Core = PNC.Core
local Types = PNC.Types
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Presence = PNC.Presence
local Equipment = PNC.Equipment
local Health = PNC.Health
local Inventory = PNC.Inventory
local Network = PNC.Network

-- Versioned cross-mod journey API. External mods receive copies/summaries and
-- never mutate the canonical record.travel table.
API.Travel = API.Travel or {}

function API.Travel.GetVersion()
    return tonumber(PNC.Const.TRAVEL_API_VERSION) or 1
end

function API.Travel.GetCapabilities()
    return {
        apiVersion = API.Travel.GetVersion(),
        persistentJourneys = true,
        waypointWaits = true,
        liveAbstractHandoff = true,
        clientProjection = true,
        routeProviders = true,
        speedProfiles = true,
        arrivalActions = true,
        mapDirectory = true,
    }
end

function API.Travel.Start(npcId, request)
    if not PNC.Travel or not PNC.Travel.Service then
        return nil, "travel_unavailable"
    end
    local journey, reason = PNC.Travel.Service.Start(npcId, request)
    return journey and PNC.Travel.Model.BuildSummary(journey, true) or nil,
        reason
end

function API.Travel.Get(npcId)
    local journey = PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Service.Get(npcId) or nil
    if journey then
        return PNC.Travel.Model.BuildSummary(journey, true)
    end
    local snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[tostring(npcId)] or nil
    return snapshot and Core.DeepCopy(snapshot.travel) or nil
end

function API.Travel.GetProgress(npcId, atWorldHour)
    if PNC.Travel and PNC.Travel.Service then
        local progress = PNC.Travel.Service.GetProgress(npcId, atWorldHour)
        if progress then return progress end
    end
    if PNC.TravelDirectory and PNC.TravelDirectory.GetProjected then
        return PNC.TravelDirectory.GetProjected(npcId, atWorldHour)
    end
    return nil
end

function API.Travel.Pause(npcId, reason)
    return PNC.Travel.Service.Pause(npcId, reason)
end

function API.Travel.Resume(npcId, reason)
    return PNC.Travel.Service.Resume(npcId, reason)
end

function API.Travel.Cancel(npcId, reason)
    return PNC.Travel.Service.Cancel(npcId, reason)
end

function API.Travel.Retarget(npcId, request)
    local journey, reason = PNC.Travel.Service.Retarget(npcId, request)
    return journey and PNC.Travel.Model.BuildSummary(journey, true) or nil,
        reason
end

function API.Travel.RegisterRouteProvider(id, provider)
    return PNC.Travel.Providers.RegisterRouteProvider(id, provider)
end

function API.Travel.UnregisterRouteProvider(id)
    return PNC.Travel.Providers.UnregisterRouteProvider(id)
end

function API.Travel.RegisterSpeedProfile(id, definition)
    return PNC.Travel.Providers.RegisterSpeedProfile(id, definition)
end

function API.Travel.UnregisterSpeedProfile(id)
    return PNC.Travel.Providers.UnregisterSpeedProfile(id)
end

function API.Travel.RegisterArrivalHandler(id, handler)
    return PNC.Travel.Arrivals.RegisterHandler(id, handler)
end

function API.Travel.UnregisterArrivalHandler(id)
    return PNC.Travel.Arrivals.UnregisterHandler(id)
end

function API.Travel.RegisterListener(eventName, listener)
    return PNC.Travel.Service.RegisterListener(eventName, listener)
end

function API.Travel.UnregisterListener(eventName, listener)
    return PNC.Travel.Service.UnregisterListener(eventName, listener)
end

API.MapCommands = API.MapCommands or {}

-- Stable cross-mod animation scene API. Scene definitions contain only
-- serializable policy fields; behaviors and clients exchange scene IDs.
API.AnimationScenes = API.AnimationScenes or {}

