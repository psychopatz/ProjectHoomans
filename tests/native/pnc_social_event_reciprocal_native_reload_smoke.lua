-- Target-owned native social-event restart fixture, phase two.
-- Exercise reciprocal relationship and conduct state after JVM restart.

local ACTOR_ID = "npc_pzharness_social_event_reciprocal_actor"
local TARGET_ID = "npc_pzharness_social_event_reciprocal_target"
local ACTOR_KEY = "npc:" .. ACTOR_ID
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "social:pzharness:social-event-reciprocal"
local EVENT_TYPE = "survived_combat_together"
local OCCURRED_AT = 1080
local ACTOR_MEMORY_ID = "memory:" .. EVENT_ID .. ":"
    .. ACTOR_ID .. ":actor"
local TARGET_MEMORY_ID = "memory:" .. EVENT_ID .. ":"
    .. TARGET_ID .. ":target"
local ACTOR_EVIDENCE_ID = "conduct:" .. EVENT_ID .. ":"
    .. ACTOR_KEY .. ":participant"
local TARGET_EVIDENCE_ID = "conduct:" .. EVENT_ID .. ":"
    .. TARGET_KEY .. ":participant"

local function buildEvent()
    return {
        id = EVENT_ID,
        type = EVENT_TYPE,
        actorKey = ACTOR_KEY,
        targetKey = TARGET_KEY,
        occurredAt = OCCURRED_AT,
        sourceSystem = "combat",
        context = {
            nativeHarness = true,
        },
    }
end

local function assertRelationship(
    relationship,
    observerID,
    memoryID,
    message
)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == observerID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == 3
            and relationship.respect == 6
            and relationship.familiarity == 4
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == OCCURRED_AT
            and relationship.lastEvaluatedAt == OCCURRED_AT
            and relationship.saturation[EVENT_TYPE].approval == 3
            and relationship.saturation[EVENT_TYPE].respect == 6
            and #relationship.memories == 1
            and memory and memory.id == memoryID
            and memory.type == EVENT_TYPE
            and memory.createdAt == OCCURRED_AT
            and memory.lastEvaluatedAt == OCCURRED_AT
            and memory.approvalEffect == 3
            and memory.respectEffect == 6
            and memory.moraleEffect == 3
            and memory.strength == 1
            and memory.decayPerDay == 0.035
            and memory.permanent == false
            and memory.shareable == false
            and memory.knowledgeSource == "experienced"
            and memory.tags.combat == true
            and memory.tags.shared_danger == true
            and memory.tags.teamwork == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.kind == EVENT_TYPE
            and interaction.source == "combat"
            and interaction.interactionType == EVENT_TYPE
            and interaction.memoryID == nil
            and interaction.at == OCCURRED_AT
            and interaction.worldAgeHours == OCCURRED_AT
            and interaction.applied == true,
        message
    )
end

local function assertConduct(
    conduct,
    entityKey,
    subjectKey,
    evidenceID,
    message
)
    local evidence = conduct and conduct.evidence
        and conduct.evidence[1]
    PZHarness.assertTrue(
        conduct
            and conduct.schemaVersion == 1
            and conduct.revision == 1
            and conduct.scores.reliability == 2
            and conduct.scores.courage == 2
            and conduct.scores.groupLoyalty == 1
            and #conduct.evidence == 1
            and #conduct.recentEvidenceIDs == 1
            and conduct.recentEvidenceIDs[1] == evidenceID
            and evidence and evidence.id == evidenceID
            and evidence.eventID == EVENT_ID
            and evidence.eventType == EVENT_TYPE
            and evidence.actorKey == entityKey
            and evidence.subjectKey == subjectKey
            and evidence.createdAt == OCCURRED_AT
            and evidence.lastEvaluatedAt == OCCURRED_AT
            and evidence.effects.reliability == 2
            and evidence.effects.courage == 2
            and evidence.effects.groupLoyalty == 1
            and evidence.strength == 1
            and evidence.decayPerDay == 0.015
            and evidence.permanent == false
            and evidence.visibility == "direct"
            and evidence.shareable == false
            and evidence.tags.combat == true
            and evidence.tags.teamwork == true
            and evidence.tags.shared_danger == true,
        message
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    local socialEvents = PNC and PNC.SocialEvents or nil
    local conduct = PNC and PNC.Conduct or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after reciprocal restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native reciprocal relationship API was not available after restart"
    )
    PZHarness.assertTrue(
        socialEvents and socialEvents.GetDefinition
            and socialEvents.Process,
        "native reciprocal social-event API was not available after restart"
    )
    PZHarness.assertTrue(
        conduct and conduct.GetForNPC,
        "native conduct query API was not available after restart"
    )
    local definition = socialEvents.GetDefinition(EVENT_TYPE)
    PZHarness.assertTrue(
        definition and definition.id == EVENT_TYPE
            and definition.reciprocalNPCObservers == true
            and definition.targetMemory
            and definition.targetMemory.type == EVENT_TYPE
            and PNC.ConductDefinitions[EVENT_TYPE].participants
                == "actor_and_target",
        "native reciprocal definition did not survive restart"
    )

    local actor = registry.Get(ACTOR_ID)
    local target = registry.Get(TARGET_ID)
    PZHarness.assertTrue(
        type(actor) == "table"
            and actor.id == ACTOR_ID
            and actor.name == "PZ Harness Reciprocal Social Event Actor"
            and actor.identitySeed == 8383
            and type(target) == "table"
            and target.id == TARGET_ID
            and target.name == "PZ Harness Reciprocal Social Event Target"
            and target.identitySeed == 8484
            and actor.social and actor.social.relationships
            and target.social and target.social.relationships,
        "native reciprocal social-event NPC records were not reloaded"
    )

    assertRelationship(
        relationships.Get(TARGET_ID, ACTOR_KEY),
        ACTOR_ID,
        TARGET_MEMORY_ID,
        "native reciprocal target relationship did not survive restart"
    )
    assertRelationship(
        relationships.Get(ACTOR_ID, TARGET_KEY),
        TARGET_ID,
        ACTOR_MEMORY_ID,
        "native reciprocal actor relationship did not survive restart"
    )
    assertConduct(
        conduct.GetForNPC(ACTOR_ID),
        ACTOR_KEY,
        TARGET_KEY,
        ACTOR_EVIDENCE_ID,
        "native reciprocal actor conduct did not survive restart"
    )
    assertConduct(
        conduct.GetForNPC(TARGET_ID),
        TARGET_KEY,
        ACTOR_KEY,
        TARGET_EVIDENCE_ID,
        "native reciprocal target conduct did not survive restart"
    )
    PZHarness.assertTrue(
        actor.social.recentEventIDs
            and #actor.social.recentEventIDs == 1
            and actor.social.recentEventIDs[1] == EVENT_ID
            and target.social.recentEventIDs
            and #target.social.recentEventIDs == 1
            and target.social.recentEventIDs[1] == EVENT_ID,
        "native reciprocal social-event recent IDs did not survive restart"
    )

    local duplicateOK, duplicate = pcall(
        socialEvents.Process,
        buildEvent()
    )
    PZHarness.assertTrue(
        duplicateOK and duplicate and duplicate.ok == false
            and duplicate.reason == "duplicate_event"
            and duplicate.memoriesCreated == 0
            and duplicate.relationshipsChanged == 0,
        "native reciprocal duplicate rejection did not survive restart"
    )
    PZHarness.assertEqual(
        actor.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native reciprocal actor persistence schema did not survive restart"
    )
    PZHarness.assertEqual(
        target.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native reciprocal target persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local actorPointer = directory and directory.records
        and directory.records[ACTOR_ID]
    local targetPointer = directory and directory.records
        and directory.records[TARGET_ID]
    local actorRaw = actorPointer and ModData.get(actorPointer.storageKey)
        or nil
    local targetRaw = targetPointer and ModData.get(targetPointer.storageKey)
        or nil
    local actorRawEvidence = actorRaw and actorRaw.social
        and actorRaw.social.conduct and actorRaw.social.conduct.evidence[1]
    local targetRawEvidence = targetRaw and targetRaw.social
        and targetRaw.social.conduct and targetRaw.social.conduct.evidence[1]
    PZHarness.assertTrue(
        type(actorPointer) == "table"
            and actorPointer.recordRevision == 1
            and type(targetPointer) == "table"
            and targetPointer.recordRevision == 1
            and type(actorRaw) == "table"
            and actorRaw.recordRevision == 1
            and type(targetRaw) == "table"
            and targetRaw.recordRevision == 1
            and actorRaw.social and actorRaw.social.conduct
            and actorRaw.social.conduct.revision == 1
            and actorRaw.social.conduct.scores.reliability == 2
            and actorRawEvidence and actorRawEvidence.id == ACTOR_EVIDENCE_ID
            and targetRaw.social and targetRaw.social.conduct
            and targetRaw.social.conduct.revision == 1
            and targetRaw.social.conduct.scores.reliability == 2
            and targetRawEvidence
            and targetRawEvidence.id == TARGET_EVIDENCE_ID,
        "native reciprocal social-event ModData was not reloaded"
    )
end
