require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.InventoryUIModel = PNC.InventoryUIModel or {}

require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Grouping"
require "PNC/UI/Inventory/PNC_InventoryUI_Model/_PlayerContainers"
require "PNC/UI/Inventory/PNC_InventoryUI_Model/_PlayerRows"
require "PNC/UI/Inventory/PNC_InventoryUI_Model/_NPCRows"
require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Weights"

return PNC.InventoryUIModel
