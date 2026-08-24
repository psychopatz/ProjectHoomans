if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
local Service, Internal = PNC.ConstructionService, PNC.ConstructionService.Internal
function Internal.ActiveOrder(id)
    local order = id and PNC.WorkRepository.Get(id) or nil
    if not order or order.status == "COMPLETED" or order.status == "CANCELLED" then
        return nil
    end
    return order
end
function Internal.HasFacilityWork(facility)
    for _, existing in pairs(PNC.WorkRepository.State.byId or {}) do
        local existingFacilityId = existing.facilityId
            or existing.payload and existing.payload.facilityId
        if tostring(existingFacilityId or "") == tostring(facility.id)
            and existing.status ~= "COMPLETED" and existing.status ~= "CANCELLED"
        then return true end
    end
    return false
end
function Service.QueueDeconstruct(player, facility)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    local constructionOrder = Internal.ActiveOrder(facility.constructionWorkOrderId)
    if constructionOrder then
        if constructionOrder.operation ~= "CONSTRUCT"
            and constructionOrder.operation ~= "RECONSTRUCT"
        then return nil, "FACILITY_WORK_IN_PROGRESS" end
        local cancelled, cancelReason = PNC.WorkService.Commands.Cancel(
            constructionOrder.id, "replaced_by_deconstruction")
        if not cancelled then return nil, cancelReason end
    end
    if Internal.HasFacilityWork(facility) then return nil, "FACILITY_IN_USE" end
    local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
    local previousState = facility.constructionState or "BUILT"
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "DECONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(definition and definition.deconstructWork) or 60),
        requiredSkills = definition and definition.buildSkills or {},
        payload = { mode = "deconstruct", facilityId = facility.id,
            previousConstructionState = previousState } })
    if not order then return nil, reason end
    facility.constructionState = "DECONSTRUCTING"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end
return Service
