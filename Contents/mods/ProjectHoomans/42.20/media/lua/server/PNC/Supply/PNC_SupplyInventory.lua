-- Stable supply-inventory entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SupplyInventory = PNC.SupplyInventory or {}

require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_CoreRecords"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_NativeMatching"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_Consumption"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_Removal"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_PersonalQueries"

return PNC.SupplyInventory
