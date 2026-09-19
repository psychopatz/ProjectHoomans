local Model = PNC.InventoryUIModel

local function groupKey(row)
    return table.concat({
        tostring(row.source or ""),
        tostring(row.fullType or ""),
        tostring(row.name or ""),
        tostring(row.category or ""),
        row.favorite == true and "favorite" or "ordinary",
        row.equipped == true and "equipped" or "carried",
        row.restricted == true and "restricted" or "interactive",
        tostring(row.stateKey or ""),
    }, "\031")
end

local function copyRow(source)
    local output = {}
    for key, value in pairs(source or {}) do output[key] = value end
    return output
end

function Model.GroupRows(rows, expandedGroups)
    local buckets = {}
    local order = {}
    local output = {}
    local key
    local bucket
    local row
    expandedGroups = type(expandedGroups) == "table" and expandedGroups or {}
    for index = 1, #(rows or {}) do
        row = rows[index]
        key = groupKey(row)
        bucket = buckets[key]
        if not bucket then
            bucket = { key = key, members = {} }
            buckets[key] = bucket
            order[#order + 1] = bucket
        end
        row.groupKey = key
        bucket.members[#bucket.members + 1] = row
    end
    for index = 1, #order do
        bucket = order[index]
        if #bucket.members <= 1 then
            output[#output + 1] = bucket.members[1]
        else
            local header = copyRow(bucket.members[1])
            local quantity = 0
            local weight = 0
            local itemIDs = {}
            for memberIndex = 1, #bucket.members do
                local member = bucket.members[memberIndex]
                quantity = quantity + math.max(
                    1,
                    math.floor(tonumber(member.stack) or 1)
                )
                weight = weight + (tonumber(member.weight) or 0)
                itemIDs[#itemIDs + 1] = member.id
            end
            header.grouped = true
            header.groupHeader = true
            header.groupKey = bucket.key
            header.members = bucket.members
            header.itemIDs = itemIDs
            header.stack = quantity
            header.weight = weight
            header.expanded = expandedGroups[bucket.key] == true
            output[#output + 1] = header
            if header.expanded then
                for memberIndex = 1, #bucket.members do
                    local member = bucket.members[memberIndex]
                    member.groupChild = true
                    output[#output + 1] = member
                end
            end
        end
    end
    return output
end

function Model.GetRowQuantity(row)
    return row and math.max(1, math.floor(tonumber(row.stack) or 1)) or 0
end

function Model.BuildTransferSelection(row, requestedQuantity)
    local available = Model.GetRowQuantity(row)
    local quantity = math.floor(tonumber(requestedQuantity) or available)
    local members = row and row.members or row and { row } or {}
    local itemIDs = {}
    local selected = 0
    if not row or row.restricted == true or quantity < 1 or quantity > available then
        return nil, "invalid_quantity"
    end
    for index = 1, #members do
        local member = members[index]
        local memberQuantity = math.max(
            1,
            math.floor(tonumber(member.stack) or 1)
        )
        if selected < quantity then
            itemIDs[#itemIDs + 1] = member.id
            selected = selected + math.min(memberQuantity, quantity - selected)
        end
    end
    if selected < quantity then return nil, "quantity_unavailable" end
    return {
        itemIDs = itemIDs,
        quantity = quantity,
    }
end

return Model
