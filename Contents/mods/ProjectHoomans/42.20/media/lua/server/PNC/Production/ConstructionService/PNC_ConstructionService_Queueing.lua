if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ConstructionService
local Internal = Service.Internal

local function activeOrder(id)
    local order = id and PNC.WorkRepository.Get(id) or nil
    if not order or order.status == "COMPLETED" or order.status == "CANCELLED" then
        return nil
    end
    return order
end

function Service.QueueBuild(player, facility, definition)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    if definition.bootstrapFromPlayer == true then
        local consumed, quote = PNC.FacilityCostService.ConsumePlayer(
            player, definition)
        if not consumed then
            return nil, quote and quote.reason or "MISSING_MATERIALS"
        end
        local payload = {
            mode = "build", facilityId = facility.id, materialKind = "bootstrap",
            requirements = {}, recipeRevision =
                Internal.RecipeRevisionFor(definition, facility, "build"),
            input = { consume = false, funded = true, committed = true,
                bootstrap = true },
        }
        local order
        order, reason = PNC.WorkService.Commands.Queue({ operation = "CONSTRUCT",
            colonyId = context.colony.id, factionId = context.faction.id,
            baseId = context.base.id,
            requiredWork = math.max(1, tonumber(definition.buildWork) or 100),
            requiredSkills = definition.buildSkills or {}, payload = payload,
            funded = true, recipeRevision = payload.recipeRevision })
        if not order then return nil, reason end
        facility.constructionState = "UNDER_CONSTRUCTION"
        facility.constructionWorkOrderId = order.id
        PNC.FacilityService.RefreshState(facility)
        return order
    end
    local requirements = Internal.BuildRequirements(definition)
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        context.storage.id, requirements, "construct:" .. facility.id)
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local payload = PNC.WorkInputService.Bind({
        mode = "build", facilityId = facility.id, storageId = context.storage.id,
        materialKind = "build", recipeRevision =
            Internal.RecipeRevisionFor(definition, facility, "build"),
    }, context.storage.id, reservation.id, "construction_materials")
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "CONSTRUCT",
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id,
        requiredWork = math.max(1, tonumber(definition.buildWork) or 100),
        requiredSkills = definition.buildSkills or {}, payload = payload,
        funded = false, recipeRevision = payload.recipeRevision })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return nil, reason
    end
    facility.constructionState = "UNDER_CONSTRUCTION"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end

function Service.QueueDeconstruct(player, facility)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    local constructionOrder = activeOrder(facility.constructionWorkOrderId)
    if constructionOrder then
        if constructionOrder.operation ~= "CONSTRUCT"
            and constructionOrder.operation ~= "RECONSTRUCT"
        then return nil, "FACILITY_WORK_IN_PROGRESS" end
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
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    if activeOrder(facility.constructionWorkOrderId) then
        return nil, "FACILITY_WORK_IN_PROGRESS"
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
        local revision = Internal.RecipeRevisionFor(
            definition, facility, change.action)
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
            materialCount = count, recipeRevision = revision,
        }, context.storage.id, reservation.id, "component_construction")
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
