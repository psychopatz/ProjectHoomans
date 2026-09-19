local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local safeCall = Helpers.safeCall
local probe = Helpers.probe

local Model = PNC.InventoryUIModel

function Model.GetPlayerContainerWeight(containerEntry, player)
    local container = containerEntry and containerEntry.container or nil
    if not container then return 0, 0 end
    local usedWeight = tonumber(safeCall(container, "getCapacityWeight", 0)) or 0
    local maxWeight
    if tostring(containerEntry.id) == "root" then
        maxWeight = tonumber(safeCall(player, "getMaxWeight", 0)) or 0
    elseif type(container.getEffectiveCapacity) == "function" then
        maxWeight = tonumber(container:getEffectiveCapacity(player))
    end
    if not maxWeight then
        maxWeight = tonumber(
            safeCall(container, "getCapacity", nil)
            or safeCall(container, "getMaxWeight", 0)
        ) or 0
    end
    return usedWeight, maxWeight
end

function Model.GetNPCContainerWeight(inventory, containerID)
    local container = inventory and inventory.containers
        and inventory.containers[containerID or "root"]
        or nil
    if not container then return 0, 0 end
    if (containerID or "root") == "root" and inventory.summary then
        return tonumber(inventory.summary.usedWeight) or 0,
            tonumber(inventory.summary.maxWeight) or tonumber(container.maxWeight) or 0
    end
    local usedWeight = 0
    for _, itemID in ipairs(container.items or {}) do
        local item = inventory.items and inventory.items[itemID] or nil
        if item then
            local metadata = probe(item.type)
            usedWeight = usedWeight
                + metadata.weight * math.max(1, tonumber(item.stack) or 1)
        end
    end
    return usedWeight, tonumber(container.maxWeight) or 0
end

return Model
