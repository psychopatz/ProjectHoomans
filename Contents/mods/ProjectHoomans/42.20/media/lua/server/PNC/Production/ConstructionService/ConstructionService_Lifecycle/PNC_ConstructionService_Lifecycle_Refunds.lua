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
    -- Player-funded (bootstrap) builds were paid out of a survivor's own
    -- inventory. Return those materials to that survivor; the stockpile below
    -- is only a fallback for a player who cannot be resolved right now.
    local routing = payload.refund or {}
    local Costs = PNC.FacilityCostService
    if routing.toPlayer == true and Costs and Costs.RefundPlayer then
        local player = Costs.ResolvePlayer and Costs.ResolvePlayer(routing) or nil
        if player then
            local paid, payReason = Costs.RefundPlayer(player, refund.products)
            if paid then return true, refund end
            if PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn("player construction refund failed reason="
                    .. tostring(payReason))
            end
        end
    end
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

