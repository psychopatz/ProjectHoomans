-- Validated, data-only dialogue-flow registry.
--
-- This public entry point preserves the existing registry namespace while
-- loading validation and runtime storage as separate bounded responsibilities.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueFlowRegistry or {}
PNC.Semantics.DialogueFlowRegistry = Registry
local BranchOffers = PNC.Semantics.DialogueBranchOffers
    or require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"

Registry.VERSION = 1
Registry.DEFAULT_MAX_FLOWS = 32
Registry.MAX_NODES = 32
Registry.MAX_TRIGGERS = 8
Registry.MAX_ACCEPTS = 16
Registry.MAX_OFFERS = BranchOffers.MAX_OFFERS
Registry.MAX_TRANSITIONS = 64
Registry.Flows = Registry.Flows or {}
Registry.FlowOrder = Registry.FlowOrder or {}
Registry.Revision = tonumber(Registry.Revision) or 0

require "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Validation"
require "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Runtime"

return Registry
