-- Validated inventory mutations and revision logging.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Delta"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Items"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Flags"
require "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Equipment"

-- Restore an already captured transaction checkpoint. This is an authority
-- operation, never a client payload: preserve the snapshot identity/revision
-- and the existing cache-rebuild order; the caller owns physical undo.
function PNC.Inventory.RestoreSnapshot(record, snapshot)
    record.inventory = snapshot
    PNC.Inventory.RebuildCaches(record)
end

return PNC.Inventory
