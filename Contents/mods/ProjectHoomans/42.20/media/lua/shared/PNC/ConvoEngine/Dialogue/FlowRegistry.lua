-- Validated, data-only dialogue-flow registry.
--
-- This public entry point preserves the existing registry namespace while
-- loading validation and runtime storage as separate bounded responsibilities.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Registry = PNC.ConvoEngine.DialogueFlowRegistry or {}
PNC.ConvoEngine.DialogueFlowRegistry = Registry
local BranchOffers = PNC.ConvoEngine.DialogueBranchOffers
    or require "PNC/ConvoEngine/Dialogue/BranchOffers"

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

require "PNC/ConvoEngine/Dialogue/FlowRegistry_Validation"
require "PNC/ConvoEngine/Dialogue/FlowRegistry_Runtime"

return Registry
