-- Data-driven NPC inventory actions shared by the UI and server authority.
PNC = PNC or {}
PNC.InventoryActions = PNC.InventoryActions or {}

local Actions = PNC.InventoryActions
Actions.Definitions = Actions.Definitions or {}
Actions.Order = Actions.Order or {}

require "PNC/Core/Inventory/InventoryActions/PNC_InventoryActions_Registry"
require "PNC/Core/Inventory/InventoryActions/PNC_InventoryActions_Definitions"

return Actions
