-- Research catalog and candidate snapshot query.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Repository = PNC.ResearchRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions

function Service.Queries.BuildSnapshot(colonyId)
    local state = Repository.Get(colonyId)
    if not state then return { entries = {}, learnedRecipeIds = {} } end
    local entries = {}
    for _, id in ipairs(Definitions.ORDER) do
        local definition = Definitions.Get(id)
        if definition then
            entries[#entries + 1] = { id = id, category = definition.category,
                labelKey = definition.labelKey,
                known = Service.Queries.HasTechnology(colonyId, id),
                prerequisiteTechnology = definition.prerequisiteTechnology,
                prerequisiteKnown = not definition.prerequisiteTechnology
                    or Service.Queries.HasTechnology(colonyId,
                        definition.prerequisiteTechnology),
                researchCapability = definition.researchCapability,
                requiredWork = definition.requiredWork,
                requiredSkills = definition.requiredSkills }
        end
    end
    local candidates = {}
    local storage = PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetForSettlement
        and PNC.ColonyStorageRepository.GetForSettlement(colonyId) or nil
    local grouped = {}
    for recordIndex = 1, #(storage and storage.inventory
        and storage.inventory.records or {}) do
        local info = PNC.ColonyStorageService.ReadProductionRecord(
            storage.id, recordIndex)
        if info then
            local mode, recipeId, descriptor
            if info.fullType == "PNC.RecipeBlueprint" then
                local blueprint = info.metadata and info.metadata.PNC
                    and info.metadata.PNC.blueprint or nil
                recipeId = math.floor(tonumber(blueprint and blueprint.rid) or 0)
                local resolved = recipeId > 0 and Registry.Queries.Resolve(recipeId)
                    or nil
                descriptor = resolved and resolved.descriptor or nil
                mode = descriptor and "blueprint" or nil
            else
                local producers = PNC.RecipeCatalog.Queries.GetProducerKeys(
                    info.fullType)
                if #producers == 1 then
                    descriptor = PNC.RecipeCatalog.Queries.Get(producers[1])
                    recipeId = descriptor
                        and Registry.Queries.GetId(descriptor.key) or 0
                    mode = descriptor and "reverse" or nil
                end
            end
            if mode then
                local key = mode .. ":" .. tostring(descriptor.key) .. ":"
                    .. tostring(info.fullType)
                local candidate = grouped[key]
                if not candidate then
                    candidate = { mode = mode, recipeId = recipeId,
                        recipeKey = descriptor.key,
                        displayName = tostring(descriptor.displayName
                            or descriptor.key), fullType = info.fullType,
                        recordIndex = recordIndex, quantity = 0,
                        known = recipeId > 0
                            and Service.Queries.HasRecipe(colonyId, recipeId)
                            or false }
                    grouped[key] = candidate
                    candidates[#candidates + 1] = candidate
                end
                candidate.quantity = candidate.quantity
                    + math.max(1, math.floor(tonumber(info.quantity) or 1))
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.mode ~= right.mode then return left.mode < right.mode end
        return left.displayName < right.displayName
    end)
    return { entries = entries,
        candidates = candidates,
        learnedRecipeIds = PNC.Core.DeepCopy(state.learnedRecipeIds),
        learnedTechnologyIds = PNC.Core.DeepCopy(state.learnedTechnologyIds),
        knowledgeRevision = state.knowledgeRevision,
        orders = PNC.WorkService.Queries.List(colonyId) }
end

return Service
