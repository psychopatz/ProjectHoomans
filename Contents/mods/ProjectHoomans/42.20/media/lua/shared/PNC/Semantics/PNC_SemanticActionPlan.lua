-- Ordered semantic action-plan entry point.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActionPlan = PNC.Semantics.ActionPlan or {}

require "PNC/Semantics/SemanticActionPlan/PNC_SemanticActionPlan_Schema"
require "PNC/Semantics/SemanticActionPlan/PNC_SemanticActionPlan_Codec"
require "PNC/Semantics/SemanticActionPlan/PNC_SemanticActionPlan_Lifecycle"

return PNC.Semantics.ActionPlan
