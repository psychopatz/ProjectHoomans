-- Server-authoritative facility orchestration entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

require "PNC/Settlement/FacilityService/PNC_FacilityService_Core"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Creation"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Targets"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Upgrades"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Settings"
require "PNC/Settlement/FacilityService/PNC_FacilityService_ComponentInternals"
require "PNC/Settlement/FacilityService/PNC_FacilityService_ComponentCommands"
require "PNC/Settlement/FacilityService/PNC_FacilityService_AnchorFinalization"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Removal"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Queries"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Snapshots"
require "PNC/Settlement/FacilityService/PNC_FacilityService_Bootstrap"

return PNC.FacilityService
