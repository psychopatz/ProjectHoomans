-- Compatibility façade for suggestion policy.
-- All typed predicate semantics now come from the shared semantic predicate.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Predicate = require "PNC/Semantics/PNC_SemanticPredicate"
PNC.ConvoEngine.SuggestionPredicates = Predicate

return Predicate
