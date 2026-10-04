local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local playerItemRow = Helpers.playerItemRow
local safeCall = Helpers.safeCall
local canFastAggregate = Helpers.canFastAggregate
local nativeQuantity = Helpers.nativeQuantity
local Currency = Helpers.currency

local Model = PNC.InventoryUIModel

local function addAggregateItem(row, item)
    local itemID = tostring(safeCall(item, "getID", ""))
    local quantity = nativeQuantity(item)
    row.stack = row.stack + quantity
    row.weight = row.weight + (row.unitWeight or 0) * quantity
    if itemID ~= "" then
        row.itemIDs[#row.itemIDs + 1] = itemID
        if quantity > 1 then
            row.itemIDQuantities = row.itemIDQuantities or {}
            row.itemIDQuantities[#row.itemIDs] = quantity
        end
        if not row.aggregateFirstID then row.aggregateFirstID = itemID end
        row.aggregateLastID = itemID
    end
end

function Model.BuildPlayerRows(
    containerEntry, player, expandedGroups, giftOnly, giftPreferences
)
    local rows = {}
    local aggregateRows = {}
    local aggregateByKey = {}
    local currencyRow
    local container = containerEntry and containerEntry.container or nil
    local items = container and container.getItems and container:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            local fullType = tostring(safeCall(item, "getFullType", ""))
            local aggregateKey
            local aggregate
            if giftOnly ~= true and Currency
                and Currency.IsType(fullType)
            then
                if not currencyRow then
                    currencyRow = Helpers.newCurrencyRow(
                        containerEntry.id, "player")
                end
                Helpers.addCurrencyValue(
                    currencyRow, fullType, nativeQuantity(item), 1)
            elseif giftOnly ~= true and canFastAggregate(item, fullType) then
                aggregateKey = tostring(containerEntry.id) .. "\031" .. fullType
                aggregate = aggregateByKey[aggregateKey]
                if not aggregate then
                    aggregate = playerItemRow(
                        item,
                        containerEntry.id,
                        player,
                        false,
                        giftPreferences
                    )
                    aggregate.name = tostring(
                        Helpers.probe(fullType).name or aggregate.name)
                    aggregate.aggregate = true
                    aggregate.aggregateKey = aggregateKey
                    aggregate.itemIDs = {}
                    aggregate.stack = 0
                    aggregate.weight = 0
                    aggregateByKey[aggregateKey] = aggregate
                    aggregateRows[#aggregateRows + 1] = aggregate
                end
                addAggregateItem(aggregate, item)
            else
                local row = playerItemRow(
                    item,
                    containerEntry.id,
                    player,
                    giftOnly == true,
                    giftPreferences
                )
                if not giftOnly or row.giftValid == true then
                    rows[#rows + 1] = row
                end
            end
        end
    end
    for index = 1, #aggregateRows do
        local row = aggregateRows[index]
        row.aggregateFingerprint = table.concat({
            tostring(row.stack),
            tostring(row.aggregateFirstID or ""),
            tostring(row.aggregateLastID or ""),
        }, ":")
        rows[#rows + 1] = row
    end
    if currencyRow and currencyRow.currencyUnits > 0 then
        rows[#rows + 1] = currencyRow
    end
    table.sort(rows, function(a, b)
        if a.currency ~= b.currency then return a.currency == true end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return Model.GroupRows(rows, expandedGroups)
end

return Model
