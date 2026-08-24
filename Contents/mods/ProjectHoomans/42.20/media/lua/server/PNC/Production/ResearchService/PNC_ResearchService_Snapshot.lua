-- Research catalog and candidate snapshot query.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Repository = PNC.ResearchRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

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
    local books = {}
    local groupedBooks = {}
    for recordIndex = 1, #(storage and storage.inventory
        and storage.inventory.records or {}) do
        local info = PNC.ColonyStorageService.ReadProductionRecord(
            storage.id, recordIndex)
        if info then
            local nativeBook
            if CoreInventory.decodeItem then
                local ok, decoded = pcall(CoreInventory.decodeItem, info.record)
                nativeBook = ok and decoded or nil
            end
            local book = PNC.RecipeKnowledge
                and PNC.RecipeKnowledge.Queries
                and PNC.RecipeKnowledge.Queries.BookDetails
                and PNC.RecipeKnowledge.Queries.BookDetails(
                    nativeBook, info.fullType)
                or { relevant = false }
            if book.relevant then
                local bookKey = tostring(info.fullType or "")
                local bookCandidate = groupedBooks[bookKey]
                if not bookCandidate then
                    bookCandidate = { mode = "book", recipeId = 0,
                        bookFullType = info.fullType,
                        displayName = info.fullType, fullType = info.fullType,
                        recordIndex = recordIndex, quantity = 0, known = false }
                    groupedBooks[bookKey] = bookCandidate
                    books[#books + 1] = bookCandidate
                    candidates[#candidates + 1] = bookCandidate
                end
                bookCandidate.quantity = bookCandidate.quantity
                    + math.max(1, math.floor(tonumber(info.quantity) or 1))
            end
            local mode, recipeId, descriptor
            if info.fullType == "PNC.RecipeBlueprint" then
                local blueprint = info.metadata and info.metadata.PNC
                    and info.metadata.PNC.blueprint or nil
                recipeId = math.floor(tonumber(blueprint and blueprint.rid) or 0)
                local resolved = recipeId > 0 and Registry.Queries.Resolve(recipeId)
                    or nil
                descriptor = resolved and resolved.descriptor or nil
                mode = descriptor and "blueprint" or nil
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
        books = books,
        learnedRecipeIds = PNC.Core.DeepCopy(state.learnedRecipeIds),
        learnedTechnologyIds = PNC.Core.DeepCopy(state.learnedTechnologyIds),
        knowledgeRevision = state.knowledgeRevision,
        orders = PNC.WorkService.Queries.List(colonyId) }
end

return Service
