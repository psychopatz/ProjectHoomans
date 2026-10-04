local Endpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
local Model = Helpers.Model

function Endpoint.SelectionForRow(endpoint, row, requestedQuantity)
    local selection, reason = Model.BuildTransferSelection(row, requestedQuantity)
    if not selection then return nil, reason end
    if endpoint and endpoint.kind == "storage" then
        selection.recordIndex = tonumber(row.recordIndex or row.id)
        selection.records = {{
            recordIndex = selection.recordIndex,
            quantity = selection.quantity,
        }}
        if not selection.recordIndex then return nil, "record_unavailable" end
    end
    return selection
end

function Endpoint.BulkSelection(endpoint, list)
    local selection = {
        itemIDs = {}, records = {}, quantity = 0,
        itemQuantity = 0, currencyAmount = 0,
        currencyContainers = {}, currencyFullType = nil,
    }
    local seen = {}
    for _, entry in ipairs(list and list.items or {}) do
        local row = entry and entry.item or nil
        if row and row.groupHeader ~= true and row.favorite ~= true
            and row.equipped ~= true and row.restricted ~= true
        then
            local quantity = Model.GetRowQuantity(row)
            if endpoint and endpoint.kind == "storage" then
                local recordIndex = tonumber(row.recordIndex or row.id)
                if recordIndex and not seen[recordIndex] then
                    seen[recordIndex] = true
                    selection.records[#selection.records + 1] = {
                        recordIndex = recordIndex,
                        quantity = quantity,
                    }
                    selection.quantity = selection.quantity + quantity
                end
            else
            if row.currency == true then
                -- Currency rows are already expressed in value units. Do not
                -- preserve a physical Money/MoneyBundle type here: the
                -- authoritative Core service normalizes the destination.
                selection.currencyAmount = selection.currencyAmount
                    + quantity
                selection.currencyContainers[#selection.currencyContainers + 1] =
                    row.container
                selection.quantity = selection.quantity + quantity
            else
                local rowIDs = row.itemIDs or { row.id }
                for index = 1, #rowIDs do
                    local itemID = rowIDs[index]
                    if itemID and not seen[itemID] then
                        seen[itemID] = true
                        selection.itemIDs[#selection.itemIDs + 1] = itemID
                    end
                end
                selection.itemQuantity = selection.itemQuantity + quantity
                selection.quantity = selection.quantity + quantity
            end
        end
        end
    end
    -- Keep the existing normal-item transfer transaction unchanged. A mixed
    -- bulk request would otherwise combine physical IDs and currency value
    -- semantics without an atomic cross-domain rollback.
    if #selection.itemIDs > 0 then
        selection.currencyAmount = 0
        selection.currencyContainers = {}
        selection.currencyFullType = nil
    elseif selection.currencyFullType == false then
        selection.currencyFullType = nil
    end
    return selection
end

return Endpoint
