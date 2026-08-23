-- Stable entry point for inventory item state, construction, and caches.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_State"
require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Metadata"
require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Payloads"
require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Construction"
require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Weights"

return PNC.Inventory
