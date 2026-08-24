if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
local Service, Internal = PNC.ConstructionService, PNC.ConstructionService.Internal
function Service.QueueReconstruct(player, facility, change)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    if Internal.ActiveOrder(facility.constructionWorkOrderId) then
        return nil, "FACILITY_WORK_IN_PROGRESS"
    end
    if Internal.HasFacilityWork(facility) then return nil, "FACILITY_IN_USE" end
    local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
    change = PNC.Core.DeepCopy(change or {})
    local payload = { mode = "reconstruct", facilityId = facility.id,
        storageId = context.storage.id, change = change }
    if change.action == "remove" then
        local existing = PNC.SettlementRepository.GetComponent
            and PNC.SettlementRepository.GetComponent(change.componentId)
        payload.refundRequirements = PNC.Core.DeepCopy(existing
            and Internal.ComponentCostsFor(facility, existing.role, nil) or {})
        payload.refundPercent = PNC.Sandbox
            and PNC.Sandbox.ComponentDeconstructionRefundPercent
            and PNC.Sandbox.ComponentDeconstructionRefundPercent() or 50
    end
    local reservation
    if change.action == "set" or change.action == "replace_role"
        or change.action == "upgrade" or change.action == "reinforce"
    then
        local component, count = change.component, 1
        if change.action == "replace_role" then
            count = math.max(1, #(change.anchors or {}))
            component = { role = change.role }
        end
        local revision = Internal.RecipeRevisionFor(definition, facility, change.action)
        local requirements
        if change.action == "upgrade" or change.action == "reinforce" then
            requirements = Internal.RequirementsFromCosts(
                Internal.DefinitionCosts(definition, change.action, revision), 1)
        else
            requirements = Internal.RequirementsFromCosts(
                Internal.ComponentCostsFor(facility,
                    component and component.role, revision), count)
        end
        reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
            context.storage.id, requirements, "component:" .. facility.id)
        if not reservation then return nil, reason or "MISSING_MATERIALS" end
        payload = PNC.WorkInputService.Bind({ mode = "reconstruct",
            facilityId = facility.id, change = change,
            storageId = context.storage.id, materialKind = change.action,
            materialRole = component and component.role or change.role,
            materialCount = count, recipeRevision = revision },
            context.storage.id, reservation.id, "component_construction")
    end
    local requiredWork = definition and definition.reconstructWork or 60
    if change.action == "set" then
        requiredWork = Internal.ComponentBuildWork(facility,
            change.component and change.component.role)
    elseif change.action == "replace_role" then
        requiredWork = Internal.ComponentBuildWork(facility, change.role)
            * math.max(1, #(change.anchors or {}))
    end
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "RECONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(requiredWork) or 60),
        requiredSkills = definition and definition.buildSkills or {},
        payload = payload, funded = false,
        recipeRevision = payload.recipeRevision })
    if not order then
        if reservation then
            PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        end
        return nil, reason
    end
    facility.constructionState = "RECONSTRUCTING"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end
return Service
