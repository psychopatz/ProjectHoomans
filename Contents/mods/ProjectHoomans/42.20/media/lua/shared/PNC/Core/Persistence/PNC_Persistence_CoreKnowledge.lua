-- Read-only bridge from the existing Hoomans player dossier into the
-- portable Core actor Knowledge contract. Hoomans remains authoritative for
-- its ModData during the compatibility window; this module never writes it.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreKnowledge or {}
Persistence.CoreKnowledge = Adapter

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function coreKnowledge(core)
    local actors = core and core.Actors
    return actors and actors.Knowledge or nil
end

local function service()
    return PNC.NPCKnowledge
end

local function dossierCategory(output, descriptor)
    local categoryID = descriptor and descriptor.category or "misc"
    local category = output.categoriesByID[categoryID]
    if not category then
        category = { id = categoryID, descriptors = {} }
        output.categoriesByID[categoryID] = category
        output.categories[#output.categories + 1] = category
    end
    return category
end

local function emptyState(knowledge)
    return knowledge.NewState({})
end

local function playerState(knowledge, characterUUID, note)
    local facts = {}
    for descriptorID, discovered in pairs(note and note.discovered or {}) do
        local evidence = {}
        for _, entry in ipairs(note.evidence or {}) do
            if entry.descriptorID == descriptorID then
                evidence[#evidence + 1] = {
                    id = entry.id,
                    sourceType = entry.sourceType,
                    direction = entry.direction,
                    strength = entry.strength,
                    reliability = entry.reliability,
                    createdAt = entry.createdAt,
                    sourceEventID = entry.sourceEventID,
                    sourceEntityKey = entry.sourceEntityKey,
                    payload = entry.payload,
                    tags = entry.tags,
                }
            end
        end
        facts[descriptorID] = {
            id = descriptorID,
            status = discovered.status,
            value = discovered.value,
            confidence = discovered.confidence,
            firstDiscoveredAt = discovered.discoveredAt,
            lastUpdatedAt = discovered.lastUpdatedAt,
            primarySource = discovered.primarySource,
            evidence = evidence,
            revision = discovered.revision,
        }
    end
    return {
        playerKey = "player:" .. tostring(characterUUID),
        revision = note and note.revision or 0,
        facts = facts,
    }
end

local function build(core, characterUUID, npcID)
    local knowledge = coreKnowledge(core)
    local serviceValue = service()
    if not knowledge or type(knowledge.NewState) ~= "function"
        or type(serviceValue) ~= "table"
        or type(serviceValue.Get) ~= "function"
    then return nil, "core_knowledge_bridge_unavailable" end
    if type(characterUUID) ~= "string" or characterUUID == ""
        or type(npcID) ~= "string" or npcID == ""
    then return nil, "knowledge_identity_required" end
    if type(serviceValue.EnsureLoaded) == "function" then
        serviceValue.EnsureLoaded()
    end
    local note = serviceValue.Get(characterUUID, npcID)
    local state, reason = emptyState(knowledge)
    if not state then return nil, reason end
    if note then
        state.revision = tonumber(note.revision) or 0
        state.byPlayer["player:" .. characterUUID] = playerState(
            knowledge, characterUUID, note)
    end
    local normalized
    normalized, reason = knowledge.NewState(state)
    if not normalized then return nil, reason end
    local valid
    valid, reason = knowledge.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

function Adapter.BuildForPlayer(core, characterUUID, npcID)
    return build(core, characterUUID, npcID)
end

function Adapter.BuildForNPC(core, npcID)
    local knowledge = coreKnowledge(core)
    local serviceValue = service()
    if not knowledge or type(serviceValue) ~= "table"
        or type(serviceValue.Registry) ~= "table"
    then return nil, "core_knowledge_bridge_unavailable" end
    if type(serviceValue.EnsureLoaded) == "function" then
        serviceValue.EnsureLoaded()
    end
    local output, reason = emptyState(knowledge)
    if not output then return nil, reason end
    for characterUUID in pairs(serviceValue.Registry.byCharacter or {}) do
        local state
        state, reason = build(core, tostring(characterUUID), tostring(npcID))
        if not state then return nil, reason end
        local player = state.byPlayer["player:" .. tostring(characterUUID)]
        if player then
            output.byPlayer[player.playerKey] = player
        end
    end
    output.revision = tonumber(serviceValue.Registry.revision) or 0
    local normalized
    normalized, reason = knowledge.NewState(output)
    if not normalized then return nil, reason end
    local valid
    valid, reason = knowledge.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

-- The import is explicit and server-authorized. It is used at a provider
-- handoff or save migration boundary; ordinary dossier reads remain served
-- by Hoomans' existing player-scoped ModData service.
function Adapter.CommitForPlayer(
    core, registry, actorID, characterUUID, npcID, authority, expectedRevision
)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(registry) ~= "table"
        or type(registry.Get) ~= "function"
        or type(registry.Commit) ~= "function"
    then return nil, "core_registry_unavailable" end
    local actor = registry:Get(actorID)
    if not actor then return nil, "actor_not_found" end
    local state, reason = Adapter.BuildForPlayer(core, characterUUID, npcID)
    if not state then return nil, reason end
    return registry:Commit(actorID, { knowledge = state }, expectedRevision)
end

-- Project a Core actor's already-authorized Knowledge into the existing
-- Hoomans dossier snapshot shape. This is a read-only presentation adapter;
-- the Hoomans Knowledge service remains the writer for its ModData schema.
function Adapter.BuildDossierSnapshot(core, actor, characterUUID)
    local knowledge = coreKnowledge(core)
    if not knowledge or type(knowledge.GetPlayer) ~= "function"
        or type(actor) ~= "table"
    then return nil, "core_knowledge_bridge_unavailable" end
    local player, reason = knowledge.GetPlayer(actor.knowledge, characterUUID)
    if not player and reason == "player_knowledge_not_found" then
        player = { playerKey = "player:" .. tostring(characterUUID), facts = {} }
    elseif not player then
        return nil, reason
    end
    local output = {
        schemaVersion = 1,
        npcID = tostring(actor.actorId or ""),
        categories = {},
        categoriesByID = {},
        revision = tonumber(player.revision) or 0,
        firstMetAt = nil,
        lastInteractionAt = nil,
        giftPreferences = {},
        identity = {},
    }
    for factID, fact in pairs(player.facts or {}) do
        local descriptor = PNC.KnowledgeDescriptors
            and type(PNC.KnowledgeDescriptors.Get) == "function"
            and PNC.KnowledgeDescriptors.Get(factID) or nil
        local category = dossierCategory(output, descriptor)
        category.descriptors[#category.descriptors + 1] = {
            descriptorID = factID,
            category = descriptor and descriptor.category or "misc",
            valueType = descriptor and descriptor.valueType or "text_enum",
            presentation = descriptor and copy(descriptor.presentation) or {},
            status = fact.status,
            value = copy(fact.value),
            confidence = fact.confidence,
            primarySource = fact.primarySource,
            evidenceCount = #(fact.evidence or {}),
        }
        if factID == "identity.name"
            and (fact.status == "known" or fact.status == "confirmed")
        then
            output.identity.displayName = fact.value
        end
    end
    for _, category in ipairs(output.categories) do
        table.sort(category.descriptors, function(left, right)
            return left.descriptorID < right.descriptorID
        end)
    end
    table.sort(output.categories, function(left, right)
        return left.id < right.id
    end)
    output.categoriesByID = nil
    return output
end

return Adapter
