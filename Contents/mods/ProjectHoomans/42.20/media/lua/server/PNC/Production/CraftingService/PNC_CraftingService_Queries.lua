if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}
PNC.CraftingServiceInternal = PNC.CraftingServiceInternal or {}

local Service = PNC.CraftingService
local H = PNC.CraftingServiceInternal
local Registry = PNC.RecipeKnowledgeRegistry

local function stationSnapshot(operation, recipe)
    local definitions = PNC.WorkDefinitions
    local source = definitions and definitions.GetStationForRecipe
        and definitions.GetStationForRecipe(recipe, operation) or nil
    source = source or definitions and definitions.GetStation
        and definitions.GetStation(operation) or nil
    source = source or {
        id = "workshop", facilityId = "workshop",
        capability = "work.craft", role = "work.craft",
        legacyRoles = { "work.disassemble" },
        labelKey = "UI_PNC_Workshop_CraftingStation",
    }
    local station = {}
    for key, value in pairs(source) do
        if key ~= "legacyRoles" then station[key] = value end
    end
    station.legacyRoles = {}
    for index, role in ipairs(source.legacyRoles or {}) do
        station.legacyRoles[index] = role
    end
    if definitions and definitions.GetProductionSkillId then
        station.productionSkillId = definitions.GetProductionSkillId(recipe,
            source)
    end
    return station
end

local function resolvedSnapshot(resolved, operation)
    local output = {}
    for key, value in pairs(resolved or {}) do output[key] = value end
    output.requiredStation = stationSnapshot(operation,
        resolved and resolved.descriptor)
    return output
end

function Service.Queries.KnownRecipes(colonyId, storageId)
    local state = PNC.ResearchRepository.Get(colonyId, false)
    local output, included = {}, {}
    local function addRecipe(recipeId)
        local resolved = Registry.Queries.Resolve(recipeId)
        if resolved and resolved.descriptor and storageId then
            resolved.availability = {}
            for inputIndex = 1, #resolved.descriptor.inputs do
                local input = resolved.descriptor.inputs[inputIndex]
                resolved.availability[inputIndex] =
                    PNC.ColonyStorageService.CountProductionAvailable(
                        storageId, input.itemTypes)
            end
        end
        if resolved and resolved.descriptor
            and not included[resolved.descriptor.key]
        then
            included[resolved.descriptor.key] = true
            output[#output + 1] = resolvedSnapshot(resolved, "CRAFT")
        end
    end
    for index = 1, #(state and state.learnedRecipeIds or {}) do
        addRecipe(state.learnedRecipeIds[index])
    end
    -- Literature recipes appear in the workshop catalog before colony-wide
    -- blueprint research. Worker assignment remains the per-NPC book gate.
    for _, descriptor in ipairs(PNC.RecipeCatalog.Queries.List() or {}) do
        if descriptor.needToBeLearn == true
            and not included[descriptor.key]
        then
            local recipeId = PNC.KnowledgeRepository.GetOrCreateId(
                descriptor.key)
            addRecipe(recipeId)
        end
    end
    return output
end

function Service.Queries.DisassemblyCandidates(storage)
    local output, grouped = {}, {}
    for recordIndex = 1, #(storage and storage.inventory
        and storage.inventory.records or {}) do
        local info = PNC.ColonyStorageService.ReadProductionRecord(
            storage.id, recordIndex)
        if info and info.fullType ~= "PNC.RecipeBlueprint"
            and info.fullType ~= "Base.Money"
        then
            local recipeId = info.metadata and info.metadata.PNC
                and info.metadata.PNC.production
                and tonumber(info.metadata.PNC.production.rid) or nil
            local resolved = recipeId and Registry.Queries.Resolve(recipeId) or nil
            if not resolved then
                local producers = PNC.RecipeCatalog.Queries.GetProducerKeys(
                    info.fullType)
                if #producers == 1 then
                    recipeId = Registry.Queries.GetId(producers[1])
                    resolved = recipeId and Registry.Queries.Resolve(recipeId)
                        or PNC.RecipeCatalog.Queries.Get(producers[1])
                            and { status = "AVAILABLE" } or nil
                end
            end
            if resolved and resolved.status == "AVAILABLE" then
                local candidate = grouped[info.fullType]
                if not candidate then
                    candidate = { fullType = info.fullType,
                        recordIndex = recordIndex, quantity = 0,
                        potentialYield = {},
                        descriptor = resolved.descriptor,
                        productionSkillId = resolved.descriptor
                            and resolved.descriptor.productionSkillId or nil,
                        requiredStation = stationSnapshot("DISASSEMBLE",
                            resolved.descriptor),
                    }
                    for inputIndex = 1, #(resolved.descriptor
                        and resolved.descriptor.inputs or {})
                    do
                        local input = resolved.descriptor.inputs[inputIndex]
                        if input.consumed and input.itemTypes
                            and input.itemTypes[1]
                        then
                            local maximum = math.ceil(
                                math.max(0, tonumber(input.amount) or 0) * 0.65)
                            if maximum > 0 then
                                candidate.potentialYield[
                                    #candidate.potentialYield + 1] = {
                                        fullType = input.itemTypes[1],
                                        maximum = maximum,
                                    }
                            end
                        end
                    end
                    grouped[info.fullType] = candidate
                    output[#output + 1] = candidate
                end
                candidate.quantity = candidate.quantity + math.max(1,
                    math.floor(tonumber(info.quantity) or 1))
            end
        end
    end
    table.sort(output, function(left, right)
        return left.fullType < right.fullType
    end)
    return output
end
function Service.Queries.BuildSnapshot(colonyId)
    local contextStorage = PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetForSettlement
        and PNC.ColonyStorageRepository.GetForSettlement(colonyId) or nil
    return { knownRecipes = Service.Queries.KnownRecipes(colonyId,
            contextStorage and contextStorage.id),
        disassemblyCandidates = Service.Queries.DisassemblyCandidates(
            contextStorage),
        orders = PNC.WorkService.Queries.List(colonyId),
        diagnostics = PNC.WorkService.Queries.Diagnostics(),
        inventoryDiagnostics = PNC.ColonyStorageService.GetProductionDiagnostics(
            contextStorage and contextStorage.id) }
end

return Service
