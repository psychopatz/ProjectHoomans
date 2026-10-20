-- Read-only bridge from the existing Hoomans player dossier into the
-- portable Core actor Knowledge contract. Hoomans remains authoritative for
-- its ModData during the compatibility window; this module never writes it.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreKnowledge or {}
Persistence.CoreKnowledge = Adapter

local function coreKnowledge(core)
    local actors = core and core.Actors
    return actors and actors.Knowledge or nil
end

local function service()
    return PNC.NPCKnowledge
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

return Adapter
