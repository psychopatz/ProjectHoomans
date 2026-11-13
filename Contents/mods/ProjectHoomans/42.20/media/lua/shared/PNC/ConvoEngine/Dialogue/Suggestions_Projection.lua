-- Ordered presentation projection entry point for semantic dialogue suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
Suggestions.Internal = Suggestions.Internal or {}

require "PNC/ConvoEngine/Dialogue/Suggestions_Projection_Offers"
require "PNC/ConvoEngine/Dialogue/Suggestions_Projection_Root"
require "PNC/ConvoEngine/Dialogue/Suggestions_Projection_Landing"
require "PNC/ConvoEngine/Dialogue/Suggestions_Projection_Groups"

return true
