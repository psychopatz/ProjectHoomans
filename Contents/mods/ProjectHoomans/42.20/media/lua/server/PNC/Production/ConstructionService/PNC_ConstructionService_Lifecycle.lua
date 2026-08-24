-- Stable construction-lifecycle entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal =
    PNC.ConstructionService.Internal or {}

require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Targets"
require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Preparation"
require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Requirements"
require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Refunds"
require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Completions"
require "PNC/Production/ConstructionService/ConstructionService_Lifecycle/PNC_ConstructionService_Lifecycle_Cancellation"

return PNC.ConstructionService
