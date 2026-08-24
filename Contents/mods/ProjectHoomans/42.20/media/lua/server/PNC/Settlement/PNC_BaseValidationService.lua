-- Stable settlement-base validation entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BaseValidationService = PNC.BaseValidationService or {}
PNC.BaseValidationService.Internal =
    PNC.BaseValidationService.Internal or {}

require "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Core"
require "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Conflicts"
require "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Territory"
require "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Upgrades"

return PNC.BaseValidationService
