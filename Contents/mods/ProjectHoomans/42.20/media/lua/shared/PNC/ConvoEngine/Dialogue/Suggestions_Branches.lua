-- Internal implementation hub for semantic dialogue suggestion branches.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Suggestions = PNC.ConvoEngine.DialogueSuggestions

-- Candidate construction must load before frame validation because the latter
-- resolves branch offers through these bounded helpers.
require "PNC/ConvoEngine/Dialogue/Suggestions_Branches_Candidates"
require "PNC/ConvoEngine/Dialogue/Suggestions_Branches_IR"

return Suggestions
