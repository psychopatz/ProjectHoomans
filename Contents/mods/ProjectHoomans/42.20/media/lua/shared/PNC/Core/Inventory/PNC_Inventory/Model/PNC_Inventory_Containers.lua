-- PNC inventory container membership and slot-reference mechanics.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Internal = PNC.Inventory.Internal

function Internal.ensureContainer(inv, containerID, maxWeight)
    if type(inv.containers) ~= "table" then inv.containers = {} end
    local container = inv.containers[containerID]
    if type(container) ~= "table" then
        container = {
            maxWeight = tonumber(maxWeight) or 0,
            items = {},
        }
        inv.containers[containerID] = container
    end
    container.maxWeight = tonumber(container.maxWeight)
        or tonumber(maxWeight)
        or 0
    container.items = type(container.items) == "table"
        and container.items
        or {}
    return container
end

function Internal.rebuildContainerMembership(inv)
    local changed = false
    local previousMembership = {}
    local item
    local itemID
    local retainedItems
    local visited
    if type(inv) ~= "table" then return false end
    if type(inv.containers) ~= "table" then
        inv.containers = {}
        changed = true
    end
    for containerID, container in pairs(inv.containers) do
        if type(container) ~= "table" then
            inv.containers[containerID] = {
                maxWeight = 0,
                items = {},
            }
            changed = true
        else
            if type(container.items) ~= "table" then
                changed = true
                container.items = {}
            else
                retainedItems = {}
                visited = 0
                for _, itemID in ipairs(container.items) do
                    visited = visited + 1
                    item = type(inv.items) == "table"
                        and inv.items[itemID] or nil
                    if not item
                        or item.container ~= containerID
                        or previousMembership[itemID]
                    then
                        changed = true
                    else
                        previousMembership[itemID] = true
                        retainedItems[#retainedItems + 1] = itemID
                    end
                end
                if visited ~= Internal.countMapEntries(container.items) then
                    changed = true
                end
                container.items = retainedItems
            end
        end
    end
    Internal.ensureContainer(inv, "root", inv.rootMaxWeight)
    for itemID, item in pairs(type(inv.items) == "table" and inv.items or {}) do
        if type(item) == "table" then
            local targetID = Internal.normalizeString(item.container) or "root"
            if item.container ~= targetID then
                item.container = targetID
                changed = true
            end
            if not previousMembership[itemID] then
                changed = true
                local target = Internal.ensureContainer(inv, targetID,
                    targetID == "root" and inv.rootMaxWeight or 0)
                target.items[#target.items + 1] = itemID
                previousMembership[itemID] = true
            end
            if item.bagContainer then
                Internal.ensureContainer(inv, item.bagContainer,
                    tonumber(item.maxWeight) or 0)
            end
        end
    end
    return changed
end

function Internal.removeItemFromAllContainers(inv, itemID)
    local container
    local i
    if type(inv) ~= "table" or type(inv.containers) ~= "table" then
        return
    end
    for _, container in pairs(inv.containers) do
        if type(container) == "table" and type(container.items) == "table" then
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
    if inv.equipped.waterContainer == itemID then
        inv.equipped.waterContainer = nil
    end
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
