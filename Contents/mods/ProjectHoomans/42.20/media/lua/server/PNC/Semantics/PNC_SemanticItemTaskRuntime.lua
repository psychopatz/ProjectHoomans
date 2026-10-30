-- Domain registration: Semantics. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider"
require "PNC/Semantics/PNC_SemanticGiveItemTaskHandler"
require "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler"
