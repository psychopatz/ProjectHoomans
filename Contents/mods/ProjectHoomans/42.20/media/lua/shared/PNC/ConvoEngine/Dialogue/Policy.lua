-- Semantic dialogue policy composition root.
-- Catalog/classifiers, response helpers, and public decision flow load in order.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/ConvoEngine/Dialogue/Policy_Core"
require "PNC/ConvoEngine/Dialogue/Policy_Classifiers"
require "PNC/ConvoEngine/Dialogue/Policy_Decision"
require "PNC/ConvoEngine/Dialogue/Policy_Flow"

return PNC.ConvoEngine.DialoguePolicy
