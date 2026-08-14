if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

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

function Service.RequestNPCDeposit(player, args)
    args = type(args) == "table" and args or {}
    local function finish(ok, reason, details, storage, record)
        Internal.LogTransaction(player, args, "npc_deposit", ok, reason,
            storage, details)
        return ok, reason, details, storage, record
    end
    if not Internal.RememberRequest(player, args.requestId) then
        return finish(false, "duplicate_request")
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return finish(false, reason) end
    local record = args.npcId and PNC.Registry.Get(tostring(args.npcId)) or nil
    if not record then return finish(false, "npc_not_found", nil, storage) end
    local ownsNPC = PNC.CompanionCommands
        and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player) == true
    if not ownsNPC and not Internal.DebugAllowed(player) then
        return finish(false, "npc_not_owned", nil, storage, record)
    end
    local inv = PNC.Inventory.EnsureRecordInventory(record)
    if tonumber(args.inventoryRevision) ~= tonumber(inv.revision) then
        return finish(false, "revision_conflict", nil, storage, record)
    end
    local item = inv.items[tostring(args.itemID or "")]
    if not item then return finish(false, "item_not_found", nil, storage, record) end
    if item.interactionLocked == true then return finish(false, "item_off_limits", nil, storage, record) end
    if item.equipSlot or item.wornSlot or item.attachedSlot then
        return finish(false, "equipped_item", nil, storage, record)
    end
    local quantity = math.max(1, math.min(
        math.floor(tonumber(args.quantity) or 1),
        math.floor(tonumber(item.stack) or 1)
    ))
    local body = PNC.Registry.GetLiveZombie(record.id)
    local source
    if body then
        source, reason = Internal.LiveNPCSource(record, item, quantity, body)
    else
        source = Internal.AbstractNPCSource(record, item, quantity)
    end
    if not source then return finish(false, reason, nil, storage, record) end
    local ok, why, details = Internal.TransferIntoStorage(
        storage, source, quantity
    )
    if not ok then
        Service.Metrics.transferFailures = Service.Metrics.transferFailures + 1
    else
        Internal.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), {{
                fullType = item.type,
                quantity = quantity,
            }}, args.reason)
    end
    return finish(ok, why, details, storage, record)
end

local function updateCourier(record, state, reason, details)
    record.runtime = record.runtime or {}
    local job = record.runtime.storageCourier or {}
    job.state = tostring(state or "FAILED")
    job.reason = reason and tostring(reason) or nil
    job.updatedAt = PNC.Core.Now()
    job.revision = math.max(0, math.floor(tonumber(job.revision) or 0)) + 1
    if details then
        job.itemCount = tonumber(details.itemCount) or job.itemCount
        job.quantity = tonumber(details.quantity) or job.quantity
    end
    record.runtime.storageCourier = job
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "storage_courier_" .. string.lower(job.state))
    end
    return job
end

local function notifyCourierOwner(record)
    local job = record.runtime and record.runtime.storageCourier or nil
    local owner = job and PNC.Core.ResolvePlayerByUsername
        and PNC.Core.ResolvePlayerByUsername(job.requestedBy) or nil
    if owner and PNC.Network and PNC.Network.SendCharacterPayload then
        PNC.Network.SendCharacterPayload(owner, record)
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "storage_courier")
    end
end

function Service.CompleteNPCCourier(record)
    local job = record and record.runtime and record.runtime.storageCourier or nil
    if not job or job.state ~= "RETURNING_HOME"
        and job.state ~= "DEPOSITING"
    then return false, "courier_not_pending" end
    if record.alive == false then
        updateCourier(record, "FAILED", "npc_not_available")
        notifyCourierOwner(record)
        return false, "npc_not_available"
    end
    if not PNC.HomeDutyService.IsAtHome(record, job.baseId) then
        return false, "courier_not_home"
    end
    local storage = Internal.Repository.Get(job.storageId)
    if not storage then
        updateCourier(record, "FAILED", "storage_not_found")
        notifyCourierOwner(record)
        return false, "storage_not_found"
    end
    updateCourier(record, "DEPOSITING")
    local source, reason, items, quantity = Internal.NPCBulkSource(record)
    if not source then
        local state = reason == "no_depositable_items" and "COMPLETED" or "FAILED"
        updateCourier(record, state, reason, { itemCount = 0, quantity = 0 })
        notifyCourierOwner(record)
        return state == "COMPLETED", reason
    end
    local ok, details
    ok, reason, details = Internal.TransferIntoStorage(storage, source, quantity)
    if ok then
        local activity = {}
        for index = 1, #items do
            activity[#activity + 1] = {
                fullType = items[index].type,
                quantity = math.max(1,
                    math.floor(tonumber(items[index].stack) or 1)),
            }
        end
        Internal.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), activity, "npc_courier")
        updateCourier(record, "COMPLETED", "deposited", {
            itemCount = #items, quantity = quantity,
        })
    else
        Service.Metrics.transferFailures = Service.Metrics.transferFailures + 1
        updateCourier(record, "FAILED", reason)
    end
    notifyCourierOwner(record)
    return ok, reason, details, storage, record
end

function Service.RequestNPCCourierDeposit(player, args)
    args = type(args) == "table" and args or {}
    if not Internal.RememberRequest(player, args.requestId) then
        return false, "duplicate_request"
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return false, reason end
    local access = Service.BuildPlayerAccess(player, storage)
    if access.hasStockpile ~= true then
        return false, "stockpile_required", nil, storage
    end
    local record = args.npcId and PNC.Registry.Get(tostring(args.npcId)) or nil
    if not record or record.alive == false then
        return false, "npc_not_found", nil, storage, record
    end
    local ownsNPC = PNC.CompanionCommands
        and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player) == true
    if not ownsNPC and not Internal.DebugAllowed(player) then
        return false, "npc_not_owned", nil, storage, record
    end
    local source, emptyReason = Internal.NPCBulkSource(record)
    if not source then
        return false, emptyReason, nil, storage, record
    end
    record.runtime = record.runtime or {}
    record.runtime.storageCourier = {
        id = PNC.Core.GenerateID("storage_courier"),
        state = "RETURNING_HOME",
        storageId = storage.id,
        baseId = access.baseId,
        requestedBy = player and player.getUsername
            and tostring(player:getUsername() or "") or "",
        requestedAt = PNC.Core.Now(),
        updatedAt = PNC.Core.Now(),
        revision = 1,
    }
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
        and record.runtime.workOrderId
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id,
            "storage_courier_requested")
    end
    if PNC.HomeDutyService.IsAtHome(record, access.baseId) then
        local ok, why, details = Service.CompleteNPCCourier(record)
        return ok, why, details, storage, record
    end
    local sent, sendReason, journey = PNC.HomeDutyService.SendHome(
        record, access.baseId, "storage_courier")
    if not sent then
        updateCourier(record, "FAILED", sendReason)
        return false, sendReason, nil, storage, record
    end
    updateCourier(record, "RETURNING_HOME", sendReason)
    return true, "courier_returning_home", {
        courier = PNC.Core.DeepCopy(record.runtime.storageCourier),
        journeyId = journey and journey.journeyId or nil,
    }, storage, record
end

return Service
