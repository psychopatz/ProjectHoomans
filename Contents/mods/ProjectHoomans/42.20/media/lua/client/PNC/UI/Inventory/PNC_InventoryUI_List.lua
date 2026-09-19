require "ISUI/ISScrollingListBox"
require "ISUI/ISContextMenu"

PNC = PNC or {}
ISPNCInventoryList = ISScrollingListBox:derive("ISPNCInventoryList")

require "PNC/UI/Inventory/PNC_InventoryUI_List/_Appearance"
require "PNC/UI/Inventory/PNC_InventoryUI_List/_Input"
require "PNC/UI/Inventory/PNC_InventoryUI_List/_Lifecycle"

return ISPNCInventoryList
