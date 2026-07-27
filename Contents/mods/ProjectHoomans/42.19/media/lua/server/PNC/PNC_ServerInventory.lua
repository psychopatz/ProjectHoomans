require "PNC/00_PNC_Init"
local ItemTransfer = require "PsychopatzCore/Inventory/PsychopatzItemTransfer"

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}

local Service = PNC.ServerInventory
local Const = PNC.Const
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local Actions = PNC.InventoryActions
local Network = PNC.Network

local function notify(player, success, reason, args)
    local payload = {
        success = success == true,
        reason = tostring(reason or (success and "ok" or "failed")),
        npcId = args and args.id and tostring(args.id) or nil,
        requestId = args and args.requestId and tostring(args.requestId) or nil,
    }
    if player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_INVENTORY_RESULT, payload)
    end
    return success == true, payload.reason
end

local function canManage(player, record)
    if not record then return false, "npc_not_found" end
    if not PNC.CompanionCommands or not PNC.CompanionCommands.CanPlayerCommand then
        return false, "command_service_unavailable"
    end
    return PNC.CompanionCommands.CanPlayerCommand(
        record,
        player,
        tonumber(Const.INVENTORY_INTERACTION_RADIUS) or 3
    )
end

local function checkRevision(record, args)
    local inv = Inventory.EnsureRecordInventory(record)
    local expected = tonumber(args and args.inventoryRevision)
    if expected == nil then return false, "revision_missing" end
    if expected ~= tonumber(inv and inv.revision) then
        return false, "revision_conflict"
    end
    return true, expected
end

local function syncResult(player, record, sinceRevision)
    if Network and Network.SendInventoryDelta then
        Network.SendInventoryDelta(player, record, sinceRevision)
    elseif Network and Network.SendCharacterPayload then
        Network.SendCharacterPayload(player, record)
    end
end

local function refreshLiveEquipment(record)
    local body = record and record.id and Registry.GetLiveZombie(record.id) or nil
    if body and PNC.Equipment and PNC.Equipment.Apply then
        PNC.Equipment.Apply(body, record)
    end
end

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

local function compactSpec(item)
    local description, reason = ItemTransfer.DescribeItem(item)
    if not description then return nil, reason end
    if isNonEmptyContainer(item) then return nil, "container_not_empty" end
    local nested = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory()
        or nil
    local state = description.state or {}
    return {
        type = description.fullType,
        stack = 1,
        uses = state.usedDelta,
        cond = state.condition,
        ammoCount = state.ammoCount,
        fav = state.favorite == true,
        customName = state.customName,
        maxWeight = nested and nested.getCapacity and tonumber(nested:getCapacity()) or nil,
        itemState = state,
    }
end

local function rollbackNativeItems(items)
    for _, item in ipairs(items or {}) do
        ItemTransfer.RemoveItem(item)
    end
end

local function compactContainerHasItems(inv, item)
    local container = item and item.bagContainer
        and inv and inv.containers and inv.containers[item.bagContainer]
        or nil
    return container and type(container.items) == "table" and #container.items > 0 or false
end

local function transferPlayerToNPC(player, record, args, sinceRevision)
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local maxItems = tonumber(Const.INVENTORY_TRANSFER_MAX_ITEMS) or 64
    if #itemIDs < 1 or #itemIDs > maxItems then return false, "invalid_item_count" end
    local resolved, reason = ItemTransfer.ResolvePlayerItems(player, itemIDs)
    if not resolved then return false, reason end
    local specs = {}
    for index = 1, #resolved do
        specs[index], reason = compactSpec(resolved[index])
        if not specs[index] then return false, reason end
    end
    local added, addReason, compactIDs = Inventory.AddItems(
        record,
        specs,
        args.npcContainer or "root",
        "player_to_npc"
    )
    if not added then return false, addReason end
    local removed, removeReason = ItemTransfer.TakeFromPlayer(player, itemIDs)
    if not removed then
        Inventory.RemoveItems(record, compactIDs, "player_to_npc_rollback")
        return false, removeReason
    end
    refreshLiveEquipment(record)
    syncResult(player, record, sinceRevision)
    return true, "transferred_to_npc"
end

local function transferNPCToPlayer(player, record, args, sinceRevision)
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local inv = Inventory.EnsureRecordInventory(record)
    local maxItems = tonumber(Const.INVENTORY_TRANSFER_MAX_ITEMS) or 64
    if #itemIDs < 1 or #itemIDs > maxItems then return false, "invalid_item_count" end

    local seen = {}
    local nativeItems = {}
    for index = 1, #itemIDs do
        local itemID = tostring(itemIDs[index] or "")
        local item = inv.items[itemID]
        if itemID == "" or seen[itemID] or not item then
            rollbackNativeItems(nativeItems)
            return false, "item_not_found"
        end
        if compactContainerHasItems(inv, item) then
            rollbackNativeItems(nativeItems)
            return false, "container_not_empty"
        end
        seen[itemID] = true
        local state = {}
        for key, value in pairs(item.itemState or {}) do state[key] = value end
        state.condition = item.cond or state.condition
        state.usedDelta = item.uses or state.usedDelta
        state.ammoCount = item.ammoCount or state.ammoCount
        state.favorite = item.fav == true
        state.customName = item.customName or state.customName
        local created, reason = ItemTransfer.GiveToPlayerContainer(
            player,
            args.playerContainer,
            item.type,
            math.max(1, math.floor(tonumber(item.stack) or 1)),
            state
        )
        if not created then
            rollbackNativeItems(nativeItems)
            return false, reason
        end
        local createdArray = nativeListToArray(created)
        for _, nativeItem in ipairs(createdArray) do
            nativeItems[#nativeItems + 1] = nativeItem
        end
    end

    local removed, reason = Inventory.RemoveItems(record, itemIDs, "npc_to_player")
    if not removed then
        rollbackNativeItems(nativeItems)
        return false, reason
    end
    refreshLiveEquipment(record)
    syncResult(player, record, sinceRevision)
    return true, "transferred_to_player"
end

function Service.Transfer(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local allowed, reason = canManage(player, record)
    if not allowed then return notify(player, false, reason, args) end
    local revisionOK, sinceRevision = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return notify(player, false, sinceRevision, args)
    end
    local success
    if args.direction == "player_to_npc" then
        success, reason = transferPlayerToNPC(player, record, args, sinceRevision)
    elseif args.direction == "npc_to_player" then
        success, reason = transferNPCToPlayer(player, record, args, sinceRevision)
    else
        success, reason = false, "invalid_direction"
    end
    return notify(player, success, reason, args)
end

local function dropItem(player, record, item, sinceRevision)
    local inv = Inventory.EnsureRecordInventory(record)
    if compactContainerHasItems(inv, item) then
        return false, "container_not_empty"
    end
    local body = Registry.GetLiveZombie(record.id)
    local square = body and body.getSquare and body:getSquare() or nil
    if not square and getCell and getCell() and getCell().getGridSquare then
        square = getCell():getGridSquare(
            math.floor(tonumber(record.x) or 0),
            math.floor(tonumber(record.y) or 0),
            math.floor(tonumber(record.z) or 0)
        )
    end
    if not square then return false, "square_unavailable" end
    local state = {}
    for key, value in pairs(item.itemState or {}) do state[key] = value end
    state.condition = item.cond or state.condition
    state.usedDelta = item.uses or state.usedDelta
    state.ammoCount = item.ammoCount or state.ammoCount
    state.customName = item.customName or state.customName
    local dropped, reason = ItemTransfer.DropToSquare(
        square,
        item.type,
        math.max(1, math.floor(tonumber(item.stack) or 1)),
        state
    )
    if not dropped then return false, reason end
    local removed, removeReason = Inventory.RemoveItems(
        record,
        { item.id },
        "inventory_action_drop"
    )
    if not removed then return false, removeReason end
    refreshLiveEquipment(record)
    syncResult(player, record, sinceRevision)
    return true, "dropped"
end

function Service.Action(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local allowed, reason = canManage(player, record)
    if not allowed then return notify(player, false, reason, args) end
    local revisionOK, sinceRevision = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return notify(player, false, sinceRevision, args)
    end
    local inv = Inventory.EnsureRecordInventory(record)
    local item = inv.items[tostring(args.itemID or "")]
    if not item then return notify(player, false, "item_not_found", args) end

    local success
    if tostring(args.actionID or "") == "drop" then
        success, reason = dropItem(player, record, item, sinceRevision)
    else
        success, reason = Actions.Execute(
            args.actionID,
            player,
            record,
            item.id,
            args
        )
        if success then
            refreshLiveEquipment(record)
            syncResult(player, record, sinceRevision)
        end
    end
    return notify(player, success, reason, args)
end

return Service
