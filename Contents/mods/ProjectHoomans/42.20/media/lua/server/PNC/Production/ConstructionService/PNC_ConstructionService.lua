if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal = PNC.ConstructionService.Internal or {}

require "PNC/Production/ConstructionService/PNC_ConstructionService_Materials"
require "PNC/Production/ConstructionService/PNC_ConstructionService_Queueing"
require "PNC/Production/ConstructionService/PNC_ConstructionService_Lifecycle"

return PNC.ConstructionService
