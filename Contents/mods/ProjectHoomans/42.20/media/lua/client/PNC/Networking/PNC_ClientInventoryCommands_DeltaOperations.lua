-- Client inventory delta operation adapter.
-- Applies one already-admitted operation and returns a bounded rejection
-- reason for the command handler to turn into an inventory resync.

local Internal = PNC.Client.Internal
local H = Internal.InventoryDelta
if not H then return Internal end

local Core = H.Core
local removeFromContainer = H.removeFromContainer

function H.ApplyInventoryDeltaOperation(inventory, op)
    local item
    local container
    if op.op == "add" and type(op.item) == "table" and op.item.id then
        item = Core.DeepCopy(op.item)
        if inventory.items[item.id] then
            return false, "duplicate_item"
        end
        inventory.items[item.id] = item
        container = inventory.containers[item.container or op.container or "root"]
        if container then
            container.items[#container.items + 1] = item.id
        end
    elseif op.op == "remove" and op.itemID then
        if not inventory.items[op.itemID] then
            return false, "missing_item"
        end
        removeFromContainer(inventory, op.itemID)
        inventory.items[op.itemID] = nil
    elseif op.op == "move" and op.itemID and inventory.items[op.itemID] then
        removeFromContainer(inventory, op.itemID)
        inventory.items[op.itemID].container = op.to
        container = inventory.containers[op.to]
        if container then
            container.items[#container.items + 1] = op.itemID
        end
    elseif op.op == "update" and op.itemID and inventory.items[op.itemID] then
        item = inventory.items[op.itemID]
        if op.stack ~= nil then item.stack = op.stack end
        if op.uses ~= nil then item.uses = op.uses end
        if op.cond ~= nil then item.cond = op.cond end
        if op.itemState ~= nil then
            item.itemState = Core.DeepCopy(op.itemState)
        end
        if op.ammoCount ~= nil then item.ammoCount = op.ammoCount end
        if op.fav ~= nil then item.fav = op.fav == true end
        if op.interactionLocked ~= nil then
            item.interactionLocked = op.interactionLocked == true
            item.interactionLockReason = item.interactionLocked
                and op.interactionLockReason or nil
        end
    elseif op.op == "replace" and op.itemID
        and inventory.items[op.itemID] and op.type
    then
        item = inventory.items[op.itemID]
        item.type = op.type
        if op.itemState ~= nil then
            item.itemState = Core.DeepCopy(op.itemState)
        end
    elseif op.op == "replace" then
        return false, "unsupported_delta"
    elseif op.op == "move" or op.op == "update" then
        return false, "missing_delta_item"
    elseif op.op == "equip" and op.slot then
        inventory.equipped = inventory.equipped or {}
        if op.oldSlot and inventory.equipped[op.oldSlot] == op.itemID then
            inventory.equipped[op.oldSlot] = nil
        end
        if op.previousItemID and inventory.items[op.previousItemID] then
            inventory.items[op.previousItemID].equipSlot = nil
        end
        inventory.equipped[op.slot] = op.itemID
        if op.itemID and inventory.items[op.itemID] then
            inventory.items[op.itemID].equipSlot = op.slot
        end
    elseif op.op == "wear" and op.slot then
        inventory.worn = inventory.worn or {}
        if op.oldSlot and inventory.worn[op.oldSlot] == op.itemID then
            inventory.worn[op.oldSlot] = nil
        end
        if op.previousItemID and inventory.items[op.previousItemID] then
            inventory.items[op.previousItemID].wornSlot = nil
        end
        inventory.worn[op.slot] = op.itemID
        if op.itemID and inventory.items[op.itemID] then
            inventory.items[op.itemID].wornSlot = op.slot
        end
    end
    return true
end

return Internal
