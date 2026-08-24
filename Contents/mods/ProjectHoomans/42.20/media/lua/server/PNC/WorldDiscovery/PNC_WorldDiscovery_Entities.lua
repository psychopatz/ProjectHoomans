-- Stable strategic-entity discovery entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
Discovery.WorldEntityCache = Discovery.WorldEntityCache or {
    list = nil,
    builtAt = 0,
}

require "PNC/WorldDiscovery/WorldDiscovery_Entities/PNC_WorldDiscovery_Entities_Registry"
require "PNC/WorldDiscovery/WorldDiscovery_Entities/PNC_WorldDiscovery_Entities_Phases"
require "PNC/WorldDiscovery/WorldDiscovery_Entities/PNC_WorldDiscovery_Entities_Snapshots"

return Discovery
