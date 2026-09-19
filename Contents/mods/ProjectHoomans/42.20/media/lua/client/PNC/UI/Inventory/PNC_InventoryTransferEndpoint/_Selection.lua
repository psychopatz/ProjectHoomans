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
    local selection = { itemIDs = {}, records = {}, quantity = 0 }
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
                local rowIDs = row.itemIDs or { row.id }
                for index = 1, #rowIDs do
                    local itemID = rowIDs[index]
                    if itemID and not seen[itemID] then
                        seen[itemID] = true
                        selection.itemIDs[#selection.itemIDs + 1] = itemID
                    end
                end
                selection.quantity = selection.quantity + quantity
            end
        end
    end
    return selection
end

return Endpoint
