-- Compatibility seam for existing PNC callers.
--
-- Predicate language/evaluation is Core-owned.  PNC keeps this module path
-- only so existing semantic/director callers consume the public Core contract
-- without a duplicate evaluator.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Predicate = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
PNC.Semantics.Predicate = Predicate

return Predicate
