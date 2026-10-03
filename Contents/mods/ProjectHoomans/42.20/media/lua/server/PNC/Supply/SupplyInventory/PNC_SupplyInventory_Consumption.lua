-- Supply consumption composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SupplyInventory = PNC.SupplyInventory or {}
PNC.SupplyInventoryInternal = PNC.SupplyInventoryInternal or {}

-- Compatibility inventory: function SupplyInventory.Consume is implemented by
-- the transaction provider while remaining visible at this boundary.
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_Consumption_Core"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_Consumption_Physical"
require "PNC/Supply/SupplyInventory/PNC_SupplyInventory_Consumption_Transaction"

return PNC.SupplyInventory
