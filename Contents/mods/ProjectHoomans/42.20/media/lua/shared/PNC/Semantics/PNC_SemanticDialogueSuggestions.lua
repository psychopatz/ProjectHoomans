-- Versioned, non-executing semantic dialogue suggestions.
--
-- This public entry point preserves the existing DialogueSuggestions namespace
-- while loading its bounded support layers and implementation spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Suggestions = PNC.Semantics.DialogueSuggestions or {}
PNC.Semantics.DialogueSuggestions = Suggestions

require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Core"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Topics"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Catalog"

require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Branches"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Frames"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Build"

return Suggestions
