-- Client adapter from semantic action intents to authoritative command routes.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
require "PNC/Semantics/PNC_SemanticCommandAdapter_CompanionActions"
require "PNC/Semantics/PNC_SemanticCommandAdapter_QuestOperations"
require "PNC/Semantics/PNC_SemanticCommandAdapter_ContextualResponses"
require "PNC/Semantics/PNC_SemanticCommandAdapter_Dispatch"

return PNC.Semantics.CommandAdapter
