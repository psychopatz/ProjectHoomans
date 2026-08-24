-- Stable facility-validation service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityValidationService = PNC.FacilityValidationService or {}
PNC.FacilityValidationService.Internal =
    PNC.FacilityValidationService.Internal or {}

require "PNC/Settlement/FacilityValidationService/PNC_FacilityValidationService_Core"
require "PNC/Settlement/FacilityValidationService/PNC_FacilityValidationService_Footprint"
require "PNC/Settlement/FacilityValidationService/PNC_FacilityValidationService_Components"
require "PNC/Settlement/FacilityValidationService/PNC_FacilityValidationService_Operational"

return PNC.FacilityValidationService
