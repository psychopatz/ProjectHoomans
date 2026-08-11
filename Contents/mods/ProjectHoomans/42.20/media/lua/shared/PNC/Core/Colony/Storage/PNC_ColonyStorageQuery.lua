PNC = PNC or {}
PNC.ColonyStorageQuery = PNC.ColonyStorageQuery or {}

local Query = PNC.ColonyStorageQuery
local Definitions = require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"
local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function rowFor(record, index)
    local fullType = Inventory.getItemFullType(record[C.TYPE_ID])
        or ("type:" .. tostring(record[C.TYPE_ID]))
    local shortName = string.match(fullType, "%.(.+)$") or fullType
    return {
        recordIndex = index,
        fullType = fullType,
        name = shortName,
        quantity = math.max(1, math.floor(tonumber(record[C.QUANTITY]) or 1)),
        unitWeight = tonumber(record[C.UNIT_WEIGHT]) or 0,
        totalWeight = (tonumber(record[C.UNIT_WEIGHT]) or 0)
            * math.max(1, math.floor(tonumber(record[C.QUANTITY]) or 1)),
        stateful = not ItemRecord.isBatchable(record),
    }
end

function Query.GetVisibleRows(storage, options)
    options = type(options) == "table" and options or {}
    local search = lower(options.search)
    local rows = {}
    for index = 1, #(storage and storage.inventory
        and storage.inventory.records or {}) do
        local row = rowFor(storage.inventory.records[index], index)
        if search == "" or string.find(lower(row.name), search, 1, true)
            or string.find(lower(row.fullType), search, 1, true)
        then
            rows[#rows + 1] = row
        end
    end
    table.sort(rows, function(left, right)
        if options.sort == "weight" then
            if left.totalWeight ~= right.totalWeight then
                return left.totalWeight > right.totalWeight
            end
        elseif options.sort == "quantity" then
            if left.quantity ~= right.quantity then
                return left.quantity > right.quantity
            end
        end
        return lower(left.name) < lower(right.name)
    end)
    return rows
end

function Query.BuildSnapshot(storage, options)
    if not storage or not storage.inventory then return nil end
    local capacity = Definitions.GetCapacity(storage.tier)
    local used = storage.inventory:getWeight()
    local allRows = Query.GetVisibleRows(storage, {})
    local rows = options and (options.search or options.sort)
        and Query.GetVisibleRows(storage, options) or allRows
    local batchCount = 0
    for index = 1, #allRows do
        if allRows[index].quantity > 1 then batchCount = batchCount + 1 end
    end
    return {
        schemaVersion = Definitions.SCHEMA_VERSION,
        storageId = storage.id,
        ownerFactionId = storage.ownerFactionId,
        settlementId = storage.settlementId,
        storageType = storage.storageType,
        tier = storage.tier,
        capacity = capacity,
        usedWeight = used,
        freeWeight = math.max(0, capacity - used),
        overCapacity = used > capacity,
        revision = storage.revision,
        inventoryRevision = storage.inventory.revision,
        logicalItemCount = storage.inventory:getLogicalItemCount(),
        serializedRecordCount = storage.inventory:getRecordCount(),
        batchCount = batchCount,
        uniqueRecordCount = #allRows - batchCount,
        rows = rows,
        activity = Journal.Snapshot(storage),
    }
end

return Query
