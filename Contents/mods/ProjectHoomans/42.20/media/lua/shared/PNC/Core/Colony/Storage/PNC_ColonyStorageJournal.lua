PNC = PNC or {}
PNC.ColonyStorageJournal = PNC.ColonyStorageJournal or {}

local Journal = PNC.ColonyStorageJournal
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

Journal.VERSION = 1
Journal.MAX_ENTRIES = 10
Journal.OPERATION = { TAKE = 1, STORE = 2 }
Journal.FIELD = {
    OPERATION = 1,
    WORLD_MINUTE = 2,
    ACTOR = 3,
    TYPE_ID = 4,
    QUANTITY = 5,
    REASON = 6,
}

local function worldMinute()
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    return math.max(0, math.floor(hours * 60 + 0.5))
end

local function operationCode(value)
    if value == Journal.OPERATION.TAKE or value == Journal.OPERATION.STORE then
        return value
    end
    return Journal.OPERATION[string.upper(tostring(value or ""))]
end

local function reasonToken(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w_.%-]", "_")
    return string.sub(value, 1, 32)
end

local function itemTypeID(spec)
    local value = math.floor(tonumber(spec and spec.typeId) or 0)
    if value > 0 then return value end
    return Inventory.getItemTypeId(spec and spec.fullType, false)
end

local function sanitizeEntry(raw)
    if type(raw) ~= "table" then return nil end
    local operation = operationCode(raw[Journal.FIELD.OPERATION])
    local typeID = math.floor(tonumber(raw[Journal.FIELD.TYPE_ID]) or 0)
    local quantity = math.floor(tonumber(raw[Journal.FIELD.QUANTITY]) or 0)
    if not operation or typeID <= 0 or quantity <= 0 then return nil end
    return {
        operation,
        math.max(0, math.floor(tonumber(raw[Journal.FIELD.WORLD_MINUTE]) or 0)),
        string.sub(tostring(raw[Journal.FIELD.ACTOR] or ""), 1, 48),
        typeID,
        math.min(quantity, 2147483647),
        reasonToken(raw[Journal.FIELD.REASON]),
    }
end

function Journal.Ensure(storage)
    if type(storage) ~= "table" then return nil end
    storage.activityJournal = type(storage.activityJournal) == "table"
        and storage.activityJournal or {}
    while #storage.activityJournal > Journal.MAX_ENTRIES do
        table.remove(storage.activityJournal, 1)
    end
    return storage.activityJournal
end

function Journal.Record(storage, spec)
    spec = type(spec) == "table" and spec or {}
    local typeID = itemTypeID(spec)
    local entry = sanitizeEntry({
        operationCode(spec.operation),
        spec.worldMinute or worldMinute(),
        spec.actor,
        typeID,
        spec.quantity,
        spec.reason,
    })
    local entries = Journal.Ensure(storage)
    if not entries or not entry then return false, "invalid_activity" end
    entries[#entries + 1] = entry
    while #entries > Journal.MAX_ENTRIES do table.remove(entries, 1) end
    return true, entry
end

function Journal.RecordMany(storage, operation, actor, items, reason)
    local grouped = {}
    local order = {}
    for _, item in ipairs(type(items) == "table" and items or {}) do
        local typeID = itemTypeID(item)
        local quantity = math.max(0, math.floor(
            tonumber(item and item.quantity) or 0
        ))
        if typeID and typeID > 0 and quantity > 0 then
            if not grouped[typeID] then
                grouped[typeID] = 0
                order[#order + 1] = typeID
            end
            grouped[typeID] = grouped[typeID] + quantity
        end
    end
    local recorded = 0
    for _, typeID in ipairs(order) do
        if Journal.Record(storage, {
            operation = operation,
            actor = actor,
            typeId = typeID,
            quantity = grouped[typeID],
            reason = reason,
        }) then recorded = recorded + 1 end
    end
    return recorded
end

function Journal.Serialize(storage)
    local output = { Journal.VERSION, {} }
    for _, raw in ipairs(Journal.Ensure(storage) or {}) do
        local entry = sanitizeEntry(raw)
        if entry then output[2][#output[2] + 1] = entry end
    end
    return output
end

function Journal.Deserialize(payload)
    local output = {}
    if type(payload) ~= "table" or tonumber(payload[1]) ~= Journal.VERSION then
        return output
    end
    for _, raw in ipairs(type(payload[2]) == "table" and payload[2] or {}) do
        local entry = sanitizeEntry(raw)
        if entry then output[#output + 1] = entry end
    end
    while #output > Journal.MAX_ENTRIES do table.remove(output, 1) end
    return output
end

function Journal.Snapshot(storage)
    return Journal.Serialize(storage)[2]
end

return Journal
