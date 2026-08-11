PNC = PNC or {}
PNC.ColonyStorageViewModel = PNC.ColonyStorageViewModel or {}

local ViewModel = PNC.ColonyStorageViewModel
local InventoryModel = PNC.InventoryUIModel
    or require "PNC/UI/Inventory/PNC_InventoryUI_Model"

local function lower(value)
    return string.lower(tostring(value or ""))
end

function ViewModel.GetVisibleRows(storage, search, sort)
    search = lower(search)
    sort = tostring(sort or "name")
    local rows = {}
    for _, row in ipairs(storage and storage.rows or {}) do
        if search == "" or string.find(lower(row.name), search, 1, true)
            or string.find(lower(row.fullType), search, 1, true)
        then rows[#rows + 1] = row end
    end
    table.sort(rows, function(left, right)
        if sort == "quantity" and left.quantity ~= right.quantity then
            return left.quantity > right.quantity
        end
        if sort == "weight" and left.totalWeight ~= right.totalWeight then
            return left.totalWeight > right.totalWeight
        end
        return lower(left.name) < lower(right.name)
    end)
    return rows
end

function ViewModel.BuildInventoryRows(storage, search, sort, collapsedGroups)
    local categories = {}
    local order = {}
    collapsedGroups = type(collapsedGroups) == "table" and collapsedGroups or {}
    for _, row in ipairs(ViewModel.GetVisibleRows(storage, search, sort)) do
        local metadata = InventoryModel.Probe(row.fullType)
        local category = tostring(metadata.category or "Item")
        local bucket = categories[category]
        if not bucket then
            bucket = { name = category, rows = {}, quantity = 0, weight = 0 }
            categories[category] = bucket
            order[#order + 1] = bucket
        end
        local quantity = math.max(1, math.floor(tonumber(row.quantity) or 1))
        bucket.quantity = bucket.quantity + quantity
        bucket.weight = bucket.weight + (tonumber(row.totalWeight) or 0)
        bucket.rows[#bucket.rows + 1] = {
            source = "storage",
            id = tostring(row.recordIndex or ""),
            fullType = row.fullType,
            name = tostring(metadata.name or row.name or row.fullType),
            category = category,
            texture = metadata.texture,
            weight = tonumber(row.totalWeight) or 0,
            stack = quantity,
            recordIndex = row.recordIndex,
            storageRecord = row,
            restricted = false,
            groupChild = true,
        }
    end
    table.sort(order, function(a, b) return lower(a.name) < lower(b.name) end)
    local output = {}
    for _, bucket in ipairs(order) do
        local key = "storage-category:" .. lower(bucket.name)
        output[#output + 1] = {
            source = "storage",
            name = bucket.name,
            category = tostring(#bucket.rows) .. " types",
            texture = bucket.rows[1] and bucket.rows[1].texture or nil,
            stack = bucket.quantity,
            weight = bucket.weight,
            groupHeader = true,
            groupKey = key,
            expanded = collapsedGroups[key] ~= true,
            restricted = true,
        }
        if collapsedGroups[key] ~= true then
            for _, child in ipairs(bucket.rows) do
                child.groupKey = key
                output[#output + 1] = child
            end
        end
    end
    return output
end

function ViewModel.GetCapacity(storage)
    return storage and tonumber(storage.capacity) or 0
end

function ViewModel.GetTotalWeight(storage)
    return storage and tonumber(storage.usedWeight) or 0
end

function ViewModel.GetTier(storage)
    return storage and tonumber(storage.tier) or 0
end

function ViewModel.GetLogicalItemCount(storage)
    return storage and tonumber(storage.logicalItemCount) or 0
end

return ViewModel
