if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal =
    PNC.ColonyStorageService.Internal or {}

local Internal = PNC.ColonyStorageService.Internal
Internal.SourceAdaptersInternal =
    Internal.SourceAdaptersInternal or {}
local H = Internal.SourceAdaptersInternal
local CoreInventory = Internal.CoreInventory
local ItemRecord =
    require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

function H.NativeID(item)
    return item and item.getID and tostring(item:getID()) or nil
end

function Internal.SelectedPlayerItems(player, ids)
    local wanted = {}
    for index = 1, #(ids or {}) do wanted[tostring(ids[index])] = true end
    local found = {}
    local function visit(container)
        local items = container and container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return end
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if wanted[H.NativeID(item)] then found[#found + 1] = item end
            local nested = item and item.getItemContainer
                and item:getItemContainer() or nil
            if nested then visit(nested) end
        end
    end
    visit(player and player.getInventory and player:getInventory() or nil)
    if #found ~= #(ids or {}) then return nil, "item_not_found" end
    return found
end

function Internal.ResolvePlayerContainer(player, containerItemID)
    local root = player and player.getInventory and player:getInventory() or nil
    containerItemID = tostring(containerItemID or "root")
    if containerItemID == "" or containerItemID == "root" then return root end
    local function visit(container, depth)
        if not container or depth > 4 then return nil end
        local items = container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return nil end
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if item and item.getID
                and tostring(item:getID()) == containerItemID
            then
                return item.getItemContainer and item:getItemContainer()
                    or item.getInventory and item:getInventory() or nil
            end
            local nested = item and item.getItemContainer
                and item:getItemContainer() or nil
            local found = nested and visit(nested, depth + 1) or nil
            if found then return found end
        end
        return nil
    end
    return visit(root, 1)
end

function Internal.PlayerDestination(player, containerItemID)
    local container = Internal.ResolvePlayerContainer(player, containerItemID)
    if not container then return nil, "player_container_not_found" end
    return CoreInventory.wrapPhysicalInventory(container)
end

return Internal

