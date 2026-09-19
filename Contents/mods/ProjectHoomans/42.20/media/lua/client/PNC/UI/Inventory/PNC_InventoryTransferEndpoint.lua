require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.InventoryTransferEndpoint = PNC.InventoryTransferEndpoint or {}

require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_LocalDraft"
require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_NPC"
require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Storage"
require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Selection"

return PNC.InventoryTransferEndpoint
