-- Bounded semantic dialogue situation composition root.
-- Source/rules, activity/needs, emotional state, and public projection load in order.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.DialogueSituation = PNC.Semantics.DialogueSituation or {}

require "PNC/Semantics/PNC_SemanticDialogueSituation_Core"
require "PNC/Semantics/PNC_SemanticDialogueSituation_Activity"
require "PNC/Semantics/PNC_SemanticDialogueSituation_State"
require "PNC/Semantics/PNC_SemanticDialogueSituation_Public"

return PNC.Semantics.DialogueSituation
