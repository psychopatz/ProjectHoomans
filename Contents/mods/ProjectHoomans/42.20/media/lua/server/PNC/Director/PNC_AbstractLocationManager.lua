-- Stable abstract-location manager entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}

require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Core"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Occupancy"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Queries"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Registration"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_LoadedDiscovery"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_MetaDiscovery"
require "PNC/Director/AbstractLocationManager/PNC_AbstractLocationManager_Nearby"

return PNC.AbstractLocations
