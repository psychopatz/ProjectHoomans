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
Discovery.RADIO_COOLDOWN_HOURS = 0.01

require "PNC/WorldDiscovery/PNC_WorldDiscovery_Storage"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Entities"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Actions"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Proximity"

return Discovery
