-- Projects compact inventory records to and from a live PZ body inventory.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local Internal = Inventory.Internal
local Adapter = Internal.CorePhysicalAdapter or {}
Internal.CorePhysicalAdapter = Adapter

local function isLooseMeta(meta)
    return meta[10] == nil and meta[11] == nil and meta[12] == nil
end

function Adapter.materializeLoose(record, body, bridge)
    local inv = Inventory.EnsureRecordInventory(record)
    local container = body and body.getInventory and body:getInventory() or nil
    if not inv or not container then return false, "physical_inventory_unavailable" end
    local store, meta = bridge.refreshCanonical(record, inv)
    if not store then return false, meta or "inventory_snapshot_unavailable" end
    local physical, reason = CoreInventory.wrapPhysicalInventory(container)
    if not physical then return false, reason or "physical_inventory_unavailable" end
    for i = 1, #store.records do
        local bucket = meta[i] or {}
        for j = 1, #bucket do
            if isLooseMeta(bucket[j]) then
                local materialized = CoreInventory.ItemRecord.clone(store.records[i], bucket[j][2])
                local ok, reason = physical:add(materialized)
                if not ok then return false, reason end
            end
        end
    end
    return true
end

local function collectPresentationItems(body)
    local excluded = {}
    local item
    if not body then return excluded end
    item = body.getPrimaryHandItem and body:getPrimaryHandItem() or nil
    if item then excluded[item] = true end
    item = body.getSecondaryHandItem and body:getSecondaryHandItem() or nil
    if item then excluded[item] = true end
    local worn = body.getWornItems and body:getWornItems() or nil
    if worn and worn.size and worn.get then
        for i = 0, worn:size() - 1 do
            local entry = worn:get(i)
            item = entry and entry.getItem and entry:getItem() or nil
            if item then excluded[item] = true end
        end
    end
    return excluded
end

function Adapter.captureLoose(record, body)
    local inv = Inventory.EnsureRecordInventory(record)
    local container = body and body.getInventory and body:getInventory() or nil
    if not inv or not container then return false, "physical_inventory_unavailable" end
    -- Encode the complete physical snapshot before mutating the persistent
    -- model. A codec failure must leave the previous NPC inventory intact.
    local capturedSpecs = {}
    local excluded = collectPresentationItems(body)
    local physical = CoreInventory.wrapPhysicalInventory(container)
    local iterator = physical:iterate()
    while true do
        local nativeItem = iterator()
        if not nativeItem then break end
        if not excluded[nativeItem] then
            local encoded, reason = CoreInventory.encodeItem(nativeItem, 1)
            if not encoded then return false, reason end
            local fullType = CoreInventory.getItemFullType(encoded[C.TYPE_ID])
            if not fullType then return false, "npc_item_type_unavailable" end
            local spec = StateCodec.readState(encoded)
            spec.type, spec.container = fullType, "root"
            spec.origin = "world"
            capturedSpecs[#capturedSpecs + 1] = spec
        end
    end

    local removeIds = {}
    for itemId, item in pairs(inv.items or {}) do
        if not item.wornSlot and not item.attachedSlot and not item.equipSlot then
            removeIds[#removeIds + 1] = itemId
        end
    end
    table.sort(removeIds)
    local ops = {}
    for i = 1, #removeIds do
        ops[#ops + 1] = { op = "remove", itemID = removeIds[i] }
    end
    for i = 1, #capturedSpecs do
        ops[#ops + 1] = { op = "add", item = capturedSpecs[i] }
    end
    if #ops > 0 then
        local applied, appliedOps = Inventory.ApplyDelta(
            record, ops, "physical_inventory_capture")
        if not applied or #appliedOps ~= #ops then
            return false, "npc_item_capture_failed"
        end
    else
        Inventory.SyncEquipmentFromInventory(record)
        Inventory.RebuildCaches(record)
    end
    return true
end

function Adapter.materializeItem(record, body, itemID)
    local inv = Inventory.EnsureRecordInventory(record)
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    local container = body and body.getInventory and body:getInventory() or nil
    local encoded
    local physical
    local addOK
    local addedItems
    local reason
    if not item or not container then
        return false, "physical_inventory_unavailable"
    end
    encoded, reason = CoreInventory.encodeItem(
        StateCodec.pseudoItem(item), 1)
    if not encoded then return false, reason or "item_encode_failed" end
    physical, reason = CoreInventory.wrapPhysicalInventory(container)
    if not physical then return false, reason end
    addOK, addedItems = physical:add(encoded)
    if not addOK then return false, addedItems or "physical_add_failed" end
    local addedItem = addedItems and addedItems[1]
    return true, "materialized", function()
        if addedItem then physical:_nativeRemove(addedItem) end
    end
end

return Adapter
