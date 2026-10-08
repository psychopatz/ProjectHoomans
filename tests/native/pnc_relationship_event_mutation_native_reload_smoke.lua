-- Target-owned native relationship restart fixture, phase two.
-- Exercise one social-event relationship mutation after JVM restart.

local NPC_ID = "npc_pzharness_relationship_event_mutation_restart"
local TARGET_ID = "npc_pzharness_relationship_event_mutation_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local SOURCE_KEY = "npc:" .. NPC_ID
local EVENT_ID = "event:pzharness:relationship-event-mutation"
local MEMORY_ID = "memory:pzharness:relationship-event-mutation"

local function buildMutation()
    return {
        eventID = EVENT_ID,
        interactionType = "greeting",
        worldAgeHours = 930,
        familiarityDelta = 6,
        moraleDelta = 5,
        memory = {
            id = MEMORY_ID,
            type = "native_harness_event_memory",
            aboutKey = TARGET_KEY,
            createdAt = 930,
            lastEvaluatedAt = 930,
            approvalEffect = 42,
            respectEffect = 24,
            moraleEffect = 0,
            strength = 1,
            decayPerDay = 0,
            permanent = true,
            shareable = true,
            knowledgeSource = "experienced",
            sourceKey = SOURCE_KEY,
            tags = {
                native_harness = true,
                event_mutation = true,
            },
        },
        interaction = {
            kind = "native_harness_event",
            source = "native_harness",
            interactionType = "greeting",
            eventID = EVENT_ID,
            memoryID = MEMORY_ID,
            at = 930,
            worldAgeHours = 930,
            applied = true,
        },
    }
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after event-mutation restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.ApplyEventMutation,
        "native event-mutation API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Event Mutation NPC"
            and record.identitySeed == 7070
            and record.social and record.social.relationships,
        "native event-mutation NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.approval == 42
            and relationship.respect == 24
            and relationship.familiarity == 6
            and relationship.state == "friend"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 930
            and relationship.lastEvaluatedAt == 930
            and relationship.cooldowns.greeting == 960
            and relationship.saturation.greeting.approval == 4
            and relationship.saturation.greeting.respect == 2
            and #relationship.memories == 1
            and memory and memory.id == MEMORY_ID
            and memory.aboutKey == TARGET_KEY
            and memory.sourceKey == SOURCE_KEY
            and memory.permanent == true
            and memory.tags.native_harness == true
            and memory.tags.event_mutation == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.memoryID == MEMORY_ID
            and interaction.interactionType == "greeting"
            and interaction.worldAgeHours == 930
            and interaction.applied == true,
        "native event mutation did not survive restart"
    )
    PZHarness.assertTrue(
        record.social.morale == 5
            and record.social.recentEventIDs
            and #record.social.recentEventIDs == 1
            and record.social.recentEventIDs[1] == EVENT_ID,
        "native event-mutation social state did not survive restart"
    )

    local duplicate, duplicateReason = relationships.ApplyEventMutation(
        NPC_ID,
        TARGET_KEY,
        buildMutation()
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_event",
        "native event-mutation duplicate rejection did not survive restart"
    )
    PZHarness.assertTrue(
        (tonumber(record.recordRevision) or 0) >= 1,
        "native event-mutation NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native event-mutation persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    local rawInteraction = rawRelationship
        and rawRelationship.interactionJournal
        and rawRelationship.interactionJournal[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and raw.social and raw.social.morale == 5
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 1
            and raw.social.recentEventIDs[1] == EVENT_ID
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 6
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 930
            and rawRelationship.lastEvaluatedAt == 930
            and rawRelationship.cooldowns.greeting == 960
            and rawRelationship.saturation.greeting.approval == 4
            and rawRelationship.saturation.greeting.respect == 2
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.sourceKey == SOURCE_KEY
            and rawMemory.permanent == true
            and rawMemory.tags.native_harness == true
            and rawMemory.tags.event_mutation == true
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.memoryID == MEMORY_ID
            and rawInteraction.interactionType == "greeting"
            and rawInteraction.applied == true,
        "native event-mutation ModData was not reloaded"
    )
end
