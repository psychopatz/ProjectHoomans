-- Ordered presentation projection entry point for semantic dialogue suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
Suggestions.Internal = Suggestions.Internal or {}

require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection_Offers"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection_Root"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection_Landing"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection_Groups"

return true
