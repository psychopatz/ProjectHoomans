if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal

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

