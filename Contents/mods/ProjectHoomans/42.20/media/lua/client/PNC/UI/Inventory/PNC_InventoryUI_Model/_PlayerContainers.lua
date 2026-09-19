local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local safeCall = Helpers.safeCall
local probe = Helpers.probe
local ROOT_INVENTORY_TEXTURE = Helpers.rootInventoryTexture

local Model = PNC.InventoryUIModel

local function addPlayerContainer(output, seen, item, depth)
    if not item or depth > 4 then return end
    local itemID = tostring(safeCall(item, "getID", ""))
    if itemID == "" or seen[itemID] then return end
    local nested = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory()
        or nil
    if not nested then return end
    seen[itemID] = true
    local fullType = tostring(safeCall(item, "getFullType", ""))
    local metadata = probe(fullType)
    output[#output + 1] = {
        id = itemID,
        container = nested,
        label = tostring(safeCall(item, "getDisplayName", metadata.name)),
        texture = metadata.texture,
    }
    local items = nested.getItems and nested:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            addPlayerContainer(output, seen, items:get(index), depth + 1)
        end
    end
end

function Model.BuildPlayerContainers(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local output = {
        {
            id = "root",
            container = inventory,
            label = "Inventory",
            texture = ROOT_INVENTORY_TEXTURE,
        },
    }
    local seen = {}
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            addPlayerContainer(output, seen, items:get(index), 1)
        end
    end
    return output
end

return Model
