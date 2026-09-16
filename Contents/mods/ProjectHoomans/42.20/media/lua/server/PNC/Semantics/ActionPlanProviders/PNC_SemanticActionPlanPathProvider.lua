-- Server provider for semantic movement.  Target discovery and locomotion
-- remain separate so world adapters never perform gameplay actions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActionPlanPathProvider =
    PNC.Semantics.ActionPlanPathProvider or {}

local Provider = PNC.Semantics.ActionPlanPathProvider
Provider.Service = PNC.Semantics.ActionPlanService
Provider.Registry = PNC.Registry
Provider.PathService = PNC.PathService
Provider.Common = PNC.BehaviorCommon
Provider.MoveIntent = PNC.BehaviorMoveIntent
Provider.WorldTargets = PNC.Semantics.WorldTargetResolver

require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPathProvider_Target"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPathProvider_Execution"

if Provider.Service and type(Provider.Service.RegisterProvider) == "function" then
    Provider.Service.RegisterProvider("MOVE_TO", Provider)
end

return Provider
