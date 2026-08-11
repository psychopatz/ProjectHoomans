-- Compatibility and presentation adapter for the pre-framework Storage
-- activity format. Runtime storage is owned by PC_Journals; this module keeps
-- the old save key, compact UI rows, and public Record helpers working.
PNC = PNC or {}
PNC.ColonyStorageJournal = PNC.ColonyStorageJournal or {}

local Journal = PNC.ColonyStorageJournal
local Events = require "PsychopatzCore/Events/PC_EventBus"
local Journals = require "PsychopatzCore/Journal/PC_JournalService"
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

Journal.VERSION = 2
Journal.LEGACY_VERSION = 1
Journal.MAX_ENTRIES = 10
Journal.TYPE = "projecthoomans.colonyActivity"
Journal.OPERATION = { TAKE = 1, STORE = 2 }
Journal.FIELD = {
    OPERATION = 1, WORLD_MINUTE = 2, ACTOR = 3,
    TYPE_ID = 4, QUANTITY = 5, REASON = 6,
}

-- Shared/client loads need the type for snapshot reads even though only the
-- authority-side route accepts canonical writes.
if not Journals.getType(Journal.TYPE) then
    Journals.registerType(Journal.TYPE, {
        storage = "boundedRing", capacity = Journal.MAX_ENTRIES,
        persistent = true,
    })
end

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

local function eventForOperation(operation)
    return operation == Journal.OPERATION.TAKE
        and EventTypes.STORAGE_ITEM_WITHDRAWN
        or operation == Journal.OPERATION.STORE
            and EventTypes.STORAGE_ITEM_DEPOSITED or nil
end

local function legacyEntry(raw)
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

local function subject(storageOrID)
    return type(storageOrID) == "table" and storageOrID.id or storageOrID
end

function Journal.Record(storageOrID, spec)
    spec = type(spec) == "table" and spec or {}
    local storageID = subject(storageOrID)
    local operation = operationCode(spec.operation)
    local eventType = eventForOperation(operation)
    local typeID = itemTypeID(spec)
    local quantity = math.floor(tonumber(spec.quantity) or 0)
    if not storageID or not eventType or typeID <= 0 or quantity <= 0 then
        return false, "invalid_activity"
    end
    Events.emit(eventType, tostring(storageID), tostring(spec.actor or ""),
        typeID, quantity, reasonToken(spec.reason),
        spec.worldMinute or worldMinute())
    return true
end

function Journal.RecordMany(storageOrID, operation, actor, items, reason)
    local grouped = {}
    local order = {}
    for _, item in ipairs(type(items) == "table" and items or {}) do
        local typeID = itemTypeID(item)
        local quantity = math.max(0, math.floor(
            tonumber(item and item.quantity) or 0))
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
        if Journal.Record(storageOrID, {
            operation = operation, actor = actor, typeId = typeID,
            quantity = grouped[typeID], reason = reason,
        }) then recorded = recorded + 1 end
    end
    return recorded
end

function Journal.Snapshot(storageOrID)
    local output = {}
    for _, entry in ipairs(Journals.getRecent(Journal.TYPE,
        subject(storageOrID))) do
        local operation = entry[1] == EventTypes.STORAGE_ITEM_WITHDRAWN
            and Journal.OPERATION.TAKE
            or entry[1] == EventTypes.STORAGE_ITEM_DEPOSITED
                and Journal.OPERATION.STORE or nil
        if operation then
            output[#output + 1] = legacyEntry({
                operation, entry[2], entry[3], entry[4], entry[5], entry[6],
            })
        end
    end
    return output
end

function Journal.Serialize(storageOrID)
    return { Journal.VERSION, Journals.export(Journal.TYPE,
        subject(storageOrID)) or { version = 1, storage = "boundedRing",
            entries = {} } }
end

function Journal.Deserialize(payload, storageID)
    Journals.remove(Journal.TYPE, storageID)
    if type(payload) ~= "table" then return false end
    if tonumber(payload[1]) == Journal.VERSION then
        return Journals.import(Journal.TYPE, storageID, payload[2] or {})
    end
    if tonumber(payload[1]) ~= Journal.LEGACY_VERSION then return false end
    local entries = {}
    for _, raw in ipairs(type(payload[2]) == "table" and payload[2] or {}) do
        local old = legacyEntry(raw)
        local eventType = old and eventForOperation(old[1]) or nil
        if eventType then
            entries[#entries + 1] = {
                eventType, old[2], old[3], old[4], old[5], old[6],
            }
        end
    end
    return Journals.import(Journal.TYPE, storageID, { entries = entries })
end

function Journal.Remove(storageOrID)
    return Journals.remove(Journal.TYPE, subject(storageOrID))
end

return Journal
