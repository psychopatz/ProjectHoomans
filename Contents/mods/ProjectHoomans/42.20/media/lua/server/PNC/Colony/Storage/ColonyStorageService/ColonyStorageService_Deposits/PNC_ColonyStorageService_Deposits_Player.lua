if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal

function Service.RequestPlayerDeposit(player, args)
    args = type(args) == "table" and args or {}
    local function finish(ok, reason, details, storage)
        Internal.LogTransaction(player, args, "player_deposit", ok, reason,
            storage, details)
        return ok, reason, details, storage
    end
    if not Internal.RememberRequest(player, args.requestId) then
        return finish(false, "duplicate_request")
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return finish(false, reason) end
    local accessible
    accessible, reason = Service.RequirePlayerAccess(player, storage)
    if not accessible then return finish(false, reason, nil, storage) end
    local items
    items, reason = Internal.SelectedPlayerItems(player, args.itemIDs)
    if not items then return finish(false, reason, nil, storage) end
    for index = 1, #items do
        local favorite = items[index].isFavorite
            and items[index]:isFavorite() == true
        local equipped = player and player.isEquipped
            and player:isEquipped(items[index]) == true
        if favorite then return finish(false, "favorite_item", nil, storage) end
        if equipped then return finish(false, "equipped_item", nil, storage) end
    end
    local source = Internal.PhysicalSelectionSource(items)
    local ok, why, details = Internal.TransferIntoStorage(
        storage, source, #items
    )
    if not ok then
        Service.Metrics.transferFailures = Service.Metrics.transferFailures + 1
    else
        Internal.RecordActivity(storage, "STORE",
            Internal.PlayerName(player), Internal.NativeItemSpecs(items),
            args.reason)
    end
    return finish(ok, why, details, storage)
end

function Service.RequestPlayerWithdrawal(player, args)
    args = type(args) == "table" and args or {}
    local function finish(ok, reason, details, storage)
        Internal.LogTransaction(player, args, "player_withdraw", ok, reason,
            storage, details)
        return ok, reason, details, storage
    end
    if not Internal.RememberRequest(player, args.requestId) then
        return finish(false, "duplicate_request")
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return finish(false, reason) end
    local accessible
    accessible, reason = Service.RequirePlayerAccess(player, storage)
    if not accessible then return finish(false, reason, nil, storage) end
    if tonumber(args.inventoryRevision) ~= tonumber(storage.inventory.revision) then
        return finish(false, "revision_conflict", nil, storage)
    end
    local selections = type(args.records) == "table" and args.records or {}
    local maxItems = tonumber(PNC.Const.INVENTORY_TRANSFER_MAX_ITEMS) or 64
    local maxQuantity = tonumber(PNC.Const.INVENTORY_TRANSFER_MAX_QUANTITY) or 1024
    if #selections < 1 or #selections > maxItems then
        return finish(false, "invalid_item_count", nil, storage)
    end
    local quantity = 0
    for index = 1, #selections do
        quantity = quantity + math.max(1,
            math.floor(tonumber(selections[index].quantity) or 1))
    end
    if quantity > maxQuantity then
        return finish(false, "invalid_quantity", nil, storage)
    end
    local activityItems = Internal.StorageSelectionSpecs(storage, selections)
    local owner = "player:" .. tostring(player and player.getUsername
        and player:getUsername() or player)
    local source
    source, reason = Internal.StorageSelectionSource(
        storage, selections, owner
    )
    if not source then return finish(false, reason, nil, storage) end
    local destination
    destination, reason = Internal.PlayerDestination(
        player, args.playerContainer
    )
    if not destination then
        source:release()
        return finish(false, reason, nil, storage)
    end
    local ok
    ok, reason = Internal.CoreInventory.transfer(
        source, destination, nil, quantity
    )
    if not ok then
        source:release()
        Service.Metrics.transferFailures = Service.Metrics.transferFailures + 1
        return finish(false, reason, nil, storage)
    end
    Internal.CommitStorage(storage)
    Internal.RecordActivity(storage, "TAKE", Internal.PlayerName(player),
        activityItems, args.reason)
    Service.Metrics.withdrawals = Service.Metrics.withdrawals + 1
    return finish(true, "withdrawn", { quantity = quantity }, storage)
end

return Service

