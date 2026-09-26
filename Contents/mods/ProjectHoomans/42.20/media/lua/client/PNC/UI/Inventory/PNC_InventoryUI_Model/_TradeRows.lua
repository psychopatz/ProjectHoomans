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

local function tradablePlayerRow(row)
    if type(row) ~= "table" then return false end
    return row.restricted ~= true
        and row.equipped ~= true
        and row.favorite ~= true
        and row.disabled ~= true
end

local function decorate(row, side, available, unitPrice)
    local quantity = math.max(1, math.floor(number(available, 1)))
    local price = math.max(0, math.floor(number(unitPrice, 0)))
    row.tradeSide = side
    -- Grouped player rows can share a full type while representing separate
    -- condition/container buckets. Keep their draft quantities independent.
    row.tradeKey = tostring(row.groupKey or row.id or row.fullType or "")
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

function Model.IsTradePlayerRow(row)
    return tradablePlayerRow(row)
end

function Model.BuildTradePlayerRows(
    containerEntry, player, expandedGroups, giftPreferences
)
    local source = Model.BuildPlayerRows(
        containerEntry, player, expandedGroups, false, giftPreferences
    )
    local rows = {}
    for index = 1, #source do
        local row = source[index]
        if tradablePlayerRow(row) then
            rows[#rows + 1] = decorate(
                row,
                "sell",
                Model.GetRowQuantity(row),
                0
            )
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
