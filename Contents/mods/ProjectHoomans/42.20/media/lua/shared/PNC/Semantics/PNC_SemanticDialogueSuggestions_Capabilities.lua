-- Ordered capability projection entry point for semantic dialogue suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
Suggestions.Internal = Suggestions.Internal or {}

require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities_Core"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities_Companion"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities_Camp"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities_Rows"

return true
