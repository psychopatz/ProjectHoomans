if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorldDiscovery = PNC.WorldDiscovery or {}
local Discovery = PNC.WorldDiscovery
Discovery.RadioBroadcastsInternal = Discovery.RadioBroadcastsInternal or {}
local Internal = Discovery.RadioBroadcastsInternal
local Types = PNC.WorldDiscoveryTypes

require "PNC/Semantics/PNC_SemanticAddressResolver"
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.AddressResolver = PNC.Semantics.AddressResolver or {}

Discovery.RADIO_IDENTITY_REVEAL_CHANCE = 35
Discovery.RADIO_ARGUMENT_CHANCE = 25
Discovery.RADIO_CONFLICT_CHANCE = 15
Discovery.RADIO_AMBIENT_VARIANTS = {
    "open_band",
    "cross_talk",
}

require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Context_Helpers"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Context_Template"
require "PNC/WorldDiscovery/WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Context_Persistence"

return Internal
