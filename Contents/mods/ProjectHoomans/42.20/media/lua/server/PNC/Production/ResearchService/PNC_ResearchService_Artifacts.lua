-- Blueprint research artifacts. Literature is handled by RecipeBookService.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Internal = Service.Internal
local RegistryRepository = PNC.KnowledgeRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions
local queue = Internal.Queue

function Service.Commands.CreateBlueprint(player, recipeKey)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local descriptor = PNC.RecipeCatalog.Queries.Get(recipeKey)
    if not descriptor and tostring(recipeKey or "") == "" then
        descriptor = PNC.RecipeCatalog.Queries.List()[1]
    end
    if not context then return false, reason end
    if not descriptor then return false, "RECIPE_UNAVAILABLE" end
    local recipeId = RegistryRepository.GetOrCreateId(descriptor.key)
    local ok, result = PNC.ColonyStorageService.DepositProductionItems(
        context.storage.id, {{ fullType = "PNC.RecipeBlueprint", quantity = 1,
            modData = { PNC = { blueprint = { v = 1, rid = recipeId } } } }})
    return ok, ok and recipeId or result
end

function Service.Commands.CreateSpearTestKit(player)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return false, reason end
    local descriptor
    for _, candidate in ipairs(PNC.RecipeCatalog.Queries.List() or {}) do
        for _, output in ipairs(candidate.outputs or {}) do
            for _, fullType in ipairs(output.itemTypes or {}) do
                if fullType == "Base.SpearCrafted" then
                    descriptor = candidate
                    break
                end
            end
            if descriptor then break end
        end
        if descriptor then break end
    end
    if not descriptor then return false, "SPEAR_RECIPE_UNAVAILABLE" end
    local recipeId = RegistryRepository.GetOrCreateId(descriptor.key)
    local products = {}
    for _, input in ipairs(descriptor.inputs or {}) do
        if input.consumed ~= false and input.itemTypes and input.itemTypes[1] then
            products[#products + 1] = { fullType = input.itemTypes[1],
                quantity = math.max(1, math.floor(tonumber(input.amount) or 1)) * 4 }
        elseif input.consumed == false and input.itemTypes and input.itemTypes[1] then
            products[#products + 1] = { fullType = input.itemTypes[1], quantity = 1 }
        end
    end
    products[#products + 1] = { fullType = "PNC.RecipeBlueprint", quantity = 1,
        modData = { PNC = { blueprint = { v = 1, rid = recipeId } } } }
    products[#products + 1] = { fullType = "Base.SpearCrafted", quantity = 1 }
    products[#products + 1] = { fullType = "Base.SpearCrafted", quantity = 1,
        modData = { PNC = { production = { v = 1, rid = recipeId } } } }
    local ok, deposit = PNC.ColonyStorageService.DepositProductionItems(
        context.storage.id, products)
    if not ok then return false, deposit end
    Service.Commands.UnlockRecipe(context.colony.id, recipeId, context.faction.id)
    Service.Commands.UnlockTechnology(context.colony.id,
        "facility:workshop", context.faction.id)
    return true, { recipeId = recipeId, recipeKey = descriptor.key,
        itemCount = #products }
end

function Service.Commands.StudyBlueprint(player, recordIndex)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    local info
    info, reason = PNC.ColonyStorageService.ReadProductionRecord(
        context.storage.id, recordIndex)
    local blueprint = info and info.metadata and info.metadata.PNC
        and info.metadata.PNC.blueprint or nil
    local recipeId = blueprint and math.floor(tonumber(blueprint.rid) or 0) or 0
    local resolved = Registry.Queries.Resolve(recipeId)
    if not info or info.fullType ~= "PNC.RecipeBlueprint" or recipeId <= 0 then
        return nil, "INVALID_BLUEPRINT"
    end
    if not resolved or resolved.status ~= "AVAILABLE" then
        return nil, "RECIPE_UNAVAILABLE"
    end
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionRecord(
        context.storage.id, recordIndex, 1, "research:blueprint")
    if not reservation then return nil, reason end
    local order
    order, reason = queue(context, { operation = "RESEARCH", recipeId = recipeId,
        requiredWork = math.max(20, resolved.descriptor.craftTime
            * Definitions.POLICY.blueprintWorkMultiplier),
        requiredSkills = resolved.descriptor.requiredSkills,
        payload = { mode = "blueprint", storageId = context.storage.id,
            reservationId = reservation.id,
            resourceFullType = "PNC.RecipeBlueprint" } })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

return Service
