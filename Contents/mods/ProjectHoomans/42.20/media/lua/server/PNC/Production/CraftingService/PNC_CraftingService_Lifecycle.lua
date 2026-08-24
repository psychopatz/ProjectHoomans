if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}
PNC.CraftingServiceInternal = PNC.CraftingServiceInternal or {}

local Service = PNC.CraftingService
local H = PNC.CraftingServiceInternal
local Registry = PNC.RecipeKnowledgeRegistry

function H.Cancellation(order)
    local payload = order.payload or {}
    if payload.input then
        PNC.WorkInputService.Cancel(order)
    elseif payload.inputsStaged == true and payload.stagedItemIds
        and order.workerId
    then
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(order.workerId) or nil
        local returned = PNC.ColonyStorageService.ReturnCollectedProductionRecords(
            payload.storageId, worker, payload.stagedItemIds,
            payload.stagedRecords or {})
        if returned then
            PNC.ColonyStorageService.ForgetProductionTransaction(
                payload.storageId, order.id)
            payload.inputsStaged = false
            payload.stagedItemIds, payload.stagedRecords = nil, nil
            payload.reservationId = nil
        end
    elseif payload.reservationId and payload.inputsCommitted ~= true
        and payload.specimenCommitted ~= true
    then PNC.ColonyStorageService.ReleaseProductionReservation(payload.reservationId) end
end

function H.Collect(order, worker)
    local payload = order.payload or {}
    if payload.inputsStaged == true then return true end
    local stage = order.operation == "CRAFT" and "craft_inputs"
        or "disassembly_specimen"
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        payload.reservationId, order.id, stage, payload.storageId, worker)
    if not ok then return false, details end
    payload.inputsStaged = true
    payload.stagedItemIds = details.itemIds or {}
    payload.stagedRecords = details.records or {}
    PNC.WorkRepository.MarkDirty()
    return true
end

function H.Prepare(order)
    local payload = order.payload or {}
    if payload.input and PNC.WorkInputService.IsReady(order) then return true end
    if order.operation == "CRAFT" and PNC.ColonyStorageService
        .HasProductionTransactionStage(payload.storageId, order.id, "craft_inputs")
    then
        if payload.stagedItemIds then payload.inputsStaged = true
        else payload.inputsCommitted = true end
        return true
    end
    if order.operation == "DISASSEMBLE" and PNC.ColonyStorageService
        .HasProductionTransactionStage(payload.storageId, order.id,
            "disassembly_specimen")
    then
        if payload.stagedItemIds then payload.inputsStaged = true
        else payload.specimenCommitted = true end
        return true
    end
    if payload.inputsCommitted == true or payload.specimenCommitted == true then
        return true
    end
    if payload.reservationId
        and PNC.ColonyStorageService.GetProductionReservation(payload.reservationId)
    then return true end
    local reservation, reason
    if order.operation == "CRAFT" then
        reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
            payload.storageId, payload.requirements, "craft:" .. order.id)
    else
        reservation, reason = PNC.ColonyStorageService.ReserveProductionMatchingRecord(
            payload.storageId, { fullType = payload.specimenFullType }, 1,
            "disassemble:" .. order.id)
    end
    if not reservation then return false, reason end
    payload.reservationId = reservation.id
    if payload.input then
        PNC.WorkInputService.ReplaceReservation(order, reservation)
    end
    PNC.WorkRepository.MarkDirty()
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.CRAFT = H.Cancellation
PNC.WorkService.CancellationHandlers.DISASSEMBLE = H.Cancellation
PNC.WorkService.RegisterPreparation("CRAFT", H.Prepare)
PNC.WorkService.RegisterPreparation("DISASSEMBLE", H.Prepare)
PNC.WorkService.RegisterCollection("CRAFT", H.Collect)
PNC.WorkService.RegisterCollection("DISASSEMBLE", H.Collect)
PNC.WorkService.RegisterCompletion("CRAFT", H.CraftCompletion)
PNC.WorkService.RegisterCompletion("DISASSEMBLE", H.DisassemblyCompletion)

