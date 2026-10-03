-- Semantic dialogue policy composition root.
-- Catalog/classifiers, response helpers, and public decision flow load in order.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDialoguePolicy_Core"
require "PNC/Semantics/PNC_SemanticDialoguePolicy_Classifiers"
require "PNC/Semantics/PNC_SemanticDialoguePolicy_Decision"
require "PNC/Semantics/PNC_SemanticDialoguePolicy_Flow"

return PNC.Semantics.DialoguePolicy
