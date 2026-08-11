PNC = PNC or {}
PNC.SupplyIndex = PNC.SupplyIndex or {}

local Index = PNC.SupplyIndex
local Utility = PNC.ItemUtility
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

Index.ByStorage = Index.ByStorage or {}

local function add(bucket, entry)
    bucket[#bucket + 1] = entry
end

local function rebuild(storage)
    local index = {
        revision = storage.inventory.revision,
        FOOD = {}, HYDRATION = {}, MEDICAL = {}, BANDAGE = {},
    }
    for position = 1, #(storage.inventory.records or {}) do
        local record = storage.inventory.records[position]
        local descriptor = Utility.DescribeCoreRecord(record)
        if descriptor then
            local entry = {
                record = record,
                typeId = record[C.TYPE_ID],
                fullType = descriptor.fullType,
                descriptor = descriptor,
            }
            if descriptor.food then add(index.FOOD, entry) end
            if descriptor.hydration then add(index.HYDRATION, entry) end
            if descriptor.bandage then
                add(index.MEDICAL, entry)
                add(index.BANDAGE, entry)
            end
        end
    end
    local function byExpiry(left, right)
        if left.descriptor.unsafe ~= right.descriptor.unsafe then
            return right.descriptor.unsafe == true
        end
        if left.descriptor.expiry ~= right.descriptor.expiry then
            return left.descriptor.expiry > right.descriptor.expiry
        end
        return left.typeId < right.typeId
    end
    table.sort(index.FOOD, byExpiry)
    table.sort(index.HYDRATION, byExpiry)
    table.sort(index.MEDICAL, byExpiry)
    table.sort(index.BANDAGE, byExpiry)
    Index.ByStorage[storage.id] = index
    return index
end

function Index.Get(storage)
    if not storage or not storage.inventory then return nil end
    local cached = Index.ByStorage[storage.id]
    if not cached or cached.revision ~= storage.inventory.revision then
        cached = rebuild(storage)
    end
    return cached
end

function Index.Query(storage, request)
    local index = Index.Get(storage)
    if not index then return {} end
    if request.resourceKind == "MEDICAL" and request.treatment == "BANDAGE" then
        return index.BANDAGE
    end
    return index[request.resourceKind] or {}
end

function Index.Invalidate(storage)
    if storage and storage.id then Index.ByStorage[storage.id] = nil end
end

function Index.AfterRemoval(storage)
    local index = storage and Index.ByStorage[storage.id] or nil
    if not index then return end
    for _, bucketName in ipairs({ "FOOD", "HYDRATION", "MEDICAL", "BANDAGE" }) do
        local bucket = index[bucketName]
        local write = 1
        for read = 1, #bucket do
            local entry = bucket[read]
            if (tonumber(entry.record and entry.record[C.QUANTITY]) or 0) > 0 then
                bucket[write] = entry
                write = write + 1
            end
        end
        while #bucket >= write do table.remove(bucket) end
    end
    index.revision = storage.inventory.revision
end

return Index
