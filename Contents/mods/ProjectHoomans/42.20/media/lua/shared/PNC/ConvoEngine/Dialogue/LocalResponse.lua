-- Small deterministic response composer for high-confidence semantic turns.
-- Composition root: catalog/context, text helpers, question context, branches.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/ConvoEngine/Dialogue/LocalResponse_Core"
require "PNC/ConvoEngine/Dialogue/LocalResponse_Text"
require "PNC/ConvoEngine/Dialogue/LocalResponse_Context"
require "PNC/ConvoEngine/Dialogue/LocalResponse_Resolve"

return PNC.ConvoEngine.LocalResponse
