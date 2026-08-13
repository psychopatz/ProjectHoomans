if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}

local Service = PNC.ConstructionService

local function contextFor(player, facility)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    if not facility or tostring(context.base.id) ~= tostring(facility.baseId) then
        return nil, "FACILITY_FORBIDDEN"
    end
    return context
end

local function requirementsFor(definition)
    local output = {}
    for _, cost in ipairs(definition and (definition.buildCosts
        or definition.buildCost) or {}) do
        output[#output + 1] = {
            itemTypes = { tostring(cost.fullType or "") },
            amount = math.max(1, math.floor(tonumber(
                cost.amount or cost.quantity) or 1)),
            consumed = true,
        }
    end
    return output
end

function Service.QueueBuild(player, facility, definition)
    local context, reason = contextFor(player, facility)
    if not context then return nil, reason end
    local requirements = requirementsFor(definition)
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        context.storage.id, requirements, "construct:" .. facility.id)
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local payload = PNC.WorkInputService.Bind({
        mode = "build", facilityId = facility.id,
        requirements = requirements,
    }, context.storage.id, reservation.id, "construction_materials")
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "CONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(definition.buildWork) or 100),
        requiredSkills = definition.buildSkills or {}, payload = payload })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return nil, reason
    end
    facility.constructionState = "UNDER_CONSTRUCTION"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end

local function activeOrder(id)
    local order = id and PNC.WorkRepository.Get(id) or nil
    if not order or order.status == "COMPLETED" or order.status == "CANCELLED" then
        return nil
    end
    return order
end

function Service.QueueDeconstruct(player, facility)
    local context, reason = contextFor(player, facility)
    if not context then return nil, reason end
    local constructionOrder = activeOrder(facility.constructionWorkOrderId)
    if constructionOrder then
        if constructionOrder.operation ~= "CONSTRUCT"
            and constructionOrder.operation ~= "RECONSTRUCT"
        then
            return nil, "FACILITY_WORK_IN_PROGRESS"
        end
        local cancelled, cancelReason = PNC.WorkService.Commands.Cancel(
            constructionOrder.id, "replaced_by_deconstruction")
        if not cancelled then return nil, cancelReason end
    end
    for _, existing in pairs(PNC.WorkRepository.State.byId or {}) do
        local existingFacilityId = existing.facilityId
            or existing.payload and existing.payload.facilityId
        if tostring(existingFacilityId or "") == tostring(facility.id)
            and existing.status ~= "COMPLETED"
            and existing.status ~= "CANCELLED"
        then return nil, "FACILITY_IN_USE" end
    end
    local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
    local previousState = facility.constructionState or "BUILT"
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "DECONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(definition and
            definition.deconstructWork) or 60),
        requiredSkills = definition and definition.buildSkills or {},
        payload = { mode = "deconstruct", facilityId = facility.id,
            previousConstructionState = previousState } })
    if not order then return nil, reason end
    facility.constructionState = "DECONSTRUCTING"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end

function Service.QueueReconstruct(player, facility, change)
    local context, reason = contextFor(player, facility)
    if not context then return nil, reason end
    if activeOrder(facility.constructionWorkOrderId) then
        return nil, "FACILITY_WORK_IN_PROGRESS"
    end
    for _, existing in pairs(PNC.WorkRepository.State.byId or {}) do
        if tostring(existing.facilityId or "") == tostring(facility.id)
            and existing.status ~= "COMPLETED"
            and existing.status ~= "CANCELLED"
        then return nil, "FACILITY_IN_USE" end
    end
    local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "RECONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(definition and
            definition.reconstructWork) or 60),
        requiredSkills = definition and definition.buildSkills or {},
        payload = { mode = "reconstruct", facilityId = facility.id,
            change = PNC.Core.DeepCopy(change or {}) } })
    if not order then return nil, reason end
    facility.constructionState = "RECONSTRUCTING"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end

local function target(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    local point, reason = PNC.FacilityService.ResolveWorkTarget(facility)
    if not point then return { ok = false, reason = reason } end
    return { ok = true, componentId = "construction:" .. facility.id,
        facilityId = facility.id, target = point }
end

local function prepare(order)
    if order.operation ~= "CONSTRUCT" then return true end
    if PNC.WorkInputService.IsReady(order) then return true end
    local payload = order.payload or {}
    local input = payload.input or {}
    local reservation, reason =
        PNC.ColonyStorageService.ReserveProductionMaterials(
            input.storageId, payload.requirements,
            "construct:" .. tostring(payload.facilityId))
    if not reservation then return false, reason end
    PNC.WorkInputService.ReplaceReservation(order, reservation)
    return true
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
    local facilityId = order.payload and order.payload.facilityId
    return PNC.FacilityService.FinalizeDestroy(facilityId)
end

local function completeReconstruct(order)
    local payload = order.payload or {}
    local change = payload.change or {}
    if change.action == "remove" then
        return PNC.FacilityService.FinalizeRemoveComponent(
            payload.facilityId, change.componentId)
    end
    return PNC.FacilityService.FinalizeSetComponent(
        payload.facilityId, change.component)
end

local function cancelBuild(order)
    PNC.WorkInputService.Cancel(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if facility then
        facility.constructionState = "PLANNED"
        facility.constructionWorkOrderId = nil
        PNC.FacilityService.RefreshState(facility)
    end
end

local function cancelDeconstruct(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if facility then
        facility.constructionState = order.payload.previousConstructionState
            or "BUILT"
        facility.constructionWorkOrderId = nil
        PNC.FacilityService.RefreshState(facility)
    end
end


local function cancelReconstruct(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if facility then
        facility.constructionState = "BUILT"
        facility.constructionWorkOrderId = nil
        PNC.FacilityService.RefreshState(facility)
    end
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.CONSTRUCT = cancelBuild
PNC.WorkService.CancellationHandlers.RECONSTRUCT = cancelReconstruct
PNC.WorkService.CancellationHandlers.DECONSTRUCT = cancelDeconstruct
PNC.WorkService.RegisterTargetProvider("CONSTRUCT", target)
PNC.WorkService.RegisterTargetProvider("RECONSTRUCT", target)
PNC.WorkService.RegisterTargetProvider("DECONSTRUCT", target)
PNC.WorkService.RegisterPreparation("CONSTRUCT", prepare)
PNC.WorkService.RegisterCompletion("CONSTRUCT", completeBuild)
PNC.WorkService.RegisterCompletion("RECONSTRUCT", completeReconstruct)
PNC.WorkService.RegisterCompletion("DECONSTRUCT", completeDeconstruct)

return Service
