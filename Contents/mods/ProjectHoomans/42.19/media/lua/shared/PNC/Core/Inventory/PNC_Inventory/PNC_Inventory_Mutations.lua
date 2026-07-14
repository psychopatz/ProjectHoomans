--[[
    PNC Inventory Mutations
    Validated add/move/remove/update operations and revision logging.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function applyAddOperation(record, inv, op)
    local item
    if type(op.item) ~= "table" then
        return nil
    end
    item = Internal.createItem(record, inv, op.item)
    if not item then
        return nil
    end
    return Internal.buildOperation("add", {
        item = Internal.itemToPayload(item),
        container = item.container,
    })
end

local function applyMoveOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local destination = Internal.normalizeString(op.to)
    local item
    if not itemID or not destination then
        return nil
    end
    item = inv.items[op.itemID]
    if not item or not Internal.setItemContainer(inv, item, op.to) then
        return nil
    end
    return Internal.buildOperation("move", {
        itemID = item.id,
        to = item.container,
    })
end

local function applyRemoveOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    if not itemID or not inv.items[op.itemID] or not Internal.removeItemByID(inv, op.itemID) then
        return nil
    end
    return Internal.buildOperation("remove", { itemID = op.itemID })
end

local function applyUpdateOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local item = itemID and inv.items[op.itemID] or nil
    if not item then
        return nil
    end
    if op.stack ~= nil then
        item.stack = math.max(1, math.floor(tonumber(op.stack) or item.stack or 1))
    end
    if op.uses ~= nil then
        item.uses = tonumber(op.uses)
    end
    if op.cond ~= nil then
        item.cond = tonumber(op.cond)
    end
    return Internal.buildOperation("update", {
        itemID = item.id,
        stack = item.stack,
        uses = item.uses,
        cond = item.cond,
    })
end

local function applyInventoryOperation(record, inv, op)
    if type(op) ~= "table" then
        return nil
    end
    if op.op == "add" then
        return applyAddOperation(record, inv, op)
    end
    if op.op == "move" then
        return applyMoveOperation(inv, op)
    end
    if op.op == "remove" then
        return applyRemoveOperation(inv, op)
    end
    if op.op == "update" then
        return applyUpdateOperation(inv, op)
    end
    return nil
end

function Inventory.ApplyDelta(record, ops, reason)
    local inv = Inventory.EnsureRecordInventory(record)
    local appliedOps = {}
    local applied
    local i
    if type(ops) ~= "table" then
        return false
    end
    for i = 1, #ops do
        applied = applyInventoryOperation(record, inv, ops[i])
        if applied then
            appliedOps[#appliedOps + 1] = applied
        end
    end
    if #appliedOps <= 0 then
        return false
    end
    Internal.bumpRevision(record, appliedOps, reason)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return true
end
