-- ProjectHoomans mapping between NPC gameplay metadata and PsychopatzCore records.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

local Bridge = {}
local NPC_SCHEMA = 1

function Bridge.refreshCanonical(record, suppliedInventory)
    local inv = suppliedInventory or Inventory.EnsureRecordInventory(record)
    if not inv then return nil end
    local store = CoreInventory.createVirtualInventory({
        revision = inv.revision,
    })
    -- NPC carry limits drive encumbrance rather than rejecting existing gear.
    -- Apply the persisted capacity after records have been captured.
    local metadataByRecord = {}
    local ids = {}
    for id, _ in pairs(inv.items or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    for i = 1, #ids do
        local item = inv.items[ids[i]]
        local encoded, reason = CoreInventory.encodeItem(StateCodec.pseudoItem(item), item.stack)
        if not encoded then return nil, reason end
        local added
        local ok
        ok, added = store:add(encoded)
        if not ok then return nil, added end
        metadataByRecord[added] = metadataByRecord[added] or {}
        metadataByRecord[added][#metadataByRecord[added] + 1] = StateCodec.metadata(item)
    end
    local meta = {}
    for i = 1, #store.records do meta[i] = metadataByRecord[store.records[i]] or {} end
    store.maxWeight = inv.maxWeight
    inv.coreStore = store
    inv.coreMetadata = meta
    return store, meta
end

function Bridge.serialize(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local store, meta = Bridge.refreshCanonical(record, inv)
    if not store then return nil end
    return {
        NPC_SCHEMA,
        CoreInventory.Serializer.serialize(store),
        meta,
        {
            inv.template and Util.copy(inv.template) or nil,
            tonumber(inv.rootMaxWeight),
        },
    }
end

function Bridge.deserialize(record, payload)
    if type(payload) ~= "table" or tonumber(payload[1]) ~= NPC_SCHEMA then
        return nil, "npc_inventory_schema_mismatch"
    end
    local store, reason = CoreInventory.Serializer.deserialize(payload[2])
    if not store then return nil, reason end
    local inv = Internal.createBaseInventory(record)
    inv.revision = store.revision
    inv.maxWeight = store.maxWeight or inv.maxWeight
    inv.template = type(payload[4]) == "table" and Util.copy(payload[4][1]) or inv.template
    inv.rootMaxWeight = type(payload[4]) == "table" and tonumber(payload[4][2]) or inv.rootMaxWeight
    inv.coreStore = store
    inv.coreMetadata = Util.copy(payload[3])
    record.inventory = inv
    for i = 1, #store.records do
        local coreRecord = store.records[i]
        local fullType = CoreInventory.getItemFullType(coreRecord[C.TYPE_ID])
        if not fullType then return nil, "unknown_type_id" end
        local bucket = type(payload[3]) == "table" and payload[3][i] or nil
        if type(bucket) ~= "table" or #bucket <= 0 then return nil, "npc_inventory_metadata_missing" end
        local assigned = 0
        for j = 1, #bucket do
            local meta = bucket[j]
            local spec = StateCodec.readState(coreRecord)
            StateCodec.applyMetadata(spec, meta, fullType)
            assigned = assigned + math.max(1, math.floor(tonumber(spec.stack) or 1))
            if not Internal.createItem(record, inv, spec) then return nil, "npc_item_create_failed" end
        end
        if assigned ~= coreRecord[C.QUANTITY] then return nil, "npc_inventory_quantity_mismatch" end
    end
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    Internal.refreshNextItemSerial(record, inv)
    return inv
end

local function isLooseMeta(meta)
    return meta[10] == nil and meta[11] == nil and meta[12] == nil
end

function Bridge.materializeLoose(record, body)
    local inv = Inventory.EnsureRecordInventory(record)
    local container = body and body.getInventory and body:getInventory() or nil
    if not inv or not container then return false, "physical_inventory_unavailable" end
    local store, meta = Bridge.refreshCanonical(record, inv)
    local physical = CoreInventory.wrapPhysicalInventory(container)
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

function Bridge.captureLoose(record, body)
    local inv = Inventory.EnsureRecordInventory(record)
    local container = body and body.getInventory and body:getInventory() or nil
    if not inv or not container then return false, "physical_inventory_unavailable" end
    -- Encode the complete physical snapshot before mutating the persistent
    -- model.  A codec failure must leave the previous NPC inventory intact.
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

function Inventory.MaterializeLooseInventory(record, body)
    return Bridge.materializeLoose(record, body)
end

-- Project one newly-added compact item into an already-live NPC body.  The
-- regular materializeLoose path is intentionally a snapshot operation and
-- would duplicate other loose items if it were used for a single transfer.
function Bridge.materializeItem(record, body, itemID)
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

function Inventory.MaterializeItem(record, body, itemID)
    return Bridge.materializeItem(record, body, itemID)
end

function Inventory.CaptureLooseInventory(record, body)
    return Bridge.captureLoose(record, body)
end

Inventory.CoreBridge = Bridge
return Bridge
