local Helpers = require "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
local probe = Helpers.probe
local isNPCDepositForbidden = Helpers.isNPCDepositForbidden
local TooltipModel = Helpers.tooltipModel
local TooltipOptions = Helpers.tooltipOptions
local ROOT_INVENTORY_TEXTURE = Helpers.rootInventoryTexture

local Model = PNC.InventoryUIModel

function Model.BuildNPCContainers(inventory)
    local output = {
        { id = "root", label = "Inventory", texture = ROOT_INVENTORY_TEXTURE },
    }
    for _, item in pairs(inventory and inventory.items or {}) do
        if item.bagContainer and inventory.containers
            and inventory.containers[item.bagContainer]
        then
            local metadata = probe(item.type)
            output[#output + 1] = {
                id = item.bagContainer,
                label = tostring(item.customName or metadata.name),
                texture = metadata.texture,
                itemID = item.id,
            }
        end
    end
    table.sort(output, function(a, b)
        if a.id == "root" then return true end
        if b.id == "root" then return false end
        return string.lower(a.label) < string.lower(b.label)
    end)
    return output
end

function Model.BuildNPCRows(inventory, containerID, expandedGroups)
    local rows = {}
    local container = inventory and inventory.containers
        and inventory.containers[containerID or "root"]
        or nil
    for _, itemID in ipairs(container and container.items or {}) do
        local item = inventory.items and inventory.items[itemID] or nil
        if item then
            local metadata = probe(item.type)
            rows[#rows + 1] = {
                source = "npc",
                id = item.id,
                compactItem = item,
                fullType = item.type,
                name = tostring(item.customName or metadata.name),
                category = metadata.category,
                texture = metadata.texture,
                weight = metadata.weight * math.max(1, tonumber(item.stack) or 1),
                unitWeight = metadata.weight,
                conditionMax = metadata.conditionMax,
                stateful = true,
                container = item.container,
                stack = math.max(1, tonumber(item.stack) or 1),
                equipped = item.equipSlot ~= nil
                    or item.wornSlot ~= nil
                    or item.attachedSlot ~= nil,
                favorite = item.fav == true,
                restricted = isNPCDepositForbidden(item),
                restrictionReason = item.interactionLockReason,
            }
            rows[#rows].stateKey = TooltipModel.StateSignature(
                rows[#rows], nil, false, TooltipOptions.modelOptions)
        end
    end
    table.sort(rows, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped == true end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return Model.GroupRows(rows, expandedGroups)
end

function Model.FindContainer(containers, containerID)
    for _, entry in ipairs(containers or {}) do
        if tostring(entry.id) == tostring(containerID) then return entry end
    end
    return nil
end

return Model
