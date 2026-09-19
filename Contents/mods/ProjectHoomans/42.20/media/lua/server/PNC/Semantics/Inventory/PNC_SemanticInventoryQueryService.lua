-- Server-authoritative, read-only inventory answers for semantic dialogue.
--
-- The facade preserves PNC.Semantics.InventoryQueryService while loading the
-- item query, bounded result, and request admission responsibilities in order.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Contract = PNC.Semantics.InventoryQuery
    or require "PNC/Semantics/PNC_SemanticInventoryQuery"
local Selector = PNC.Semantics.ItemSelector
    or require "PNC/Semantics/Inventory/PNC_SemanticItemSelector"
local Service = PNC.Semantics.InventoryQueryService or {}
PNC.Semantics.InventoryQueryService = Service
Service.VERSION = 1
Service.MAX_ITEMS = 256
Service.MAX_RESULTS = 12
Service.Internal = Service.Internal or {}
Service.Internal.Contract = Contract
Service.Internal.Selector = Selector
Service.Internal.Diagnostics = PNC.Semantics.SemanticDiagnostics

require "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService_QueryCandidates"
require "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService_Query"
require "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService_Request"

return Service
