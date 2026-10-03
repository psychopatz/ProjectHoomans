-- Small deterministic response composer for high-confidence semantic turns.
-- Composition root: catalog/context, text helpers, question context, branches.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Core"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Text"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Context"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Resolve"

return PNC.Semantics.LocalResponse
