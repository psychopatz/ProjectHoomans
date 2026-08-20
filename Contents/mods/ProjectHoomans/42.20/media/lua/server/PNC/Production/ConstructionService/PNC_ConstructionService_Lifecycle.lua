if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ConstructionService
local Internal = Service.Internal

local function pointFromRegion(region)
    for z, spans in pairs(type(region) == "table" and region.levels or {}) do
        for _, span in ipairs(spans or {}) do
            local x1 = tonumber(span.x1 or span.x)
            local y = tonumber(span.y)
            if x1 and y then return { x = x1, y = y, z = tonumber(z) or 0 } end
        end
    end
    return nil
end

function Internal.ResolveTarget(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    local change = order.payload and order.payload.change or {}
    local component = change.action == "remove"
        and PNC.SettlementRepository.GetComponent(change.componentId)
        or change.component
    if change.action == "replace_role" then
        local anchor = change.anchors and change.anchors[1]
        component = anchor and { kind = "anchor", role = change.role,
            x = anchor.x, y = anchor.y, z = anchor.z } or nil
    end
    if component and component.kind == "anchor"
        and component.x ~= nil and component.y ~= nil
    then
        return { ok = true, componentId = component.id
                or "construction:" .. tostring(facility and facility.id),
            facilityId = facility and facility.id, target = {
                x = component.x, y = component.y, z = component.z,
                componentId = component.id, role = component.role,
            } }
    elseif component and component.kind == "region" and component.region then
        local point = pointFromRegion(component.region)
        if point then
            return { ok = true, componentId = component.id
                    or "construction:" .. tostring(facility and facility.id),
                facilityId = facility and facility.id,
                target = { x = point.x, y = point.y, z = point.z,
                    componentId = component.id, role = component.role } }
        end
    end
    local point, reason = PNC.FacilityService.ResolveWorkTarget(facility)
    if not point then return { ok = false, reason = reason } end
    return { ok = true, componentId = "construction:" .. facility.id,
        facilityId = facility.id, target = point }
end

function Internal.Prepare(order)
    if order.operation ~= "CONSTRUCT" and order.operation ~= "RECONSTRUCT" then
        return true
    end
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    local expectedState = order.operation == "CONSTRUCT"
        and "UNDER_CONSTRUCTION" or "RECONSTRUCTING"
    if facility and (facility.constructionState ~= expectedState
        or tostring(facility.constructionWorkOrderId or "") ~= order.id)
    then
        facility.constructionState = expectedState
        facility.constructionWorkOrderId = order.id
        PNC.FacilityService.RefreshState(facility)
    end
    local input = order.payload and order.payload.input or nil
    if order.funded == true or input and (input.funded == true
        or input.committed == true)
    then order.funded = true; return true end
    if input and PNC.WorkInputService.IsReady(order) then
        local funded, reason = PNC.WorkInputService.Fund(order, nil,
            "legacy_construction_funding")
        if funded then order.funded = true; return true end
        return false, reason
    end
    if order.progress > 0 or order.createdAt then
        order.funded = true
        order.payload = order.payload or {}
        order.payload.input = { consume = true, funded = true,
            committed = true, legacyRecovered = true }
        PNC.WorkRepository.MarkDirty()
        return true
    end
    return false, "CONSTRUCTION_NOT_FUNDED"
end

function Internal.ConstructionRequirements(order)
    local payload = order and order.payload or {}
    if type(payload.requirements) == "table" then
        return PNC.Core.DeepCopy(payload.requirements)
    end
    local facility = PNC.SettlementRepository.GetFacility(payload.facilityId)
    local definition = facility and PNC.FacilityDefinitions.Get(
        facility.definitionId) or nil
    local change = payload.change or {}
    local kind = payload.materialKind or (order.operation == "CONSTRUCT"
        and "build" or change.action)
    if not definition then return {} end
    local revision = tonumber(order.recipeRevision)
        or tonumber(payload.recipeRevision)
    if kind == "set" or kind == "replace_role" then
        return Internal.RequirementsFromCosts(Internal.ComponentCostsFor(
            facility, payload.materialRole or change.role
                or change.component and change.component.role, revision),
            payload.materialCount or (kind == "replace_role"
                and math.max(1, #(change.anchors or {})) or 1))
    end
    if kind == "upgrade" or kind == "reinforce" or kind == "build" then
        return Internal.RequirementsFromCosts(
            Internal.DefinitionCosts(definition, kind, revision), 1)
    end
    return {}
end

function Internal.CancellationRefund(order)
    if not order or (order.operation ~= "CONSTRUCT"
        and order.operation ~= "RECONSTRUCT")
    then return { percent = 0, products = {} } end
    local payload = order.payload or {}
    if order.operation == "RECONSTRUCT"
        and (payload.change and payload.change.action) == "remove"
    then return { percent = 0, products = {} } end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(order.progress) or 0))
    local remaining = math.max(0, (required - progress) / required)
    local multiplier = PNC.Sandbox
        and PNC.Sandbox.ConstructionCancellationRefundMultiplier
        and PNC.Sandbox.ConstructionCancellationRefundMultiplier() or 1
    local percent = math.max(0, math.min(100,
        math.floor(remaining * multiplier * 100 + 0.5)))
    local products = {}
    for _, cost in ipairs(Internal.ConstructionRequirements(order)) do
        local fullType = cost.fullType or cost.itemTypes and cost.itemTypes[1]
        local quantity = math.floor((tonumber(cost.amount) or 0)
            * remaining * multiplier + 0.000001)
        if fullType and quantity > 0 then
            products[#products + 1] = { fullType = fullType, quantity = quantity }
        end
    end
    return { percent = percent, products = products,
        recipeRevision = tonumber(order.recipeRevision)
            or tonumber(payload.recipeRevision) or 1 }
end

local function refundConstruction(order)
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

local function completeBuild(order)
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

local function completeDeconstruct(order)
    return PNC.FacilityService.FinalizeDestroy(
        order.payload and order.payload.facilityId)
end

local function completeReconstruct(order)
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
        return PNC.FacilityService.FinalizeUpgrade(
            payload.facilityId, change.targetLevel)
    end
    return PNC.FacilityService.FinalizeSetComponent(
        payload.facilityId, change.component)
end

local function resetFacility(order, state)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if facility then
        facility.constructionState = state
        facility.constructionWorkOrderId = nil
        PNC.FacilityService.RefreshState(facility)
    end
end

local function cancelBuild(order)
    local refunded, refundOrReason = refundConstruction(order)
    if not refunded then return false, refundOrReason end
    local released, releaseReason = PNC.WorkInputService.Cancel(order)
    if released == false then return false, releaseReason end
    resetFacility(order, "PLANNED")
    return true, refundOrReason
end

local function cancelDeconstruct(order)
    resetFacility(order, order.payload.previousConstructionState or "BUILT")
    return true
end

local function cancelReconstruct(order)
    local change = order.payload and order.payload.change or {}
    if change.action ~= "remove" then
        local refunded, refundOrReason = refundConstruction(order)
        if not refunded then return false, refundOrReason end
    end
    local released, releaseReason = PNC.WorkInputService.Cancel(order)
    if released == false then return false, releaseReason end
    resetFacility(order, "BUILT")
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.CONSTRUCT = cancelBuild
PNC.WorkService.CancellationHandlers.RECONSTRUCT = cancelReconstruct
PNC.WorkService.CancellationHandlers.DECONSTRUCT = cancelDeconstruct
PNC.WorkService.RegisterTargetProvider("CONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterTargetProvider("RECONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterTargetProvider("DECONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterPreparation("CONSTRUCT", Internal.Prepare)
PNC.WorkService.RegisterPreparation("RECONSTRUCT", Internal.Prepare)
PNC.WorkService.RegisterCompletion("CONSTRUCT", completeBuild)
PNC.WorkService.RegisterCompletion("RECONSTRUCT", completeReconstruct)
PNC.WorkService.RegisterCompletion("DECONSTRUCT", completeDeconstruct)

return Service
