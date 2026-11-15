-- Server-authoritative shared work zone service (geometry, cursor scanning,
-- target claims with TTL, and dual-mode autonomous/manual worker dispatch).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkZoneService = PNC.WorkZoneService or {}
PNC.WorkZoneService.Internal = PNC.WorkZoneService.Internal or {}

require "PNC/Production/WorkZoneService/PNC_WorkZoneService_Registry"
require "PNC/Production/WorkZoneService/PNC_WorkZoneService_Claims"
require "PNC/Production/WorkZoneService/PNC_WorkZoneService_Dispatch"

return PNC.WorkZoneService
