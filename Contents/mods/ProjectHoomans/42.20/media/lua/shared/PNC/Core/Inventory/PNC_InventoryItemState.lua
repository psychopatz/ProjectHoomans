-- Public Inventory value interop. No native or compact inventory mutation.
-- Normal runtime composition initializes the Inventory model before consumers.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}
PNC.Inventory.Queries = PNC.Inventory.Queries or {}
local Queries = PNC.Inventory.Queries
Queries.ItemState = Queries.ItemState or {}
local ItemState = Queries.ItemState
local Codec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

-- Decode the existing Core record state shape without adding validation or
-- changing legacy handling. Callers retain type/quantity interpretation.
ItemState.Decode = Codec.readState

function ItemState.Encode(item, quantity)
    return CoreInventory.encodeItem(Codec.pseudoItem(item), quantity)
end

return ItemState
