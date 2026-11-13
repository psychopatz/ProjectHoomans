-- Ordered capability projection entry point for semantic dialogue suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
Suggestions.Internal = Suggestions.Internal or {}

require "PNC/ConvoEngine/Dialogue/Suggestions_Capabilities_Core"
require "PNC/ConvoEngine/Dialogue/Suggestions_Capabilities_Companion"
require "PNC/ConvoEngine/Dialogue/Suggestions_Capabilities_Camp"
require "PNC/ConvoEngine/Dialogue/Suggestions_Capabilities_Rows"

return true
