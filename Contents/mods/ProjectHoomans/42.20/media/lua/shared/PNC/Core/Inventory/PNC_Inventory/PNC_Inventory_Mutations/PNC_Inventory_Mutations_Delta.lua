local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function applyAddOperation(record, inv, op)
    local item
    if type(op.item) ~= "table" then return nil end
    item = Internal.createItem(record, inv, op.item)
    if not item then return nil end
    return Internal.buildOperation("add", {
        item = Internal.itemToNetworkPayload(item),
        container = item.container,
    })
end

local function applyMoveOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local destination = Internal.normalizeString(op.to)
    local item
    if not itemID or not destination then return nil end
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
    if not itemID or not inv.items[op.itemID]
        or not Internal.removeItemByID(inv, op.itemID)
    then
        return nil
    end
    return Internal.buildOperation("remove", { itemID = op.itemID })
end

local function applyReplaceOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local item = itemID and inv.items[op.itemID] or nil
    local fullType = Internal.normalizeItemType(op.type)
    if not item or not fullType or fullType == item.type then return nil end
    item.type = fullType
    if op.itemState ~= nil then
        item.itemState = Internal.sanitizeItemState(op.itemState)
        if Inventory.NormalizeItemState then
            Inventory.NormalizeItemState(item)
        end
    end
    return Internal.buildOperation("replace", {
        itemID = item.id,
        type = item.type,
        itemState = Internal.sanitizeNetworkItemState(
            item.itemState, item
        ),
    })
end

local function applyUpdateOperation(inv, op)
    local itemID = Internal.normalizeString(op.itemID)
    local item = itemID and inv.items[op.itemID] or nil
    if not item then return nil end
    if op.stack ~= nil then
        item.stack = math.max(1,
            math.floor(tonumber(op.stack) or item.stack or 1))
    end
    if op.uses ~= nil then item.uses = tonumber(op.uses) end
    if op.cond ~= nil then item.cond = tonumber(op.cond) end
    if op.itemState ~= nil then
        item.itemState = Internal.sanitizeItemState(op.itemState)
        if Inventory.NormalizeItemState then
            Inventory.NormalizeItemState(item)
        end
    end
    if op.ammoCount ~= nil then
        item.ammoCount = math.max(0,
            math.floor(tonumber(op.ammoCount) or item.ammoCount or 0))
    end
    if op.fav ~= nil then item.fav = op.fav == true end
    if op.interactionLocked ~= nil then
        item.interactionLocked = op.interactionLocked == true
        item.interactionLockReason = item.interactionLocked
            and Internal.normalizeString(op.interactionLockReason)
            or nil
    elseif op.interactionLockReason ~= nil then
        item.interactionLockReason = Internal.normalizeString(
            op.interactionLockReason
        )
    end
    local applied = { itemID = item.id }
    if op.stack ~= nil then applied.stack = item.stack end
    if op.uses ~= nil then applied.uses = item.uses end
    if op.cond ~= nil then applied.cond = item.cond end
    if op.itemState ~= nil then
        applied.itemState = Internal.sanitizeNetworkItemState(
            item.itemState, item
        )
    end
    if op.ammoCount ~= nil then applied.ammoCount = item.ammoCount end
    if op.fav ~= nil then applied.fav = item.fav == true end
    if op.interactionLocked ~= nil then
        applied.interactionLocked = item.interactionLocked == true
        applied.interactionLockReason = item.interactionLockReason
    elseif op.interactionLockReason ~= nil then
        applied.interactionLockReason = item.interactionLockReason
    end
    return Internal.buildOperation("update", applied)
end

local function applyInventoryOperation(record, inv, op)
    if type(op) ~= "table" then return nil end
    if op.op == "add" then return applyAddOperation(record, inv, op) end
    if op.op == "move" then return applyMoveOperation(inv, op) end
    if op.op == "remove" then return applyRemoveOperation(inv, op) end
    if op.op == "replace" then return applyReplaceOperation(inv, op) end
    if op.op == "update" then return applyUpdateOperation(inv, op) end
    return nil
end

function Inventory.ApplyDelta(record, ops, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local appliedOps = {}
    local applied
    local i
    if type(ops) ~= "table" then return false, {} end
    for i = 1, #ops do
        applied = applyInventoryOperation(record, inv, ops[i])
        if applied then appliedOps[#appliedOps + 1] = applied end
    end
    if #appliedOps <= 0 then return false, {} end
    Internal.bumpRevision(record, appliedOps, reason)
    if inv.persistenceMode ~= "FULL" then
        inv.persistenceMode = "BASELINE_DELTA"
    end
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    Events.emit(EventTypes.NPC_INVENTORY_CHANGED, record, appliedOps, reason)
    return true, appliedOps
end

return Inventory
