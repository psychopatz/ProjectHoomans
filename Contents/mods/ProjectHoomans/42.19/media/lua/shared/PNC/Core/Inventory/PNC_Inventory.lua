--[[
    PNC Inventory
    Stable public entry point for the split inventory subsystem.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
Inventory.Internal = Inventory.Internal or {}

require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Equipment"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Payloads"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Persistence"
