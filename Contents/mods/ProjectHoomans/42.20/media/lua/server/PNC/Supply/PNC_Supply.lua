-- Canonical server entry for Supply. Require order is contractual.

PNC = PNC or {}
PNC.Supply = PNC.Supply or {}

require "PNC/Supply/PNC_SupplyRequest"
require "PNC/Supply/PNC_SupplyMetrics"
require "PNC/Supply/PNC_ItemUtility"
require "PNC/Supply/PNC_SupplyIndex"
require "PNC/Supply/PNC_SupplySelector"
require "PNC/Supply/PNC_StorageAccessPolicy"
require "PNC/Supply/PNC_SupplyInventory"
require "PNC/Supply/PNC_NPCSupplyService"

local Supply = PNC.Supply
Supply.Commands = PNC.SupplyInventory.Commands
Supply.Queries = PNC.SupplyInventory.Queries
Supply.Process = PNC.NPCSupplyService.Process

return Supply
