if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal =
    PNC.ConstructionService.Internal or {}

local Service = PNC.ConstructionService
local Internal = Service.Internal
Internal.LifecycleInternal = Internal.LifecycleInternal or {}
local H = Internal.LifecycleInternal

function H.RefundConstruction(order)
    local refund = Internal.CancellationRefund(order)
    if #refund.products == 0 then return true, refund end
    local payload = order.payload or {}
    local input = payload.input or {}
    local storageId = payload.storageId or input.storageId
    if (not storageId or tostring(storageId) == "")
        and PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetForSettlement
    then
        local storage = PNC.ColonyStorageRepository.GetForSettlement(
            order.colonyId)
        storageId = storage and storage.id or nil
    end
    if not storageId or tostring(storageId) == "" then
        return false, "CONSTRUCTION_REFUND_STORAGE_MISSING"
    end
    local ok, reason = PNC.ColonyStorageService.DepositProductionItems(
        storageId, refund.products, nil, order.id,
        "construction_cancellation_refund")
    if not ok then return false, reason end
    return true, refund
end

Service.Queries = Service.Queries or {}
function Service.Queries.GetCancellationRefund(orderOrId)
    local order = type(orderOrId) == "table" and orderOrId
        or PNC.WorkRepository.Get(orderOrId)
    return PNC.Core.DeepCopy(Internal.CancellationRefund(order))
end

return Service

