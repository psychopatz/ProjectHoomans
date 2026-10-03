-- Server-owned allocation of a validated camp into nearby loaded room zones.
--
-- Providers are loaded in dependency order: shared helpers, bounded discovery,
-- assignment policy, then public runtime lifecycle.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.CampZoneService = PNC.CampZoneService or {}

require "PNC/World/PNC_CampZoneService_Core"
require "PNC/World/PNC_CampZoneService_Discovery"
require "PNC/World/PNC_CampZoneService_Assignment"
require "PNC/World/PNC_CampZoneService_Runtime"

return PNC.CampZoneService
