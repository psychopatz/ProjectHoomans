-- PNC inventory container membership and slot-reference mechanics.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Internal = PNC.Inventory.Internal

function Internal.ensureContainer(inv, containerID, maxWeight)
    inv.containers = inv.containers or {}
    inv.containers[containerID] = inv.containers[containerID] or {
        maxWeight = tonumber(maxWeight) or 0,
        items = {},
    }
    inv.containers[containerID].maxWeight = tonumber(inv.containers[containerID].maxWeight)
        or tonumber(maxWeight)
        or 0
    inv.containers[containerID].items = type(inv.containers[containerID].items) == "table"
        and inv.containers[containerID].items
        or {}
    return inv.containers[containerID]
end

function Internal.removeItemFromAllContainers(inv, itemID)
    local container
    local i
    if not inv or not inv.containers then
        return
    end
    for _, container in pairs(inv.containers) do
        if type(container.items) == "table" then
            for i = #container.items, 1, -1 do
                if container.items[i] == itemID then
                    table.remove(container.items, i)
                end
            end
        end
    end
end

function Internal.addItemToContainer(inv, itemID, containerID)
    local container = Internal.ensureContainer(inv, containerID,
        containerID == "root" and inv.rootMaxWeight or 0)
    Internal.removeItemFromAllContainers(inv, itemID)
    container.items[#container.items + 1] = itemID
end

function Internal.clearItemRefs(inv, itemID)
    local key
    if inv.equipped.primary == itemID then inv.equipped.primary = nil end
    if inv.equipped.secondary == itemID then inv.equipped.secondary = nil end
    if inv.equipped.bag == itemID then inv.equipped.bag = nil end
    for key, _ in pairs(inv.worn) do
        if inv.worn[key] == itemID then inv.worn[key] = nil end
    end
    for key, _ in pairs(inv.attached) do
        if inv.attached[key] == itemID then inv.attached[key] = nil end
    end
end

function Internal.removeItemByID(inv, itemID)
    local item = inv.items[itemID]
    if not item then
        return false
    end
    Internal.clearItemRefs(inv, itemID)
    Internal.removeItemFromAllContainers(inv, itemID)
    if item.bagContainer then
        inv.containers[item.bagContainer] = nil
    end
    inv.items[itemID] = nil
    return true
end

function Internal.setItemContainer(inv, item, containerID)
    if not inv or not item then
        return false
    end
    item.container = Internal.normalizeString(containerID) or "root"
    Internal.addItemToContainer(inv, item.id, item.container)
    return true
end

function Internal.resolveSavedContainer(inv, containerID)
    local resolved = Internal.normalizeString(containerID) or "root"
    local bag
    if inv.containers and inv.containers[resolved] then
        return resolved
    end
    if string.sub(resolved, 1, 4) == "bag_" and inv.equipped and inv.equipped.bag then
        bag = inv.items and inv.items[inv.equipped.bag] or nil
        if bag and bag.bagContainer then
            return bag.bagContainer
        end
    end
    return "root"
end
