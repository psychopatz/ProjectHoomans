require "ISUI/ISButton"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_Model"
require "PNC/UI/Inventory/PNC_InventoryUI_List"
require "PNC/UI/Inventory/PNC_InventoryUI_ContainerList"
require "PNC/UI/Inventory/PNC_InventoryQuantityModal"
require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint"

PNC = PNC or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"
PNC.InventoryWindow = PNC.InventoryWindow or {}

local UI = PsychopatzCore.UI
ISPNCInventoryWindow = UI.Window:derive("ISPNCInventoryWindow")

require "PNC/UI/Inventory/InventoryWindow/_Helpers"
require "PNC/UI/Inventory/InventoryWindow/_Layout"
require "PNC/UI/Inventory/InventoryWindow/_Endpoint"
require "PNC/UI/Inventory/InventoryWindow/_RefreshControls"
require "PNC/UI/Inventory/InventoryWindow/_Refresh"
require "PNC/UI/Inventory/InventoryWindow/_BulkTransfers"
require "PNC/UI/Inventory/InventoryWindow/_DragDrop"
require "PNC/UI/Inventory/InventoryWindow/_ItemActions"
require "PNC/UI/Inventory/InventoryWindow/_ContainerNavigation"
require "PNC/UI/Inventory/InventoryWindow/_Presentation"
require "PNC/UI/Inventory/InventoryWindow/_Lifecycle"

return PNC.InventoryWindow
