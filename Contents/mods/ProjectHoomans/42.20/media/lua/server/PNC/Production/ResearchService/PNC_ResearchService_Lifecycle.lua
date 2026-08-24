-- Research work-order preparation, completion, and cancellation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Internal = Service.Internal
local Definitions = PNC.ColonyResearchDefinitions
local researchTarget = Internal.ResearchTarget

local function completion(order)
    local payload = order.payload or {}
    if payload.mode == "technology" then
        return Service.Commands.UnlockTechnology(order.colonyId,
            payload.technologyId, order.factionId)
    end
    if payload.mode ~= "blueprint" and payload.mode ~= "reverse" then
        return false, "RESEARCH_MODE_UNKNOWN"
    end
    if payload.resourceCommitted ~= true then
        local consume = payload.mode == "reverse"
            or Definitions.POLICY.consumeBlueprintOnCompletion == true
        local ok, reason
        if consume and payload.input then
            ok, reason = PNC.WorkInputService.Commit(order,
                "research_resource_consumption")
        elseif consume then
            ok, reason = PNC.ColonyStorageService.CommitProductionReservation(
                payload.reservationId, order.id, "research_resource",
                payload.storageId)
        else
            ok, reason = PNC.ColonyStorageService.ReleaseProductionReservation(
                payload.reservationId)
        end
        if not ok then return false, reason end
        payload.resourceCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    return Service.Commands.UnlockRecipe(order.colonyId, order.recipeId,
        order.factionId)
end

local function cancellation(order)
    local payload = order.payload or {}
    if payload.input then
        PNC.WorkInputService.Cancel(order)
    elseif payload.reservationId and payload.resourceCommitted ~= true then
        PNC.ColonyStorageService.ReleaseProductionReservation(payload.reservationId)
    end
end

local function prepare(order)
    local payload = order.payload or {}
    if payload.input and PNC.WorkInputService.IsReady(order) then return true end
    if PNC.ColonyStorageService.HasProductionTransactionStage(
        payload.storageId, order.id, "research_resource")
    then payload.resourceCommitted = true; return true end
    if payload.mode == "technology" or payload.resourceCommitted == true then
        return true
    end
    if payload.reservationId
        and PNC.ColonyStorageService.GetProductionReservation(payload.reservationId)
    then return true end
    local match = { fullType = payload.resourceFullType }
    if payload.mode == "blueprint" then match.recipeId = order.recipeId end
    local reservation, reason = PNC.ColonyStorageService.ReserveProductionMatchingRecord(
        payload.storageId, match, 1, "research:" .. order.id)
    if not reservation then return false, reason end
    payload.reservationId = reservation.id
    if payload.input then
        PNC.WorkInputService.ReplaceReservation(order, reservation)
    end
    PNC.WorkRepository.MarkDirty()
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.RESEARCH = cancellation
PNC.WorkService.RegisterPreparation("RESEARCH", prepare)
PNC.WorkService.RegisterCompletion("RESEARCH", completion)
PNC.WorkService.RegisterTargetProvider("RESEARCH", researchTarget)
PNC.WorkService.RegisterReconciler("research_duplicates",
    Service.Commands.ReconcileDuplicates)

Internal.Completion = completion
Internal.Cancellation = cancellation
Internal.Prepare = prepare

return Service
