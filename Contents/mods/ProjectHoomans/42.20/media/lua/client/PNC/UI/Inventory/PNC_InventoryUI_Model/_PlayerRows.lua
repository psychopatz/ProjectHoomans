local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local playerItemRow = Helpers.playerItemRow

local Model = PNC.InventoryUIModel

function Model.BuildPlayerRows(containerEntry, player, expandedGroups, giftOnly)
    local rows = {}
    local container = containerEntry and containerEntry.container or nil
    local items = container and container.getItems and container:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            local row = playerItemRow(
                items:get(index), containerEntry.id, player, giftOnly == true
            )
            if not giftOnly or row.giftValid == true then
                rows[#rows + 1] = row
            end
        end
    end
    table.sort(rows, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    return Model.GroupRows(rows, expandedGroups)
end

return Model
