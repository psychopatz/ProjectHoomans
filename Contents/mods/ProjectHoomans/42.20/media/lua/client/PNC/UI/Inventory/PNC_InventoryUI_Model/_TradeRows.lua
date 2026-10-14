local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local Model = PNC.InventoryUIModel

local function number(value, fallback)
    value = tonumber(value)
    return value or fallback or 0
end

local function rowName(item)
    return tostring(item and (item.name or item.displayName
        or item.fullType) or "Item")
end

local function copyRow(source)
    local output = {}
    for key, value in pairs(source or {}) do output[key] = value end
    return output
end

local function tradablePlayerRow(row)
    if type(row) ~= "table" then return false end
    return row.restricted ~= true
        and row.equipped ~= true
        and row.favorite ~= true
        and row.disabled ~= true
end

local function hasUnsupportedStack(row)
    local members = row and row.members
    local item
    if type(members) == "table" and #members > 0 then
        for index = 1, #members do
            item = members[index] and members[index].nativeItem
            if Helpers.nativeQuantity(item) > 1 then return true end
        end
        return false
    end
    return Helpers.nativeQuantity(row and row.nativeItem) > 1
end

local function stableTradeKey(row)
    local itemIDs = row and row.itemIDs
    if type(itemIDs) == "table" then
        local identities = {}
        for index = 1, #itemIDs do
            local itemID = itemIDs[index]
            if itemID ~= nil and tostring(itemID) ~= "" then
                identities[#identities + 1] = tostring(itemID)
            end
        end
        if #identities > 0 then
            -- Draft quantities belong to exact native item identities.  Do
            -- not key the interactive control from a display/state
            -- signature: that signature can legitimately change when the
            -- inventory is re-read, which made player-side controls appear
            -- to accept a click and then snap back to zero.
            table.sort(identities)
            return table.concat({
                tostring(row.source or "player"),
                tostring(row.fullType or ""),
                table.concat(identities, "\030"),
            }, "\031")
        end
    end
    return tostring(row and (row.id or row.groupKey or row.fullType) or "")
end

local function decorate(row, side, available, unitPrice)
    local quantity = math.max(1, math.floor(number(available, 1)))
    local price = math.max(0, math.floor(number(unitPrice, 0)))
    row.tradeSide = side
    -- Grouped player rows can share a full type while representing separate
    -- condition/container buckets. Keep their draft quantities independent
    -- without coupling the draft to a volatile display signature.
    row.tradeKey = stableTradeKey(row)
    row.availableQuantity = quantity
    row.selectedQuantity = 0
    row.unitPrice = price
    row.catalogCells = {
        category = tostring(row.category or "Item"),
        availability = tostring(quantity),
        unitPrice = "$" .. tostring(price),
        action = "-  0  +",
    }
    row.catalogColors = {
        availability = quantity > 0 and "success" or "warning",
        unitPrice = "accent",
        action = "accent",
    }
    return row
end

local function rowMembers(row)
    if type(row and row.members) == "table" and #row.members > 0 then
        return row.members
    end
    return row and { row } or {}
end

local function quoteRow(row, members, quote)
    local output = copyRow(row)
    local itemIDs = {}
    local stack = 0
    local weight = 0
    for index = 1, #members do
        local member = members[index]
        if member then
            itemIDs[#itemIDs + 1] = member.id
            stack = stack + math.max(1, math.floor(
                number(member.stack, 1)))
            weight = weight + number(member.weight, 0)
        end
    end
    output.members = #members > 1 and members or nil
    output.itemIDs = itemIDs
    output.itemIDQuantities = nil
    output.stack = stack
    output.weight = weight
    output.grouped = #members > 1
    output.groupHeader = nil
    output.groupChild = nil
    output.expanded = nil
    output.groupKey = nil
    output.tradeQuote = math.max(0, math.floor(number(quote, 0)))
    return output
end

local function splitByQuote(row, quoteForItem)
    local members = rowMembers(row)
    if type(quoteForItem) ~= "function" or #members < 1 then
        return { row }
    end
    local buckets = {}
    local order = {}
    for index = 1, #members do
        local member = members[index]
        local quote = math.max(0, math.floor(number(
            quoteForItem(member), 0)))
        local key = tostring(quote)
        local bucket = buckets[key]
        if not bucket then
            bucket = { quote = quote, members = {} }
            buckets[key] = bucket
            order[#order + 1] = bucket
        end
        bucket.members[#bucket.members + 1] = member
    end
    local output = {}
    for index = 1, #order do
        local bucket = order[index]
        output[#output + 1] = quoteRow(row, bucket.members, bucket.quote)
    end
    return output
end

function Model.IsTradePlayerRow(row)
    return tradablePlayerRow(row)
end

function Model.BuildTradePlayerRows(
    containerEntry, player, expandedGroups, giftPreferences, options
)
    local source = Model.BuildPlayerRows(
        containerEntry, player, nil, false, giftPreferences,
        {
            stateSignatureCache = options
                and options.stateSignatureCache or nil,
        }
    )
    local rows = {}
    for index = 1, #source do
        local row = source[index]
        if tradablePlayerRow(row) and not hasUnsupportedStack(row) then
            -- Trade rows use a flat quantity control instead of the normal
            -- inventory group's expand/collapse click target. Keep the
            -- grouped members and exact itemIDs, but make the visual header
            -- itself the actionable trade row.
            row.groupHeader = nil
            row.expanded = nil
            local quoteRows = splitByQuote(
                row, options and options.quoteForItem or nil)
            for quoteIndex = 1, #quoteRows do
                local quoteRowValue = quoteRows[quoteIndex]
                rows[#rows + 1] = decorate(
                    quoteRowValue,
                    "sell",
                    Model.GetRowQuantity(quoteRowValue),
                    quoteRowValue.tradeQuote or 0
                )
            end
        end
    end
    return rows
end

function Model.BuildTradeStockRows(items)
    local rows = {}
    for index = 1, #(items or {}) do
        local item = items[index]
        local fullType = tostring(item and item.fullType or "")
        local quantity = math.max(0, math.floor(number(
            item and (item.quantity or item.availableQuantity), 0
        )))
        if fullType ~= "" and quantity > 0
            and number(item and item.unitPrice, 0) > 0
            and item.tradable ~= false
            and item.disabled ~= true
            and item.guardEquipment ~= true
        then
            local metadata = Helpers.probe(fullType)
            local row = {
                source = "trader",
                id = tostring(item.itemID or fullType),
                fullType = fullType,
                name = rowName(item) ~= "" and rowName(item) or metadata.name,
                category = tostring(item.category or metadata.category or "Item"),
                texture = item.texture or metadata.texture,
                weight = number(item.weight, metadata.weight),
                unitWeight = number(item.unitWeight, metadata.weight),
                stack = quantity,
                stateful = true,
            }
            decorate(row, "buy", quantity, item.unitPrice)
            rows[#rows + 1] = row
        end
    end
    table.sort(rows, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    return rows
end

function Model.SetTradeRowQuantity(row, quantity)
    if type(row) ~= "table" then return false, "row_required" end
    local maximum = math.max(0, math.floor(number(row.availableQuantity, 0)))
    quantity = math.floor(number(quantity, 0))
    if quantity < 0 or quantity > maximum then
        return false, "quantity_unavailable"
    end
    row.selectedQuantity = quantity
    row.catalogCells = row.catalogCells or {}
    row.catalogCells.action = "-  " .. tostring(quantity) .. "  +"
    return true
end

return Model
