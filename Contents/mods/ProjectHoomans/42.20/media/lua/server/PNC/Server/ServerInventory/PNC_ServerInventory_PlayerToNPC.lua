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
local isNativeBulkProtected = Internal.isNativeBulkProtected
local isNonEmptyContainer = Internal.isNonEmptyContainer
local compactSpec = Internal.compactSpec
local refreshLiveEquipment = Internal.refreshLiveEquipment
local syncResult = Internal.syncResult

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
        if args.gift == true and PNC.Gifts
            and PNC.Gifts.IsValidItemType
            and not PNC.Gifts.IsValidItemType(specs[index].type)
        then
            return false, "gift_item_invalid"
        end
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

Internal.transferPlayerToNPC = transferPlayerToNPC
