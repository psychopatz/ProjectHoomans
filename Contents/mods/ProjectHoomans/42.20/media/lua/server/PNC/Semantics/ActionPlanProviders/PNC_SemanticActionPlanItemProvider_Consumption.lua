-- Composition entry for the authoritative consumption providers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

-- Ensure a partial server composition still installs the world-target spoke
-- before a refill plan is submitted.
pcall(require, "PNC/Semantics/PNC_SemanticWaterTargetResolver")
PNC.Semantics.ActionPlanItemProvider.Consume =
    PNC.Semantics.ActionPlanItemProvider.Consume or {}
PNC.Semantics.ActionPlanItemProvider.Refill =
    PNC.Semantics.ActionPlanItemProvider.Refill or {}

require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_ConsumptionSupport"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_ConsumptionExecution"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_RefillExecution"

return PNC.Semantics.ActionPlanItemProvider
