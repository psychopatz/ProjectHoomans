if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal

local function nativeListToArray(list)
    local output = {}
    if not list or not list.size or not list.get then return output end
    for index = 0, list:size() - 1 do output[#output + 1] = list:get(index) end
    return output
end

local function isNonEmptyContainer(item)
    local nested = item and item.getItemContainer and item:getItemContainer()
        or item and item.getInventory and item:getInventory()
        or nil
    if not nested or not nested.getItems then return false end
    local items = nested:getItems()
    return items and items.size and items:size() > 0 or false
end

local function nativeFlag(item, methodName)
    local method = item and item[methodName] or nil
    local ok
    local value
    if not method then return false end
    ok, value = pcall(method, item)
    return ok and value == true
end

local function nativeListContainsItem(list, item)
    local entry
    local candidate
    if not list or not list.size or not list.get then return false end
    for index = 0, list:size() - 1 do
        entry = list:get(index)
        candidate = entry and entry.getItem and entry:getItem() or entry
        if candidate == item then return true end
    end
    return false
end

local function playerEquipsItem(player, item)
    local ok
    local equipped
    if nativeFlag(item, "isEquipped") then return true end
    if player and player.isEquipped then
        ok, equipped = pcall(player.isEquipped, player, item)
        if ok and equipped == true then return true end
    end
    if player and player.getPrimaryHandItem and player:getPrimaryHandItem() == item then
        return true
    end
    if player and player.getSecondaryHandItem and player:getSecondaryHandItem() == item then
        return true
    end
    if nativeListContainsItem(
        player and player.getWornItems and player:getWornItems() or nil,
        item
    ) then
        return true
    end
    if nativeListContainsItem(
        player and player.getAttachedItems and player:getAttachedItems() or nil,
        item
    ) then
        return true
    end
    return false
end

local function isNativeBulkProtected(player, item)
    return nativeFlag(item, "isFavorite") or playerEquipsItem(player, item)
end

local function isCompactBulkProtected(item)
    return item and (
        item.fav == true
        or item.interactionLocked == true
        or item.equipSlot ~= nil
        or item.wornSlot ~= nil
        or item.attachedSlot ~= nil
    ) or false
end

Internal.nativeListToArray = nativeListToArray
Internal.isNonEmptyContainer = isNonEmptyContainer
Internal.isNativeBulkProtected = isNativeBulkProtected
Internal.isCompactBulkProtected = isCompactBulkProtected
