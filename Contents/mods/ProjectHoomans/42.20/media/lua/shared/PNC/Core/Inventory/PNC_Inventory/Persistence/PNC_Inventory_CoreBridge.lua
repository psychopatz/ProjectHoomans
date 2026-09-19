-- ProjectHoomans mapping between NPC gameplay metadata and PsychopatzCore records.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal or {}
Inventory.Internal = Internal
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local PhysicalAdapter = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CorePhysicalAdapter"

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
    -- Core's serializer validates records, but malformed nested save payloads
    -- can still raise while it walks the record list. Catch that before this
    -- bridge assigns a new inventory to the NPC record.
    local ok, store, reason = pcall(
        CoreInventory.Serializer.deserialize,
        payload[2]
    )
    if not ok then return nil, "npc_inventory_core_deserialize_failed" end
    if not store then return nil, reason end
    local inv = Internal.createBaseInventory(record)
    inv.revision = store.revision
    inv.maxWeight = store.maxWeight or inv.maxWeight
    inv.template = type(payload[4]) == "table" and Util.copy(payload[4][1]) or inv.template
    inv.rootMaxWeight = type(payload[4]) == "table" and tonumber(payload[4][2]) or inv.rootMaxWeight
    inv.coreStore = store
    inv.coreMetadata = Util.copy(payload[3])
    for i = 1, #store.records do
        local coreRecord = store.records[i]
        local fullType = CoreInventory.getItemFullType(coreRecord[C.TYPE_ID])
        if not fullType then return nil, "unknown_type_id" end
        local bucket = type(payload[3]) == "table" and payload[3][i] or nil
        if type(bucket) ~= "table" or #bucket <= 0 then return nil, "npc_inventory_metadata_missing" end
        local assigned = 0
        for j = 1, #bucket do
            local meta = bucket[j]
            local spec, stateReason = StateCodec.readValidatedState(coreRecord)
            if not spec then return nil, stateReason end
            StateCodec.applyMetadata(spec, meta, fullType)
            assigned = assigned + math.max(1, math.floor(tonumber(spec.stack) or 1))
            if not Internal.createItem(record, inv, spec) then return nil, "npc_item_create_failed" end
        end
        if assigned ~= coreRecord[C.QUANTITY] then return nil, "npc_inventory_quantity_mismatch" end
    end
    record.inventory = inv
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    Internal.refreshNextItemSerial(record, inv)
    return inv
end

function Bridge.materializeLoose(record, body)
    return PhysicalAdapter.materializeLoose(record, body, Bridge)
end

function Bridge.captureLoose(record, body)
    return PhysicalAdapter.captureLoose(record, body)
end

function Inventory.MaterializeLooseInventory(record, body)
    return Bridge.materializeLoose(record, body)
end

-- Project one newly-added compact item into an already-live NPC body.  The
-- regular materializeLoose path is intentionally a snapshot operation and
-- would duplicate other loose items if it were used for a single transfer.
function Bridge.materializeItem(record, body, itemID)
    return PhysicalAdapter.materializeItem(record, body, itemID)
end

function Inventory.MaterializeItem(record, body, itemID)
    return Bridge.materializeItem(record, body, itemID)
end

function Inventory.CaptureLooseInventory(record, body)
    return Bridge.captureLoose(record, body)
end

Inventory.CoreBridge = Bridge
return Bridge
