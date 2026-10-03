-- WorkService target acquisition composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

require "PNC/Production/WorkService/PNC_WorkService_Targets_Providers"
require "PNC/Production/WorkService/PNC_WorkService_Targets_Claim"

return PNC.WorkService
