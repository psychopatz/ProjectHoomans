PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

local Delta = {}
local DELTA_SCHEMA = 1

local function equal(left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for key, value in pairs(left) do
        if type(value) == "table" then
            if not equal(value, right[key]) then return false end
        elseif value ~= right[key] then return false end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function encodeItem(item)
    local record, reason = CoreInventory.encodeItem(
        StateCodec.pseudoItem(item), item.stack
    )
    if not record then return nil, reason end
    return { item.templateKey or false, record, StateCodec.metadata(item) }
end

local function equivalent(left, right)
    if not left or not right then return left == right end
    local encodedLeft = encodeItem(left)
    local encodedRight = encodeItem(right)
    if not encodedLeft or not encodedRight
        or not equal(encodedLeft[2], encodedRight[2])
    then return false end
    local leftMeta, rightMeta = encodedLeft[3], encodedRight[3]
    if (leftMeta[3] == nil) ~= (rightMeta[3] == nil) then return false end
    for index = 5, 16 do
        if not equal(leftMeta[index], rightMeta[index]) then return false end
    end
    return true
end

local function buildBaseline(record)
    local runtime = Internal.getRuntimeState(record)
    local nextSerial = runtime and runtime.nextItemSerial or 0
    local baseline = Internal.buildTemplateSnapshot(record)
    if runtime then runtime.nextItemSerial = nextSerial end
    return baseline
end

local function arrayLength(value)
    if value == nil then return 0 end
    if type(value) ~= "table" then return nil end
    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil
        end
        count = count + 1
    end
    if count ~= #value then return nil end
    return count
end

function Delta.build(record, inv)
    local baseline = buildBaseline(record)
    local removed = {}
    local upserts = {}
    for _, baselineItem in pairs(baseline.items or {}) do
        if baselineItem.templateKey
            and not Internal.findItemByTemplateKey(inv, baselineItem.templateKey)
        then
            removed[#removed + 1] = baselineItem.templateKey
        end
    end
    for _, item in pairs(inv.items or {}) do
        local baselineItem = item.templateKey
            and Internal.findItemByTemplateKey(baseline, item.templateKey) or nil
        if not baselineItem or not equivalent(item, baselineItem) then
            local encoded, reason = encodeItem(item)
            if not encoded then return nil, reason end
            upserts[#upserts + 1] = encoded
        end
    end
    table.sort(removed)
    table.sort(upserts, function(left, right)
        return tostring(left[3] and left[3][1] or "")
            < tostring(right[3] and right[3][1] or "")
    end)
    return { DELTA_SCHEMA, removed, upserts }
end

function Delta.isEmpty(delta)
    if type(delta) ~= "table" then return false end
    local removedCount = arrayLength(delta[2])
    local upsertCount = arrayLength(delta[3])
    return removedCount == 0 and upsertCount == 0
end

local function prepareUpsert(upsert)
    if type(upsert) ~= "table" then
        return nil, "delta_upsert_invalid"
    end
    local templateKey = upsert[1]
    if templateKey ~= nil and templateKey ~= false
        and (type(templateKey) ~= "string" or #templateKey == 0)
    then
        return nil, "delta_upsert_invalid"
    end
    local coreRecord = upsert[2]
    local meta = upsert[3]
    if type(coreRecord) ~= "table" or type(meta) ~= "table" then
        return false, "delta_upsert_invalid"
    end
    local fullType = CoreInventory.getItemFullType(coreRecord[C.TYPE_ID])
    if not fullType then return false, "unknown_type_id" end
    local spec, reason = StateCodec.readValidatedState(coreRecord)
    if not spec then return nil, reason or "delta_upsert_invalid" end
    StateCodec.applyMetadata(spec, meta, fullType)
    spec.stack = coreRecord[C.QUANTITY]
    return {
        templateKey = templateKey ~= false and templateKey or nil,
        spec = spec,
    }
end

function Delta.apply(record, inv, delta)
    if type(delta) ~= "table" or tonumber(delta[1]) ~= DELTA_SCHEMA then
        return false, "npc_delta_schema_mismatch"
    end
    if type(record) ~= "table" or type(inv) ~= "table" then
        return false, "npc_delta_target_invalid"
    end
    local removedCount = arrayLength(delta[2])
    local upsertCount = arrayLength(delta[3])
    if removedCount == nil then
        return false, "npc_delta_removed_invalid"
    end
    if upsertCount == nil then
        return false, "npc_delta_upserts_invalid"
    end
    for i = 1, removedCount do
        local templateKey = delta[2][i]
        if type(templateKey) ~= "string" or #templateKey == 0 then
            return false, "npc_delta_removed_invalid"
        end
    end
    local prepared = {}
    for i = 1, upsertCount do
        local entry, reason = prepareUpsert(delta[3][i])
        if not entry then return false, reason end
        prepared[i] = entry
    end
    for i = 1, removedCount do
        local item = Internal.findItemByTemplateKey(inv, delta[2][i])
        if item then Internal.removeItemByID(inv, item.id) end
    end
    for i = 1, upsertCount do
        local entry = prepared[i]
        if entry.templateKey then
            local existing = Internal.findItemByTemplateKey(inv, entry.templateKey)
            if existing then Internal.removeItemByID(inv, existing.id) end
        end
        if not Internal.createItem(record, inv, entry.spec) then
            return false, "delta_item_create_failed"
        end
    end
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    Internal.refreshNextItemSerial(record, inv)
    return true
end

return Delta
