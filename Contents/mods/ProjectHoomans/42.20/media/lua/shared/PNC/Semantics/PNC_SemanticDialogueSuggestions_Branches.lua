-- Internal implementation hub for semantic dialogue suggestion branches.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Suggestions = PNC.Semantics.DialogueSuggestions

-- Candidate construction must load before frame validation because the latter
-- resolves branch offers through these bounded helpers.
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Branches_Candidates"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Branches_IR"

return Suggestions
