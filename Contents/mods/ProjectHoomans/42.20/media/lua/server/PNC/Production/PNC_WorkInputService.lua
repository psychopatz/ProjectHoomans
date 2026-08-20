if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkInputService = PNC.WorkInputService or {}

local Service = PNC.WorkInputService

function Service.Bind(payload, storageId, reservationId, stage)
    payload = type(payload) == "table" and payload or {}
    payload.input = {
        storageId = tostring(storageId or ""),
        reservationId = tostring(reservationId or ""),
        stage = tostring(stage or "work_inputs"),
        consume = true,
    }
    return payload
end

local function inputFor(order)
    local input = order and order.payload and order.payload.input or nil
    return type(input) == "table" and input or nil
end

function Service.RequiresCollection(order)
    local input = inputFor(order)
    return input ~= nil and input.consume == true
        and input.committed ~= true and input.staged ~= true
end

function Service.IsReady(order)
    local input = inputFor(order)
    if not input or input.committed == true or input.staged == true then
        return true
    end
    if PNC.ColonyStorageService.HasProductionTransactionStage(
        input.storageId, order.id, input.stage)
    then
        if input.itemIds then input.staged = true else input.committed = true end
        PNC.WorkRepository.MarkDirty()
        return true
    end
    return PNC.ColonyStorageService.GetProductionReservation(
        input.reservationId) ~= nil
end

function Service.ReplaceReservation(order, reservation)
    local input = inputFor(order)
    if not input or not reservation then return false end
    input.reservationId = reservation.id
    PNC.WorkRepository.MarkDirty()
    return true
end

-- Construction is funded when the project is created.  This deliberately
-- uses the storage transaction API instead of touching inventory internals;
-- the resulting order no longer depends on a reservation surviving a save,
-- a worker replacement, or a live/abstract handoff.
function Service.Fund(order, actor, reason)
    local input = inputFor(order)
    if not input then return false, "WORK_INPUT_MISSING" end
    if input.funded == true or input.committed == true then
        input.funded, input.committed = true, true
        input.reservationId, input.storageId, input.stage = nil, nil, nil
        input.itemIds, input.records = nil, nil
        return true, "already_funded"
    end
    if input.reservationId == "" or input.storageId == "" then
        return false, "WORK_INPUT_RESERVATION_MISSING"
    end
    local ok, why = PNC.ColonyStorageService.CommitProductionReservation(
        input.reservationId, order.id, input.stage, input.storageId,
        actor and tostring(actor.name or actor.id) or order.workerId,
        reason or "project_funding")
    if not ok then return false, why end
    input.funded, input.committed = true, true
    -- Keep only the semantic marker. Reservation and collection details are
    -- runtime/transaction state and must not be carried by the work order.
    input.reservationId, input.storageId, input.stage = nil, nil, nil
    input.itemIds, input.records = nil, nil
    PNC.WorkRepository.MarkDirty()
    return true, "funded"
end

function Service.Collect(order, worker)
    local input = inputFor(order)
    if not input then return false, "WORK_INPUT_MISSING" end
    if input.staged == true or input.committed == true then return true end
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        input.reservationId, order.id, input.stage, input.storageId, worker)
    if not ok then return false, details end
    input.staged = true
    input.itemIds = details.itemIds or {}
    input.records = details.records or {}
    PNC.WorkRepository.MarkDirty()
    return true
end

function Service.Commit(order, reason)
    local input = inputFor(order)
    if not input or input.committed == true then return true end
    local ok, why
    local worker = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if input.staged == true then
        local commands = PNC.SupplyInventory and PNC.SupplyInventory.Commands
        if commands and commands.RemoveCoreItemIds then
            ok, why = commands.RemoveCoreItemIds(worker, input.itemIds or {},
                reason or "work_input_consumption")
        else
            ok, why = false, "worker_inventory_unavailable"
        end
    else
        ok, why = PNC.ColonyStorageService.CommitProductionReservation(
            input.reservationId, order.id, input.stage, input.storageId,
            worker and tostring(worker.name or worker.id) or order.workerId,
            reason)
    end
    if not ok then return false, why end
    input.committed = true
    PNC.WorkRepository.MarkDirty()
    return true
end

function Service.Cancel(order)
    local input = inputFor(order)
    if not input or input.committed == true then return true end
    if input.staged == true and input.itemIds and order.workerId then
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(order.workerId) or nil
        local returned, reason =
            PNC.ColonyStorageService.ReturnCollectedProductionRecords(
                input.storageId, worker, input.itemIds, input.records or {})
        if not returned then return false, reason end
        PNC.ColonyStorageService.ForgetProductionTransaction(
            input.storageId, order.id)
        input.staged, input.itemIds, input.records = false, nil, nil
        input.reservationId = ""
        PNC.WorkRepository.MarkDirty()
        return true
    end
    if input.reservationId ~= "" then
        return PNC.ColonyStorageService.ReleaseProductionReservation(
            input.reservationId)
    end
    return true
end

return Service
