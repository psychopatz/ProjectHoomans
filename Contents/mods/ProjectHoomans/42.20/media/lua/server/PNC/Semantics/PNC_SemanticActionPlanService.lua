-- Stable server entry point for semantic action-plan orchestration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
require "PNC/Semantics/PNC_SemanticActionPlan"
require "PNC/Semantics/ActionPlanService/PNC_SemanticActionPlanService_Registry"
require "PNC/Semantics/ActionPlanService/PNC_SemanticActionPlanService_Commands"
require "PNC/Semantics/ActionPlanService/PNC_SemanticActionPlanService_Ownership"
require "PNC/Semantics/ActionPlanService/PNC_SemanticActionPlanService_Pump"

return PNC.Semantics.ActionPlanService
