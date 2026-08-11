-- PNC inventory persistence facade.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Bridge = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreBridge"

function Inventory.Serialize(record)
    return Bridge.serialize(record)
end

function Inventory.Deserialize(record, rawInventory)
    if not record then return nil end
    if type(rawInventory) ~= "table" then
        return Inventory.CreateFromTemplate(record)
    end
    local inv, reason = Bridge.deserialize(record, rawInventory)
    if not inv and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("PNC inventory rejected payload: " .. tostring(reason))
    end
    return inv or Inventory.CreateFromTemplate(record)
end
