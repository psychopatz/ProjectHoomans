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

local function canUseDebug(player)
    local access
    if not isServer or not isServer() then
        if isDebugEnabled then return isDebugEnabled() == true end
        return getCore and getCore() and getCore():getDebug() == true or false
    end
    access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

local function notify(player, success, reason, args, details)
    local payload = {
        success = success == true,
        reason = tostring(reason or (success and "ok" or "failed")),
        npcId = args and args.id and tostring(args.id) or nil,
        requestId = args and args.requestId and tostring(args.requestId) or nil,
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        payload[key] = value
    end
    if player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_INVENTORY_RESULT, payload)
    end
    return success == true, payload.reason, payload
end

local function canGift(player, record, args)
    if not player or not record then return false, "npc_not_found" end
    if args.direction ~= "player_to_npc" then
        return false, "gift_direction_invalid"
    end
    local lease = record.runtime and record.runtime.conversationLease or nil
    if not lease or tostring(lease.token or "")
        ~= tostring(args.conversationToken or "")
    then
        return false, "conversation_lease_required"
    end
    local faction = tostring(record.faction or "")
    if faction == tostring(Const.FACTION_HOSTILE) then
        return false, "hostile_gift_forbidden"
    end
    if PNC.ConversationScene and PNC.ConversationScene.Begin then
        local ok, reason = PNC.ConversationScene.Begin(
            record,
            Registry.GetLiveZombie(record.id),
            player,
            args.conversationToken,
            {
                maximumDistance = lease.maximumDistance,
                dangerRadius = lease.dangerRadius,
                allowHostileParley = false,
            }
        )
        if ok ~= true then return false, reason or "conversation_unavailable" end
    end
    return true, "gift_authorized"
end

PNC.Gifts = PNC.Gifts or {}
local giftEffect = PNC.Gifts.EvaluateEffect

local function relationshipSnapshot(value)
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = value.state,
    }
end

local function canManage(player, record)
    if not record then return false, "npc_not_found" end
    if canUseDebug(player) then return true, "debug_authorized" end
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

local function compactSpec(item)
    local description, reason = ItemTransfer.DescribeItem(item)
    if not description then return nil, reason end
    if isNonEmptyContainer(item) then return nil, "container_not_empty" end
    local nested = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory()
        or nil
    local state = description.state or {}
    local reduction = item.getWeightReduction
        and tonumber(item:getWeightReduction())
        or nil
    if reduction and reduction > 1 then reduction = reduction / 100 end
    local wearableSlot = item.canBeEquipped
        and tostring(item:canBeEquipped() or "")
        or nil
    if wearableSlot == "" then wearableSlot = nil end
    return {
        type = description.fullType,
        stack = 1,
        uses = state.usedDelta,
        cond = state.condition,
        ammoCount = state.ammoCount,
        fav = state.favorite == true,
        customName = state.customName,
        maxWeight = nested and nested.getCapacity and tonumber(nested:getCapacity()) or nil,
        weightReduction = reduction,
        wearableSlot = wearableSlot,
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
    if args.bulk == true then
        local eligibleIDs = {}
        local eligibleItems = {}
        for index = 1, #resolved do
            if not isNativeBulkProtected(player, resolved[index])
                and not isNonEmptyContainer(resolved[index])
            then
                eligibleIDs[#eligibleIDs + 1] = itemIDs[index]
                eligibleItems[#eligibleItems + 1] = resolved[index]
            end
        end
        itemIDs = eligibleIDs
        resolved = eligibleItems
        if #itemIDs < 1 then return false, "no_transferable_items" end
    elseif args.quantity ~= nil then
        local quantity = math.floor(tonumber(args.quantity) or 0)
        if quantity < 1 or quantity > #resolved then
            return false, "invalid_quantity"
        end
        while #resolved > quantity do
            resolved[#resolved] = nil
            itemIDs[#itemIDs] = nil
        end
    end
    local specs = {}
    local itemTypes = {}
    for index = 1, #resolved do
        specs[index], reason = compactSpec(resolved[index])
        if not specs[index] then return false, reason end
        itemTypes[#itemTypes + 1] = specs[index].type
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
    return true, "transferred_to_npc", {
        itemTypes = itemTypes,
        itemCount = #itemTypes,
    }
end

local function transferNPCToPlayer(player, record, args, sinceRevision)
    local requestedIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local inv = Inventory.EnsureRecordInventory(record)
    local maxItems = tonumber(Const.INVENTORY_TRANSFER_MAX_ITEMS) or 64
    local maxQuantity = tonumber(Const.INVENTORY_TRANSFER_MAX_QUANTITY) or 1024
    local requestedQuantity = args.bulk ~= true and args.quantity ~= nil
        and math.floor(tonumber(args.quantity) or 0) or nil
    if #requestedIDs < 1 or #requestedIDs > maxItems then
        return false, "invalid_item_count"
    end
    if requestedQuantity ~= nil
        and (requestedQuantity < 1 or requestedQuantity > maxQuantity)
    then
        return false, "invalid_quantity"
    end

    local seen = {}
    local nativeItems = {}
    local plans = {}
    local remaining = requestedQuantity
    for index = 1, #requestedIDs do
        local itemID = tostring(requestedIDs[index] or "")
        local item = inv.items[itemID]
        if itemID == "" or seen[itemID] or not item then
            rollbackNativeItems(nativeItems)
            return false, "item_not_found"
        end
        if args.bulk ~= true and item.interactionLocked == true then
            rollbackNativeItems(nativeItems)
            return false, "item_off_limits"
        end
        if args.bulk ~= true and compactContainerHasItems(inv, item) then
            rollbackNativeItems(nativeItems)
            return false, "container_not_empty"
        end
        seen[itemID] = true
        if args.bulk == true
            and (isCompactBulkProtected(item)
                or compactContainerHasItems(inv, item))
        then
            -- Vanilla bulk transfer leaves favorites, equipped items, and
            -- non-empty carried containers in place.
        else
            local available = math.max(
                1,
                math.floor(tonumber(item.stack) or 1)
            )
            local transferCount = remaining ~= nil
                and math.min(available, math.max(0, remaining))
                or available
            if transferCount > 0 then
                local state = {}
                for key, value in pairs(item.itemState or {}) do
                    state[key] = value
                end
                state.condition = item.cond or state.condition
                state.usedDelta = item.uses or state.usedDelta
                state.ammoCount = item.ammoCount or state.ammoCount
                state.favorite = item.fav == true
                state.customName = item.customName or state.customName
                local created, reason = ItemTransfer.GiveToPlayerContainer(
                    player,
                    args.playerContainer,
                    item.type,
                    transferCount,
                    state
                )
                if not created then
                    rollbackNativeItems(nativeItems)
                    return false, reason
                end
                plans[#plans + 1] = {
                    itemID = itemID,
                    previousStack = available,
                    quantity = transferCount,
                }
                local createdArray = nativeListToArray(created)
                for _, nativeItem in ipairs(createdArray) do
                    nativeItems[#nativeItems + 1] = nativeItem
                end
                if remaining ~= nil then
                    remaining = remaining - transferCount
                end
            end
        end
    end

    if #plans < 1 then return false, "no_transferable_items" end
    if remaining ~= nil and remaining > 0 then
        rollbackNativeItems(nativeItems)
        return false, "quantity_unavailable"
    end

    local removeIDs = {}
    local ops = {}
    local partial = false
    for index = 1, #plans do
        local plan = plans[index]
        if plan.quantity >= plan.previousStack then
            removeIDs[#removeIDs + 1] = plan.itemID
            ops[#ops + 1] = { op = "remove", itemID = plan.itemID }
        else
            partial = true
            ops[#ops + 1] = {
                op = "update",
                itemID = plan.itemID,
                stack = plan.previousStack - plan.quantity,
            }
        end
    end
    local mutated
    local reason
    if partial then
        mutated = Inventory.ApplyDelta(
            record,
            ops,
            "npc_to_player_partial"
        )
        reason = "remove_failed"
    else
        mutated, reason = Inventory.RemoveItems(
            record,
            removeIDs,
            "npc_to_player"
        )
    end
    if not mutated then
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
    local giftMode = args.gift == true
    local allowed, reason
    if giftMode then
        allowed, reason = canGift(player, record, args)
    else
        allowed, reason = canManage(player, record)
    end
    if not allowed then return notify(player, false, reason, args) end
    local revisionOK, sinceRevision = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return notify(player, false, sinceRevision, args)
    end
    local success
    local details
    if args.direction == "player_to_npc" then
        success, reason, details = transferPlayerToNPC(
            player, record, args, sinceRevision
        )
    elseif args.direction == "npc_to_player" then
        success, reason = transferNPCToPlayer(player, record, args, sinceRevision)
    else
        success, reason = false, "invalid_direction"
    end
    if success and giftMode then
        local gift = giftEffect(details and details.itemTypes or {})
        local playerKey = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetEntityKey
            and PNC.PlayerCharacters.GetEntityKey(player, {
                callback = "conversation_gift",
                worldAgeHours = getGameTime and getGameTime()
                    and getGameTime():getWorldAgeHours() or 0,
            }) or nil
        local applied
        local applyReason
        local result
        local relationshipBefore = PNC.Relationships
            and PNC.Relationships.Get
            and relationshipSnapshot(PNC.Relationships.Get(record.id, playerKey))
            or relationshipSnapshot(nil)
        if playerKey and PNC.Relationships
            and PNC.Relationships.ApplyConversationEffect
        then
            applied, applyReason, result = PNC.Relationships.ApplyConversationEffect(
                record.id,
                playerKey,
                gift,
                {
                    blockID = "projecthoomans:needs_gift",
                    choiceID = "gift",
                    outcomeID = args.requestId or details and details.itemTypes
                        and details.itemTypes[1] or "gift",
                    worldAgeHours = getGameTime and getGameTime()
                        and getGameTime():getWorldAgeHours() or 0,
                }
            )
        end
        if applied == true and result and result.relationship then
            local relationshipAfter = relationshipSnapshot(result.relationship)
            details.relationshipBefore = relationshipBefore
            details.relationshipAfter = relationshipAfter
            details.relationshipDelta = {
                approval = relationshipAfter.approval - relationshipBefore.approval,
                respect = relationshipAfter.respect - relationshipBefore.respect,
                familiarity = relationshipAfter.familiarity - relationshipBefore.familiarity,
            }
            details.giftEffect = gift
        else
            details.giftEffectError = applyReason or "relationship_unavailable"
        end
        if Registry.Save then Registry.Save() end
    end
    return notify(player, success, reason, args, details)
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
    if item.interactionLocked == true then
        return notify(player, false, "item_off_limits", args)
    end

    local success
    if tostring(args.actionID or "") == "drop" then
        success, reason = dropItem(player, record, item, sinceRevision)
    else
        local definition = Actions.Get and Actions.Get(args.actionID) or nil
        success, reason = Actions.Execute(
            args.actionID,
            player,
            record,
            item.id,
            args
        )
        if success then
            if not definition or definition.refreshEquipment ~= false then
                refreshLiveEquipment(record)
            end
            syncResult(player, record, sinceRevision)
        end
    end
    return notify(player, success, reason, args)
end

return Service
