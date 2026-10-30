-- Domain registration: Semantics. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Semantics/PNC_SemanticCognitionEvidence"
require "PNC/Semantics/PNC_SemanticEngineEvents_Server"
require "PNC/Semantics/PNC_SemanticCombatReactionService"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts"
require "PNC/Semantics/PNC_SemanticInteractionSceneAdopters"
