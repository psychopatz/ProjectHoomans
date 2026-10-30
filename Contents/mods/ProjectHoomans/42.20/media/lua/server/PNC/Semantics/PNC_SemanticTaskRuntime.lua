-- Domain registration: Semantics. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Semantics/PNC_SemanticWaterTargetResolver"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector"
require "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPathProvider"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanWaitProvider"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanCampProvider"
require "PNC/Semantics/PNC_SemanticTaskRequestService"
require "PNC/Semantics/PNC_SemanticActionPlanTaskHandler"
require "PNC/Semantics/PNC_SemanticCampTaskHandler"
