-- Compatibility façade for suggestion policy.
-- All typed predicate semantics now come from the shared semantic predicate.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Predicate = require "PNC/Semantics/PNC_SemanticPredicate"
PNC.Semantics.SuggestionPredicates = Predicate

return Predicate
