-- Versioned, non-executing semantic dialogue suggestions.
--
-- This public entry point preserves the existing DialogueSuggestions namespace
-- while loading its bounded support layers and implementation spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Suggestions = PNC.ConvoEngine.DialogueSuggestions or {}
PNC.ConvoEngine.DialogueSuggestions = Suggestions

require "PNC/ConvoEngine/Dialogue/Suggestions_Core"
require "PNC/ConvoEngine/Dialogue/Suggestions_Topics"
require "PNC/ConvoEngine/Dialogue/Suggestions_Catalog"

require "PNC/ConvoEngine/Dialogue/Suggestions_Capabilities"
require "PNC/ConvoEngine/Dialogue/Suggestions_Branches"
require "PNC/ConvoEngine/Dialogue/Suggestions_Frames"
require "PNC/ConvoEngine/Dialogue/Suggestions_Projection"
require "PNC/ConvoEngine/Dialogue/Suggestions_Build"

return Suggestions
