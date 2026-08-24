if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
local Service, Internal = PNC.ConstructionService, PNC.ConstructionService.Internal
function Service.QueueBuild(player, facility, definition)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    if definition.bootstrapFromPlayer == true then
        local consumed, quote = PNC.FacilityCostService.ConsumePlayer(player, definition)
        if not consumed then return nil, quote and quote.reason or "MISSING_MATERIALS" end
        local payload = { mode = "build", facilityId = facility.id,
            materialKind = "bootstrap", requirements = {},
            recipeRevision = Internal.RecipeRevisionFor(definition, facility, "build"),
            input = { consume = false, funded = true, committed = true,
                bootstrap = true } }
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
    local payload = PNC.WorkInputService.Bind({ mode = "build",
        facilityId = facility.id, storageId = context.storage.id,
        materialKind = "build", recipeRevision =
            Internal.RecipeRevisionFor(definition, facility, "build") },
        context.storage.id, reservation.id, "construction_materials")
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
return Service
