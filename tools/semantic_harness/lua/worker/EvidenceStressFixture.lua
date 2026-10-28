-- Developer-only bounded pressure and query measurements on detached owners.
local Fixture = {}
local ContextProjection = require "worker/Conversation_Context"
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"

function Fixture.Run(context, payload)
    payload = type(payload) == "table" and payload or {}
    local Runtime = context.Runtime
    local record = Runtime.hydratedNpcRecord
    if not record then return nil, "hydrated_fixture_required" end
    record = PNC.Registry.Get(record.id) or record
    local target = Runtime.relationshipTargetKey
    local at = getGameTime():getWorldAgeHours()
    local Events = PNC.Conversation.Memory.Events
    local count = math.max(0, math.min(256, math.floor(tonumber(payload.count) or 0)))
    local first = math.max(0, math.floor(tonumber(payload.start) or 0))
    if payload.seedMeaningful then
        Events.RecordRelationshipMemory(record, { type = "saved_from_incapacitation",
            aboutKey = target, permanent = true }, target)
    end
    for index = first + 1, first + count do
        PNC.Relationships.AddMemory(record.id, target, {
            id = "pressure:memory:" .. tostring(index), type = "player_spoke_insult",
            aboutKey = target, createdAt = at, strength = 0.5, decayPerDay = 0,
            approvalEffect = -1,
        })
        PNC.Conduct.AddEvidence(target, { id = "conduct:pressure:" .. tostring(index),
            eventID = "social:pressure:" .. tostring(index), eventType = "player_dialogue_insult",
            actorKey = target, subjectKey = "npc:" .. record.id, createdAt = at,
            strength = 0.5, decayPerDay = 0, effects = { compassion = -1 }, visibility = "direct" })
        record = PNC.Registry.Get(record.id) or record
        local other = "player:pressure:char_" .. tostring(index)
        Events.RecordRelationshipMemory(record, { type = "player_greeted",
            aboutKey = other, permanent = true }, other)
        Events.RecordConversationTopics(record, 1, "pressure_" .. tostring(index))
    end
    if payload.repeatPair then
        Events.RecordRelationshipMemory(record, { type = "player_greeted",
            aboutKey = "player:pressure:char_1", permanent = true }, "player:pressure:char_1")
    end
    local scene = ContextProjection.buildContext(context)
    local iterations = math.max(1, math.min(1000, math.floor(tonumber(payload.queryIterations) or 1)))
    local evidence
    for _ = 1, iterations do evidence = Providers.QueryEvidence(scene, { relation = "repair" }) end
    local parsed = PNC.EntityRef.Parse(target)
    local playerRecord = PNC.PlayerCharacters.GetRegistryRecord(parsed.characterUUID)
    local relationship = PNC.Relationships.Get(record.id, target) or {}
    local conduct = PNC.Conduct.GetForEntity(target) or {}
    local roots = {}
    for key in pairs(Runtime.modData or {}) do roots[#roots + 1] = key end
    table.sort(roots)
    return { ok = true, serializedRecord = context.Values.copy(PNC.Persistence.SerializeRecord(record)),
        playerRecord = context.Values.copy(playerRecord), memory = context.Values.copy(record.memory),
        counts = { relationship = #(relationship.memories or {}), conduct = #(conduct.evidence or {}),
            journal = #(relationship.interactionJournal or {}),
            today = #(record.memory and record.memory.s or {}) / 3,
            durable = #(record.memory and record.memory.l or {}) / 4,
            topicPlayers = #(record.memory and record.memory.t or {}) / 2 },
        evidence = evidence, queryIterations = iterations, roots = roots,
        limits = { topicPlayers = Events.TOPIC_PLAYER_LIMIT, topicMask = Events.TOPIC_MASK_LIMIT } }
end
return Fixture
