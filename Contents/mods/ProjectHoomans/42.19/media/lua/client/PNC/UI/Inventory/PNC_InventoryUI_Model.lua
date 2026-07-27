require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.InventoryUIModel = PNC.InventoryUIModel or {}

local Model = PNC.InventoryUIModel
local PROBE_CACHE = {}
local ROOT_INVENTORY_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png")
    or nil

local function safeCall(object, method, fallback)
    if not object or not object[method] then return fallback end
    local ok, value = pcall(object[method], object)
    if not ok or value == nil then return fallback end
    return value
end

local function probe(fullType)
    fullType = tostring(fullType or "")
    if PROBE_CACHE[fullType] then return PROBE_CACHE[fullType] end
    local item = PNC.Equipment and PNC.Equipment.CreateItem
        and PNC.Equipment.CreateItem(fullType)
        or nil
    if type(item) == "table" and not item.getDisplayName and item[1] then
        item = item[1]
    end
    local result = {
        fullType = fullType,
        name = tostring(safeCall(item, "getDisplayName", fullType)),
        category = tostring(
            safeCall(item, "getDisplayCategory", nil)
            or safeCall(item, "getCategory", "Item")
        ),
        texture = safeCall(item, "getTex", nil),
        weight = tonumber(
            safeCall(item, "getActualWeight", nil)
            or safeCall(item, "getWeight", 0)
        ) or 0,
    }
    PROBE_CACHE[fullType] = result
    return result
end

local function playerItemRow(item, containerKey)
    local fullType = tostring(safeCall(item, "getFullType", ""))
    local metadata = probe(fullType)
    local customName = safeCall(item, "getName", nil)
    local displayName = tostring(customName or metadata.name or fullType)
    return {
        source = "player",
        id = tostring(safeCall(item, "getID", "")),
        nativeItem = item,
        fullType = fullType,
        name = displayName,
        category = metadata.category,
        texture = metadata.texture,
        weight = metadata.weight,
        container = containerKey,
        stack = 1,
        equipped = safeCall(item, "isEquipped", false) == true,
        favorite = safeCall(item, "isFavorite", false) == true,
    }
end

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

function Model.BuildPlayerRows(containerEntry)
    local rows = {}
    local container = containerEntry and containerEntry.container or nil
    local items = container and container.getItems and container:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            rows[#rows + 1] = playerItemRow(items:get(index), containerEntry.id)
        end
    end
    table.sort(rows, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    return rows
end

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

function Model.BuildNPCRows(inventory, containerID)
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
                container = item.container,
                stack = math.max(1, tonumber(item.stack) or 1),
                equipped = item.equipSlot ~= nil
                    or item.wornSlot ~= nil
                    or item.attachedSlot ~= nil,
                favorite = item.fav == true,
            }
        end
    end
    table.sort(rows, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped == true end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return rows
end

function Model.FindContainer(containers, containerID)
    for _, entry in ipairs(containers or {}) do
        if tostring(entry.id) == tostring(containerID) then return entry end
    end
    return nil
end

function Model.GetPlayerContainerWeight(containerEntry, player)
    local container = containerEntry and containerEntry.container or nil
    if not container then return 0, 0 end
    local usedWeight = tonumber(safeCall(container, "getCapacityWeight", 0)) or 0
    local maxWeight
    if tostring(containerEntry.id) == "root" then
        maxWeight = tonumber(safeCall(player, "getMaxWeight", 0)) or 0
    elseif container.getEffectiveCapacity then
        local ok, value = pcall(container.getEffectiveCapacity, container, player)
        if ok then maxWeight = tonumber(value) end
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
