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

local function listContainsItem(list, item)
    local entry
    local candidate
    if not list or not list.size or not list.get then return false end
    for index = 0, list:size() - 1 do
        entry = list:get(index)
        candidate = entry and entry.getItem and safeCall(entry, "getItem", nil)
            or entry
        if candidate == item then return true end
    end
    return false
end

local function isPlayerItemEquipped(player, item)
    local method = player and player.isEquipped or nil
    local ok
    local value
    if safeCall(item, "isEquipped", false) == true then return true end
    if type(method) == "function" then
        ok, value = pcall(method, player, item)
        if ok and value == true then return true end
    end
    if safeCall(player, "getPrimaryHandItem", nil) == item
        or safeCall(player, "getSecondaryHandItem", nil) == item
    then
        return true
    end
    if listContainsItem(safeCall(player, "getWornItems", nil), item)
        or listContainsItem(safeCall(player, "getAttachedItems", nil), item)
    then
        return true
    end
    return false
end

local function playerItemRow(item, containerKey, player)
    local fullType = tostring(safeCall(item, "getFullType", ""))
    local metadata = probe(fullType)
    local customName = safeCall(item, "getName", nil)
    local displayName = tostring(customName or metadata.name or fullType)
    local giftScore = PNC.Gifts and PNC.Gifts.GetItemScore
        and PNC.Gifts.GetItemScore(fullType) or nil
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
        equipped = isPlayerItemEquipped(player, item),
        favorite = safeCall(item, "isFavorite", false) == true,
        restricted = false,
        giftScore = giftScore,
    }
end

local function groupKey(row)
    return table.concat({
        tostring(row.source or ""),
        tostring(row.fullType or ""),
        tostring(row.name or ""),
        tostring(row.category or ""),
        row.favorite == true and "favorite" or "ordinary",
        row.equipped == true and "equipped" or "carried",
        row.restricted == true and "restricted" or "interactive",
    }, "\031")
end

local function copyRow(source)
    local output = {}
    for key, value in pairs(source or {}) do output[key] = value end
    return output
end

function Model.GroupRows(rows, expandedGroups)
    local buckets = {}
    local order = {}
    local output = {}
    local key
    local bucket
    local row
    expandedGroups = type(expandedGroups) == "table" and expandedGroups or {}
    for index = 1, #(rows or {}) do
        row = rows[index]
        key = groupKey(row)
        bucket = buckets[key]
        if not bucket then
            bucket = { key = key, members = {} }
            buckets[key] = bucket
            order[#order + 1] = bucket
        end
        row.groupKey = key
        bucket.members[#bucket.members + 1] = row
    end
    for index = 1, #order do
        bucket = order[index]
        if #bucket.members <= 1 then
            output[#output + 1] = bucket.members[1]
        else
            local header = copyRow(bucket.members[1])
            local quantity = 0
            local weight = 0
            local itemIDs = {}
            for memberIndex = 1, #bucket.members do
                local member = bucket.members[memberIndex]
                quantity = quantity + math.max(
                    1,
                    math.floor(tonumber(member.stack) or 1)
                )
                weight = weight + (tonumber(member.weight) or 0)
                itemIDs[#itemIDs + 1] = member.id
            end
            header.grouped = true
            header.groupHeader = true
            header.groupKey = bucket.key
            header.members = bucket.members
            header.itemIDs = itemIDs
            header.stack = quantity
            header.weight = weight
            header.expanded = expandedGroups[bucket.key] == true
            output[#output + 1] = header
            if header.expanded then
                for memberIndex = 1, #bucket.members do
                    local member = bucket.members[memberIndex]
                    member.groupChild = true
                    output[#output + 1] = member
                end
            end
        end
    end
    return output
end

function Model.GetRowQuantity(row)
    return row and math.max(1, math.floor(tonumber(row.stack) or 1)) or 0
end

function Model.BuildTransferSelection(row, requestedQuantity)
    local available = Model.GetRowQuantity(row)
    local quantity = math.floor(tonumber(requestedQuantity) or available)
    local members = row and row.members or row and { row } or {}
    local itemIDs = {}
    local selected = 0
    if not row or row.restricted == true or quantity < 1 or quantity > available then
        return nil, "invalid_quantity"
    end
    for index = 1, #members do
        local member = members[index]
        local memberQuantity = math.max(
            1,
            math.floor(tonumber(member.stack) or 1)
        )
        if selected < quantity then
            itemIDs[#itemIDs + 1] = member.id
            selected = selected + math.min(memberQuantity, quantity - selected)
        end
    end
    if selected < quantity then return nil, "quantity_unavailable" end
    return {
        itemIDs = itemIDs,
        quantity = quantity,
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

function Model.BuildPlayerRows(containerEntry, player, expandedGroups)
    local rows = {}
    local container = containerEntry and containerEntry.container or nil
    local items = container and container.getItems and container:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do
            rows[#rows + 1] = playerItemRow(items:get(index), containerEntry.id, player)
        end
    end
    table.sort(rows, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    return Model.GroupRows(rows, expandedGroups)
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
                container = item.container,
                stack = math.max(1, tonumber(item.stack) or 1),
                equipped = item.equipSlot ~= nil
                    or item.wornSlot ~= nil
                    or item.attachedSlot ~= nil,
                favorite = item.fav == true,
                restricted = item.interactionLocked == true,
                restrictionReason = item.interactionLockReason,
            }
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
