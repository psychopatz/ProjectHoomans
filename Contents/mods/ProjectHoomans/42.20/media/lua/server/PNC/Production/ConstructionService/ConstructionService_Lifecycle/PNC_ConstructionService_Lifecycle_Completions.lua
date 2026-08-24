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

function H.CompleteBuild(order)
    local ok, reason = PNC.WorkInputService.Commit(order,
        "construction_material_consumption")
    if not ok then return false, reason end
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if not facility then return false, "FACILITY_NOT_FOUND" end
    facility.constructionState = "BUILT"
    facility.constructionWorkOrderId = nil
    PNC.FacilityService.RefreshState(facility)
    return true
end

function H.CompleteDeconstruct(order)
    return PNC.FacilityService.FinalizeDestroy(
        order.payload and order.payload.facilityId)
end

function H.CompleteReconstruct(order)
    local payload = order.payload or {}
    local change = payload.change or {}
    if change.action ~= "remove" then
        local ok, reason = PNC.WorkInputService.Commit(order,
            "component_construction_material_consumption")
        if not ok then return false, reason end
    end
    if change.action == "remove" then
        local ok, reason = PNC.FacilityService.FinalizeRemoveComponent(
            payload.facilityId, change.componentId)
        if not ok then return false, reason end
        local products = {}
        for _, cost in ipairs(payload.refundRequirements or {}) do
            local quantity = math.floor((tonumber(cost.amount) or 0)
                * (tonumber(payload.refundPercent) or 0) / 100 + 0.5)
            if quantity > 0 then products[#products + 1] = {
                fullType = cost.fullType, quantity = quantity } end
        end
        if #products > 0 then
            local refunded, refundReason =
                PNC.ColonyStorageService.DepositProductionItems(
                    payload.storageId, products, nil, order.id,
                    "component_deconstruction_refund")
            if not refunded then return false, refundReason end
        end
        return true, "ComponentRemoved"
    end
    if change.action == "replace_role" then
        return PNC.FacilityService.FinalizeReplaceAnchorRole(
            payload.facilityId, change.role, change.anchors)
    end
    if change.action == "upgrade" then
        local facility = PNC.SettlementRepository.GetFacility(payload.facilityId)
        local ok, reason = PNC.FacilityService.FinalizeUpgrade(
            payload.facilityId, change.targetLevel)
        if not ok then return false, reason end
        if facility and facility.definitionId == "stockpile"
            and PNC.ColonyStorageService.SetTierForSettlement
        then
            local upgraded, storageReason =
                PNC.ColonyStorageService.SetTierForSettlement(
                    order.colonyId, change.targetLevel)
            if not upgraded then return false, storageReason end
        end
        return true, reason
    end
    return PNC.FacilityService.FinalizeSetComponent(
        payload.facilityId, change.component)
end

return Service

