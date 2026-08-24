if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Const = PNC.Const
local Inventory = PNC.Inventory
local ItemTransfer = Internal.ItemTransfer
local nativeListToArray = Internal.nativeListToArray
local isCompactBulkProtected = Internal.isCompactBulkProtected
local rollbackNativeItems = Internal.rollbackNativeItems
local compactContainerHasItems = Internal.compactContainerHasItems
local portableCompactItemState = Internal.portableCompactItemState
local refreshLiveEquipment = Internal.refreshLiveEquipment
local syncResult = Internal.syncResult

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
                local state = portableCompactItemState(record, item)
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

Internal.transferNPCToPlayer = transferNPCToPlayer
