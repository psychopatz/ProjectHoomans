if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
Discovery.RadioBroadcastsInternal = Discovery.RadioBroadcastsInternal or {}

require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Context"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_MessagePacks"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Api"

return Discovery
