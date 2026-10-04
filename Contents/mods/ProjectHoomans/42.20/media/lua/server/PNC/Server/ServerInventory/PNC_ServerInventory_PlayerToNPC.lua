if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Const = PNC.Const
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local ItemTransfer = Internal.ItemTransfer
local isNativeBulkProtected = Internal.isNativeBulkProtected
local isNonEmptyContainer = Internal.isNonEmptyContainer
local isNativeIdentityItem = Internal.isNativeIdentityItem
local compactSpec = Internal.compactSpec
local refreshLiveEquipment = Internal.refreshLiveEquipment
local syncResult = Internal.syncResult
local transferCurrency = Internal.transferPlayerToNPCCurrency

local function rollbackProjections(projections)
    for index = #(projections or {}), 1, -1 do
        local undo = projections[index]
        if type(undo) == "function" then pcall(undo) end
    end
end

-- A colonist who is handed a radio wears it instead of bagging it. Returns the
-- compact item ID that was moved onto the belt so the caller can skip the loose
-- projection for it: equipped items are projected by Equipment.Apply, and adding
-- a second native copy would duplicate the radio.
local function adoptRadioGear(record, compactIDs)
    local radioGear = PNC.Equipment and PNC.Equipment.RadioGear or nil
    local inv = record and record.inventory or nil
    local item
    if not radioGear or type(radioGear.AdoptFromInventory) ~= "function" then
        return nil
    end
    if not inv or not inv.items then return nil end
    for index = 1, #(compactIDs or {}) do
        item = inv.items[tostring(compactIDs[index])]
        if item and radioGear.IsRadioType(item.type) then
            -- Either the radio is now equipped or the colonist already had one
            -- (or has no free belt slot); in both cases the item stays carried.
            if radioGear.AdoptFromInventory(record, item.id, item.type) == true
            then
                return item.id
            end
            return nil
        end
    end
    return nil
end

local function transferPlayerToNPC(player, record, args, sinceRevision)
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local currencyAmount = math.floor(tonumber(args.currencyAmount) or 0)
    if currencyAmount > 0 then
        if type(transferCurrency) ~= "function" then
            return false, "currency_service_unavailable"
        end
        return transferCurrency(player, record, args, sinceRevision)
    end
    local maxItems = tonumber(Const.INVENTORY_TRANSFER_MAX_ITEMS) or 64
    if #itemIDs < 1 or #itemIDs > maxItems then return false, "invalid_item_count" end
    local resolved, reason = ItemTransfer.ResolvePlayerItems(player, itemIDs)
    if not resolved then return false, reason end
    for index = 1, #resolved do
        local protected, protectedReason = isNativeIdentityItem(
            resolved[index]
        )
        if protected then return false, protectedReason end
    end
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
    local equippedRadioID = adoptRadioGear(record, compactIDs)
    local projections = {}

    -- Undo the whole transfer, including the belt slot the radio may have been
    -- moved into, so the equipment mirror never keeps a dangling item ID.
    local function revertTransfer(reason)
        if equippedRadioID and Inventory.ClearAttached then
            Inventory.ClearAttached(record, equippedRadioID,
                "player_to_npc_projection_rollback")
        end
        rollbackProjections(projections)
        Inventory.RemoveItems(record, compactIDs, "player_to_npc_rollback")
        return false, reason
    end

    -- AddItems owns the persistent compact model, while a live zombie also
    -- needs a native projection for gameplay consumers.  Without this step
    -- the UI showed the gift, but SupplyInventory.Consume correctly rejected
    -- it as physically absent and the NPC remained hungry.
    local body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    if body then
        if not Inventory.MaterializeItem then
            return revertTransfer("live_inventory_projection_unavailable")
        end
        for index = 1, #compactIDs do
            if tostring(compactIDs[index]) ~= tostring(equippedRadioID) then
                local projected, projectionReason, undo =
                    Inventory.MaterializeItem(record, body, compactIDs[index])
                if not projected then
                    return revertTransfer(projectionReason)
                end
                projections[#projections + 1] = undo
            end
        end
    end
    local removed, removeReason = ItemTransfer.TakeFromPlayer(player, itemIDs)
    if not removed then
        return revertTransfer(removeReason)
    end
    refreshLiveEquipment(record)
    syncResult(player, record, sinceRevision)
    return true, "transferred_to_npc", {
        itemTypes = itemTypes,
        -- Compact IDs are authoritative NPC-inventory identities. Returning
        -- them lets the client keep a discourse reference such as "it"
        -- tied to the actual gifted item without trusting a client ID for
        -- mutation. Any later task still revalidates this ID on the server.
        itemIDs = compactIDs,
        itemCount = #itemTypes,
    }
end

Internal.transferPlayerToNPC = transferPlayerToNPC
