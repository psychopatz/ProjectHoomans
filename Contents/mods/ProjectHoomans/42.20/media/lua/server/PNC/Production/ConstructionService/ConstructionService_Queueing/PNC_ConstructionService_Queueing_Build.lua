if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
local Service, Internal = PNC.ConstructionService, PNC.ConstructionService.Internal
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"
function Service.QueueBuild(player, facility, definition)
    local context, reason = Internal.ContextFor(player, facility)
    if not context then return nil, reason end
    if definition.bootstrapFromPlayer == true then
        -- The player pays from their own inventory here, so the removal is
        -- committed before the work order exists. Keep the receipts until the
        -- order is durably queued: a rejected queue must return the materials.
        local consumed, quote = PNC.FacilityCostService.ConsumePlayer(
            player, definition, { keepReceipts = true })
        if not consumed then
            if BuildAudit.Enabled() then
                BuildAudit.Log("bootstrap_consume_failed", {
                    "definition=" .. tostring(definition.id),
                    "reason=" .. tostring(quote and quote.reason),
                })
            end
            return nil, quote and quote.reason or "MISSING_MATERIALS"
        end
        if BuildAudit.Enabled() then
            BuildAudit.Log("bootstrap_consumed", {
                "definition=" .. tostring(definition.id),
                "facility=" .. tostring(facility.id),
            })
        end
        local payload = { mode = "build", facilityId = facility.id,
            materialKind = "bootstrap",
            recipeRevision = Internal.RecipeRevisionFor(definition, facility, "build"),
            input = { consume = false, funded = true, committed = true,
                bootstrap = true },
            refund = { toPlayer = true,
                onlineID = player and player.getOnlineID
                    and tonumber(player:getOnlineID()) or nil,
                username = player and player.getUsername
                    and player:getUsername() or nil } }
        local order
        order, reason = PNC.WorkService.Commands.Queue({ operation = "CONSTRUCT",
            colonyId = context.colony.id, factionId = context.faction.id,
            baseId = context.base.id,
            requiredWork = math.max(1, tonumber(definition.buildWork) or 100),
            requiredSkills = definition.buildSkills or {}, payload = payload,
            funded = true, recipeRevision = payload.recipeRevision })
        if not order then
            local restored = PNC.FacilityCostService.Rollback(quote)
            if BuildAudit.Enabled() then
                BuildAudit.Log("bootstrap_rolled_back", {
                    "definition=" .. tostring(definition.id),
                    "reason=" .. tostring(reason),
                    "restored=" .. tostring(restored == true),
                })
            end
            if restored ~= true and PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn("bootstrap build refund failed reason="
                    .. tostring(reason))
            end
            return nil, reason or "BUILD_QUEUE_FAILED"
        end
        if BuildAudit.Enabled() then
            BuildAudit.Log("bootstrap_queued", {
                "definition=" .. tostring(definition.id),
                "order=" .. tostring(order.id),
                "facility=" .. tostring(facility.id),
            })
        end
        facility.constructionState = "UNDER_CONSTRUCTION"
        facility.constructionWorkOrderId = order.id
        PNC.FacilityService.RefreshState(facility)
        return order
    end
    local requirements = Internal.BuildRequirements(definition)
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        context.storage.id, requirements, "construct:" .. facility.id)
    if not reservation then
        if BuildAudit.Enabled() then
            BuildAudit.Log("reservation_failed", {
                "definition=" .. tostring(definition.id),
                "storage=" .. tostring(context.storage.id),
                "reason=" .. tostring(reason),
            })
        end
        return nil, reason or "MISSING_MATERIALS"
    end
    if BuildAudit.Enabled() then
        BuildAudit.Log("reservation_ok", {
            "definition=" .. tostring(definition.id),
            "storage=" .. tostring(context.storage.id),
            "reservation=" .. tostring(reservation.id),
        })
    end
    local payload = PNC.WorkInputService.Bind({ mode = "build",
        facilityId = facility.id, storageId = context.storage.id,
        materialKind = "build", recipeRevision =
            Internal.RecipeRevisionFor(definition, facility, "build"),
        activityItemFullType = Internal.ActivityItemFullType(
            requirements, reservation) },
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
        if BuildAudit.Enabled() then
            BuildAudit.Log("reservation_released", {
                "definition=" .. tostring(definition.id),
                "reservation=" .. tostring(reservation.id),
                "reason=" .. tostring(reason),
            })
        end
        return nil, reason
    end
    if BuildAudit.Enabled() then
        BuildAudit.Log("construction_queued", {
            "definition=" .. tostring(definition.id),
            "facility=" .. tostring(facility.id),
            "order=" .. tostring(order.id),
            "reservation=" .. tostring(reservation.id),
        })
    end
    facility.constructionState = "UNDER_CONSTRUCTION"
    facility.constructionWorkOrderId = order.id
    PNC.FacilityService.RefreshState(facility)
    return order
end
return Service
