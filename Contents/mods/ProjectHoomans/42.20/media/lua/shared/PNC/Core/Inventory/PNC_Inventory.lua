--[[
    PNC Inventory
    Stable public entry point for the split inventory subsystem.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
Inventory.Internal = Inventory.Internal or {}
Inventory.Queries = Inventory.Queries or {}

require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model"
require "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_FoodLifecycle"
require "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_EquipmentPools"
require "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_EquipmentGeneration"
require "PNC/Core/Inventory/PNC_Inventory_NativeCapture"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Equipment"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_WaterContainers"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Payloads"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Persistence"
require "PNC/Core/Inventory/PNC_InventoryItemState"

Inventory.Queries.GetItemWeight = Inventory.Internal.getItemWeight
Inventory.Queries.ToDefinitionSpec = Inventory.Internal.itemToDefinitionSpec

Inventory.Commands = Inventory.Commands or {}

Inventory.Commands.EnsureRecordInventory = Inventory.EnsureRecordInventory
Inventory.Commands.ApplyDelta = Inventory.ApplyDelta
Inventory.Commands.AddItems = Inventory.AddItems
Inventory.Commands.RemoveItems = Inventory.RemoveItems
Inventory.Commands.RebuildCaches = Inventory.RebuildCaches
Inventory.Commands.RestoreSnapshot = Inventory.RestoreSnapshot
Inventory.Commands.SetWaterContainer = Inventory.SetWaterContainer
Inventory.Commands.ClearWaterContainer = Inventory.ClearWaterContainer
Inventory.Commands.AdvanceFoodLifecycle = Inventory.AdvanceFoodLifecycle

require "PNC/Core/Inventory/PNC_InventoryRepository"
