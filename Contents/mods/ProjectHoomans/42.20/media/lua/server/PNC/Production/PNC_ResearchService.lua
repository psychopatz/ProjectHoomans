if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
require "PNC/Production/PNC_WorkInputService"
local Service = PNC.ResearchService
local Repository = PNC.ResearchRepository
local RegistryRepository = PNC.KnowledgeRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Definitions = PNC.ColonyResearchDefinitions

Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}

local function emit(eventType, payload)
    if eventType and EventsBus and EventsBus.emit then
        EventsBus.emit(eventType, payload)
    end
end

local function broadcast(colonyId, factionId, delta)
    delta.colonyId, delta.factionId = tostring(colonyId), tostring(factionId or "")
    if not PNC.Network or not PNC.Network.SendColonyKnowledgeDelta then return end
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        for index = 0, players:size() - 1 do
            local player = players:get(index)
            local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
                and PNC.Factions.GetPlayerFaction(player) or nil
            if faction and tostring(faction.id) == delta.factionId then
                PNC.Network.SendColonyKnowledgeDelta(player, delta)
            end
        end
    elseif getSpecificPlayer then
        local player = getSpecificPlayer(0)
        if player then PNC.Network.SendColonyKnowledgeDelta(player, delta) end
    end
end

local function runtime(colonyId)
    Repository.Get(colonyId)
    return Repository.Runtime[tostring(colonyId or "")]
end

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

local function queue(context, spec)
    spec.colonyId, spec.factionId, spec.baseId = context.colony.id,
        context.faction.id, context.base.id
    return PNC.WorkService.Commands.Queue(spec)
end

function Service.Commands.QueueTechnology(player, technologyId)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local definition = Definitions.Get(technologyId)
    if not context then return nil, reason end
    if not definition or technologyId == "storage_capacity" then
        return nil, "TECHNOLOGY_UNKNOWN"
    end
    if Service.Queries.HasTechnology(context.colony.id, technologyId) then
        return nil, "ALREADY_KNOWN"
    end
    return queue(context, { operation = "RESEARCH",
        requiredWork = definition.requiredWork,
        requiredSkills = definition.requiredSkills,
        payload = { mode = "technology", technologyId = technologyId } })
end

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

function Service.Commands.ReverseEngineer(player, recordIndex)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    local info
    info, reason = PNC.ColonyStorageService.ReadProductionRecord(
        context.storage.id, recordIndex)
    if not info then return nil, reason end
    local producers = PNC.RecipeCatalog.Queries.GetProducerKeys(info.fullType)
    if #producers == 0 then return nil, "REVERSE_ENGINEER_UNSUPPORTED" end
    if #producers > 1 then return nil, "REVERSE_ENGINEER_AMBIGUOUS" end
    local descriptor = PNC.RecipeCatalog.Queries.Get(producers[1])
    local recipeId = RegistryRepository.GetOrCreateId(descriptor.key)
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionRecord(
        context.storage.id, recordIndex, 1, "research:specimen")
    if not reservation then return nil, reason end
    local order
    order, reason = queue(context, { operation = "RESEARCH", recipeId = recipeId,
        requiredWork = math.max(30, descriptor.craftTime
            * Definitions.POLICY.reverseEngineeringWorkMultiplier),
        requiredSkills = descriptor.requiredSkills,
        payload = PNC.WorkInputService.Bind({ mode = "reverse",
            storageId = context.storage.id, reservationId = reservation.id,
            resourceFullType = info.fullType }, context.storage.id,
            reservation.id, "research_resource") })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

local function completion(order)
    local payload = order.payload or {}
    if payload.mode == "technology" then
        return Service.Commands.UnlockTechnology(order.colonyId,
            payload.technologyId, order.factionId)
    end
    if payload.mode ~= "blueprint" and payload.mode ~= "reverse" then
        return false, "RESEARCH_MODE_UNKNOWN"
    end
    if payload.resourceCommitted ~= true then
        local consume = payload.mode == "reverse"
            or Definitions.POLICY.consumeBlueprintOnCompletion == true
        local ok, reason
        if consume and payload.input then
            ok, reason = PNC.WorkInputService.Commit(order,
                "research_resource_consumption")
        elseif consume then
            ok, reason = PNC.ColonyStorageService.CommitProductionReservation(
                payload.reservationId, order.id, "research_resource",
                payload.storageId)
        else
            ok, reason = PNC.ColonyStorageService.ReleaseProductionReservation(
                payload.reservationId)
        end
        if not ok then return false, reason end
        payload.resourceCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    return Service.Commands.UnlockRecipe(order.colonyId, order.recipeId,
        order.factionId)
end

local function cancellation(order)
    local payload = order.payload or {}
    if payload.input then
        PNC.WorkInputService.Cancel(order)
    elseif payload.reservationId and payload.resourceCommitted ~= true then
        PNC.ColonyStorageService.ReleaseProductionReservation(payload.reservationId)
    end
end

local function prepare(order)
    local payload = order.payload or {}
    if payload.input and PNC.WorkInputService.IsReady(order) then return true end
    if PNC.ColonyStorageService.HasProductionTransactionStage(
        payload.storageId, order.id, "research_resource")
    then payload.resourceCommitted = true; return true end
    if payload.mode == "technology" or payload.resourceCommitted == true then
        return true
    end
    if payload.reservationId
        and PNC.ColonyStorageService.GetProductionReservation(payload.reservationId)
    then return true end
    local match = { fullType = payload.resourceFullType }
    if payload.mode == "blueprint" then match.recipeId = order.recipeId end
    local reservation, reason = PNC.ColonyStorageService.ReserveProductionMatchingRecord(
        payload.storageId, match, 1, "research:" .. order.id)
    if not reservation then return false, reason end
    payload.reservationId = reservation.id
    if payload.input then
        PNC.WorkInputService.ReplaceReservation(order, reservation)
    end
    PNC.WorkRepository.MarkDirty()
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.RESEARCH = cancellation
PNC.WorkService.RegisterPreparation("RESEARCH", prepare)
PNC.WorkService.RegisterCompletion("RESEARCH", completion)

function Service.Queries.BuildSnapshot(colonyId)
    local state = Repository.Get(colonyId)
    if not state then return { entries = {}, learnedRecipeIds = {} } end
    local entries = {}
    for _, id in ipairs(Definitions.ORDER) do
        local definition = Definitions.Get(id)
        if definition and id ~= "storage_capacity" then
            entries[#entries + 1] = { id = id, category = definition.category,
                labelKey = definition.labelKey,
                known = Service.Queries.HasTechnology(colonyId, id),
                requiredWork = definition.requiredWork,
                requiredSkills = definition.requiredSkills }
        end
    end
    return { entries = entries,
        learnedRecipeIds = PNC.Core.DeepCopy(state.learnedRecipeIds),
        learnedTechnologyIds = PNC.Core.DeepCopy(state.learnedTechnologyIds),
        knowledgeRevision = state.knowledgeRevision,
        orders = PNC.WorkService.Queries.List(colonyId) }
end

return Service
