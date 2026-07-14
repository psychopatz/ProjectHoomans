-- Worn-item capture and transfer from live bodies to inert corpses.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Internal = PNC.BodyLifecycle.Internal

function Internal.captureWornEntries(wornItems)
    local entries = {}
    local entry
    local item
    local i
    if not wornItems or not wornItems.size then
        return entries
    end
    for i = 0, wornItems:size() - 1 do
        entry = wornItems:get(i)
        item = entry and entry.getItem and entry:getItem() or nil
        if item then
            entries[#entries + 1] = {
                location = entry.getLocation and tostring(entry:getLocation() or "") or "",
                item = item,
                fullType = Internal.itemFullType(item),
            }
        end
    end
    return entries
end

function Internal.applyCorpseWornItems(corpse, wornEntries)
    local targetWornItems
    local container
    local inventoryItems
    local pool = {}
    local claimed = {}
    local applied = 0
    local entry
    local item
    local kind
    local candidates
    local i
    local j
    if not corpse or type(wornEntries) ~= "table" then
        return false
    end
    targetWornItems = corpse.getWornItems and corpse:getWornItems() or nil
    container = corpse.getContainer and corpse:getContainer() or nil
    if not targetWornItems or not targetWornItems.setItem then
        return false
    end
    inventoryItems = container and container.getItems and container:getItems() or nil
    if inventoryItems then
        for i = 0, inventoryItems:size() - 1 do
            item = inventoryItems:get(i)
            kind = Internal.itemFullType(item)
            if kind ~= "" then
                pool[kind] = pool[kind] or {}
                pool[kind][#pool[kind] + 1] = item
            end
        end
    end
    if targetWornItems.clear then
        pcall(targetWornItems.clear, targetWornItems)
    end
    for i = 1, #wornEntries do
        entry = wornEntries[i]
        item = nil
        if entry.item and entry.item.getContainer and entry.item:getContainer() == container then
            item = entry.item
        end
        candidates = pool[tostring(entry.fullType or "")] or {}
        if not item then
            for j = 1, #candidates do
                if not claimed[candidates[j]] then
                    item = candidates[j]
                    break
                end
            end
        end
        item = item or entry.item
        if item and entry.location and entry.location ~= "" then
            Internal.addItemToContainer(container, item)
            claimed[item] = true
            if pcall(targetWornItems.setItem, targetWornItems, entry.location, item) then
                applied = applied + 1
            end
        end
    end
    if targetWornItems and container and targetWornItems.addItemsToItemContainer then
        pcall(targetWornItems.addItemsToItemContainer, targetWornItems, container)
    end
    return applied > 0 or #wornEntries == 0
end

function Internal.transmitCorpseState(corpse)
    if corpse and isServer and isServer() and corpse.transmitCompleteItemToClients then
        pcall(corpse.transmitCompleteItemToClients, corpse)
    end
end
