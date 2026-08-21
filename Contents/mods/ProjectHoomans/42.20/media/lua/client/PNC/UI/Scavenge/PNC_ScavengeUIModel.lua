PNC = PNC or {}
PNC.ScavengeUIModel = PNC.ScavengeUIModel or {}

local Model = PNC.ScavengeUIModel

local function sourceFallback(entry)
    local kind = entry.sourceType == "floor" and "Floor"
        or entry.sourceType == "corpse" and "Corpse" or "Container"
    return string.format("%s at %d, %d, %d", kind,
        tonumber(entry.x) or 0, tonumber(entry.y) or 0,
        tonumber(entry.z) or 0)
end

local function itemGroups(entries)
    local buckets, order = {}, {}
    for _, entry in ipairs(entries or {}) do
        local key = tostring(entry.fullType or "")
        local bucket = buckets[key]
        if not bucket then
            bucket = { key = key, entries = {}, quantity = 0,
                displayName = entry.displayName,
                category = entry.category,
                fullType = entry.fullType,
                autoGrab = entry.autoGrab == true }
            buckets[key] = bucket
            order[#order + 1] = bucket
        end
        bucket.entries[#bucket.entries + 1] = entry
        bucket.quantity = bucket.quantity + (tonumber(entry.quantity) or 1)
        bucket.autoGrab = bucket.autoGrab or entry.autoGrab == true
    end
    table.sort(order, function(left, right)
        local leftName = string.lower(tostring(left.displayName or left.fullType))
        local rightName = string.lower(tostring(right.displayName or right.fullType))
        if leftName ~= rightName then return leftName < rightName end
        return left.key < right.key
    end)
    return order
end

function Model.GroupManifest(manifest, include)
    local buckets, order = {}, {}
    for _, entry in ipairs(manifest or {}) do
        if not include or include(entry) == true then
            local key = tostring(entry.fullType or "")
            local bucket = buckets[key]
            if not bucket then
                bucket = { key = key, entries = {}, quantity = 0,
                    displayName = entry.displayName,
                    category = entry.category,
                    fullType = entry.fullType,
                    autoGrab = entry.autoGrab == true }
                buckets[key] = bucket
                order[#order + 1] = bucket
            end
            bucket.entries[#bucket.entries + 1] = entry
            bucket.quantity = bucket.quantity + (tonumber(entry.quantity) or 1)
            bucket.autoGrab = bucket.autoGrab or entry.autoGrab == true
        end
    end
    table.sort(order, function(left, right)
        local leftName = string.lower(tostring(left.displayName or left.fullType))
        local rightName = string.lower(tostring(right.displayName or right.fullType))
        if leftName ~= rightName then return leftName < rightName end
        return left.key < right.key
    end)
    return order
end

function Model.GroupManifestBySource(manifest, include)
    local buckets, order = {}, {}
    for _, entry in ipairs(manifest or {}) do
        if not include or include(entry) == true then
            local key = tostring(entry.sourceToken or "unknown")
            local bucket = buckets[key]
            if not bucket then
                bucket = {
                    key = key,
                    sourceToken = entry.sourceToken,
                    sourceType = entry.sourceType,
                    sourceLabel = tostring(entry.sourceLabel or "") ~= ""
                        and tostring(entry.sourceLabel) or sourceFallback(entry),
                    x = entry.x, y = entry.y, z = entry.z,
                    entries = {}, quantity = 0,
                }
                buckets[key] = bucket
                order[#order + 1] = bucket
            end
            bucket.entries[#bucket.entries + 1] = entry
            bucket.quantity = bucket.quantity + (tonumber(entry.quantity) or 1)
        end
    end
    for _, bucket in ipairs(order) do
        bucket.items = itemGroups(bucket.entries)
    end
    table.sort(order, function(left, right)
        local leftName = string.lower(left.sourceLabel)
        local rightName = string.lower(right.sourceLabel)
        if leftName ~= rightName then return leftName < rightName end
        return left.key < right.key
    end)
    return order
end

function Model.SelectableEntryIDs(manifest, selected, autoOnly)
    local output = {}
    selected = type(selected) == "table" and selected or {}
    for _, entry in ipairs(manifest or {}) do
        if entry.status == "AVAILABLE"
            and (autoOnly and entry.autoGrab == true
                or not autoOnly and selected[entry.entryId] == true)
        then output[#output + 1] = entry.entryId end
    end
    return output
end

function Model.AllAvailableEntryIDs(manifest)
    local output = {}
    for _, entry in ipairs(manifest or {}) do
        if entry.status == "AVAILABLE" then
            output[#output + 1] = entry.entryId
        end
    end
    return output
end

return Model
