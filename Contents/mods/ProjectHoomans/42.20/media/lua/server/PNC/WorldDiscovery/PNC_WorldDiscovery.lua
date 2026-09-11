-- Server-authoritative strategic discovery entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldDiscovery = PNC.WorldDiscovery or {}
PNC.WorldDiscovery.Internal = PNC.WorldDiscovery.Internal or {}

local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes

Discovery.Registry = Discovery.Registry or {
    schemaVersion = Types.SCHEMA_VERSION,
    revision = 0,
    players = {},
    frequencies = { settlements = {}, refugees = {} },
}
Discovery.Loaded = Discovery.Loaded == true
Discovery.Dirty = Discovery.Dirty == true
Discovery.LastProximityScanAt = Discovery.LastProximityScanAt or {}
Discovery.PROXIMITY_SCAN_MS = 2000
Discovery.PROXIMITY_SLICE_MS = 100
Discovery.PROXIMITY_SCAN_BUDGET = 24
Discovery.WORLD_ENTITY_CACHE_MS = 10000
Discovery.SETTLEMENT_DISCOVERY_RANGE = 40
Discovery.MOBILE_GROUP_DISCOVERY_RANGE = 30
Discovery.RADIO_RANGE = 10000
-- Kept as a compatibility fallback for callers that loaded before the
-- sandbox accessor. Runtime scans use RadioCooldownHours() below.
Discovery.RADIO_COOLDOWN_HOURS = 0.5
Discovery.RADIO_AMBIENT_INTERVAL_MS = 90000
Discovery.RADIO_AMBIENT_GLOBAL_GAP_MS = 60000
Discovery.RADIO_AMBIENT_CHANCE = 65
Discovery.RadioAmbientState = Discovery.RadioAmbientState or {
    lastAiredAt = nil,
    hasAired = false,
    lastVariant = nil,
    sequence = 0,
    lastRequestAtByPlayer = {},
}

function Discovery.RadioDiscoveryEnabled()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioDiscoveryEnabled) == "function" then
        return settings.RadioDiscoveryEnabled() == true
    end
    return true
end

function Discovery.RadioCooldownHours()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioDiscoveryCooldownHours) == "function" then
        return math.max(0, tonumber(settings.RadioDiscoveryCooldownHours())
            or Discovery.RADIO_COOLDOWN_HOURS)
    end
    return Discovery.RADIO_COOLDOWN_HOURS
end

function Discovery.RadioSignalChance()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioDiscoverySignalChance) == "function" then
        return math.max(0, math.min(100,
            tonumber(settings.RadioDiscoverySignalChance()) or 100))
    end
    return 100
end

function Discovery.RadioAmbientEnabled()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioAmbientEnabled) == "function" then
        return settings.RadioAmbientEnabled() == true
    end
    return true
end

function Discovery.RadioAmbientIntervalMs()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioAmbientIntervalSeconds) == "function" then
        return math.max(1000, tonumber(settings.RadioAmbientIntervalSeconds())
            or Discovery.RADIO_AMBIENT_INTERVAL_MS / 1000) * 1000
    end
    return Discovery.RADIO_AMBIENT_INTERVAL_MS
end

function Discovery.RadioAmbientChance()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioAmbientChance) == "function" then
        return math.max(0, math.min(100,
            tonumber(settings.RadioAmbientChance())
                or Discovery.RADIO_AMBIENT_CHANCE))
    end
    return Discovery.RADIO_AMBIENT_CHANCE
end

require "PNC/WorldDiscovery/PNC_WorldDiscovery_Storage"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Entities"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Actions"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Proximity"

return Discovery
