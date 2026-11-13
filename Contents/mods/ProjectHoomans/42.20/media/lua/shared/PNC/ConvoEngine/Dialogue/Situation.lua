-- Bounded semantic dialogue situation composition root.
-- Source/rules, activity/needs, emotional state, and public projection load in order.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
PNC.ConvoEngine.DialogueSituation = PNC.ConvoEngine.DialogueSituation or {}

require "PNC/ConvoEngine/Dialogue/Situation_Core"
require "PNC/ConvoEngine/Dialogue/Situation_Activity"
require "PNC/ConvoEngine/Dialogue/Situation_State"
require "PNC/ConvoEngine/Dialogue/Situation_Public"

return PNC.ConvoEngine.DialogueSituation
