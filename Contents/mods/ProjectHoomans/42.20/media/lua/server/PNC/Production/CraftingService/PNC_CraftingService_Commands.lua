if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}
PNC.CraftingServiceInternal = PNC.CraftingServiceInternal or {}

local Service = PNC.CraftingService
local H = PNC.CraftingServiceInternal
local Registry = PNC.RecipeKnowledgeRegistry

function Service.Commands.QueueCraft(player, recipeId, quantity)
    local ctx, reason = H.Context(player)
    recipeId = math.floor(tonumber(recipeId) or 0)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if not ctx then return nil, reason end
    if not PNC.ResearchService.Queries.HasRecipe(ctx.colony.id, recipeId) then
        return nil, "RECIPE_UNKNOWN"
    end
    local resolved = Registry.Queries.Resolve(recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return nil, "RECIPE_UNAVAILABLE"
    end
    local requirements = {}
    for index = 1, #resolved.descriptor.inputs do
        local row = resolved.descriptor.inputs[index]
        if row.consumed == false then requirements[#requirements + 1] = row end
    end
    for copyIndex = 1, quantity do
        for index = 1, #resolved.descriptor.inputs do
            local row = resolved.descriptor.inputs[index]
            if row.consumed ~= false then requirements[#requirements + 1] = row end
        end
    end
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        ctx.storage.id, requirements, "craft:" .. tostring(recipeId))
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "CRAFT",
        colonyId = ctx.colony.id, factionId = ctx.faction.id, baseId = ctx.base.id,
        recipeId = recipeId, quantity = quantity,
        requiredWork = math.max(20, resolved.descriptor.craftTime * quantity),
        requiredSkills = resolved.descriptor.requiredSkills,
        payload = PNC.WorkInputService.Bind({ storageId = ctx.storage.id,
            reservationId = reservation.id, requirements = requirements },
            ctx.storage.id, reservation.id, "craft_inputs") })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

function Service.Commands.QueueDisassembly(player, recordIndex)
    local ctx, reason = H.Context(player)
    if not ctx then return nil, reason end
    local info
    info, reason = PNC.ColonyStorageService.ReadProductionRecord(
        ctx.storage.id, recordIndex)
    if not info then return nil, reason end
    local recipeId = info.metadata and info.metadata.PNC
        and info.metadata.PNC.production
        and tonumber(info.metadata.PNC.production.rid) or nil
    local resolved = recipeId and Registry.Queries.Resolve(recipeId) or nil
    if not resolved or resolved.status ~= "AVAILABLE" then
        local producers = PNC.RecipeCatalog.Queries.GetProducerKeys(info.fullType)
        if #producers == 0 then return nil, "DISASSEMBLY_UNSUPPORTED" end
        if #producers > 1 then return nil, "DISASSEMBLY_AMBIGUOUS" end
        recipeId = PNC.KnowledgeRepository.GetOrCreateId(producers[1])
        resolved = Registry.Queries.Resolve(recipeId)
    end
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionRecord(
        ctx.storage.id, recordIndex, 1, "disassemble:" .. tostring(recipeId))
    if not reservation then return nil, reason end
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "DISASSEMBLE",
        colonyId = ctx.colony.id, factionId = ctx.faction.id, baseId = ctx.base.id,
        recipeId = recipeId, requiredWork = math.max(20,
            resolved.descriptor.craftTime * 0.6),
        requiredSkills = resolved.descriptor.requiredSkills,
        payload = PNC.WorkInputService.Bind({ storageId = ctx.storage.id,
            reservationId = reservation.id, specimenFullType = info.fullType },
            ctx.storage.id, reservation.id, "disassembly_specimen") })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

