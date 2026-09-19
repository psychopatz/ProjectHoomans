local Model = PNC.InventoryUIModel
    or require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local StorageModel = PNC.ColonyStorageViewModel
    or require "PNC/UI/Communities/PNC_ColonyStorageViewModel"
local Inventory = PNC.Inventory
local ROOT_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png") or nil

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function title(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function findNativeItem(container, wantedID, depth)
    local items
    local item
    local nested
    depth = tonumber(depth) or 0
    if not container or depth > 6 then return nil end
    items = container.getItems and container:getItems() or nil
    if not items or not items.size or not items.get then return nil end
    for index = 0, items:size() - 1 do
        item = items:get(index)
        if item and item.getID and tostring(item:getID()) == tostring(wantedID) then
            return item
        end
        nested = item and item.getItemContainer and item:getItemContainer()
            or item and item.getInventory and item:getInventory() or nil
        item = findNativeItem(nested, wantedID, depth + 1)
        if item then return item end
    end
    return nil
end

local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
end

return {
    Model = Model,
    StorageModel = StorageModel,
    Inventory = Inventory,
    rootTexture = ROOT_TEXTURE,
    clientState = clientState,
    title = title,
    findNativeItem = findNativeItem,
    localPlayer = localPlayer,
}
