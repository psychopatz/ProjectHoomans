-- Learned recipe and technology queries and mutations.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Internal = Service.Internal
local Repository = PNC.ResearchRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions
local EventTypes = PNC.EventTypes or {}
local emit = Internal.Emit
local broadcast = Internal.Broadcast
local runtime = Internal.Runtime

function Service.Queries.HasRecipe(colonyId, recipeId)
    local value = runtime(colonyId)
    return value and value.learnedRecipeSet[math.floor(tonumber(recipeId) or 0)] == true
end
function Service.Queries.HasTechnology(colonyId, technologyId)
    local value = runtime(colonyId)
    return value and value.learnedTechnologySet[tostring(technologyId or "")] == true
end

function Service.Commands.UnlockRecipe(colonyId, recipeId, factionId)
    recipeId = math.floor(tonumber(recipeId) or 0)
    local state = Repository.Get(colonyId)
    local index = runtime(colonyId)
    if not state or recipeId <= 0 or not Registry.Queries.GetKey(recipeId) then
        return false, "RECIPE_ID_UNKNOWN"
    end
    if index.learnedRecipeSet[recipeId] then return true, "ALREADY_KNOWN" end
    state.learnedRecipeIds[#state.learnedRecipeIds + 1] = recipeId
    table.sort(state.learnedRecipeIds)
    index.learnedRecipeSet[recipeId] = true
    state.knowledgeRevision = state.knowledgeRevision + 1
    Repository.MarkDirty()
    local resolved = Registry.Queries.Resolve(recipeId)
    emit(EventTypes.RECIPE_KNOWLEDGE_UNLOCKED, { colonyId = state.colonyId,
        recipeId = recipeId, revision = state.knowledgeRevision })
    broadcast(state.colonyId, factionId, { recipeId = recipeId,
        recipe = resolved, revision = state.knowledgeRevision })
    return true, "KNOWLEDGE_UNLOCKED", state.knowledgeRevision
end

function Service.Commands.UnlockTechnology(colonyId, technologyId, factionId)
    technologyId = tostring(technologyId or "")
    local state = Repository.Get(colonyId)
    local index = runtime(colonyId)
    if not state or not Definitions.Get(technologyId) then
        return false, "TECHNOLOGY_UNKNOWN"
    end
    if index.learnedTechnologySet[technologyId] then return true, "ALREADY_KNOWN" end
    state.learnedTechnologyIds[#state.learnedTechnologyIds + 1] = technologyId
    table.sort(state.learnedTechnologyIds)
    index.learnedTechnologySet[technologyId] = true
    state.knowledgeRevision = state.knowledgeRevision + 1
    Repository.MarkDirty()
    emit(EventTypes.TECHNOLOGY_UNLOCKED, { colonyId = state.colonyId,
        technologyId = technologyId, revision = state.knowledgeRevision })
    broadcast(state.colonyId, factionId, { technologyId = technologyId,
        revision = state.knowledgeRevision })
    return true, "TECHNOLOGY_UNLOCKED", state.knowledgeRevision
end

return Service
