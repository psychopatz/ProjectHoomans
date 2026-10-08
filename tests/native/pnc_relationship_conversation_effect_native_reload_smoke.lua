-- Target-owned native relationship restart fixture, phase two.
-- Exercise one conversation effect after JVM restart.

local NPC_ID = "npc_pzharness_relationship_conversation_effect_restart"
local TARGET_ID = "npc_pzharness_relationship_conversation_effect_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID =
    "conversation:pzharness_block:pzharness_choice:pzharness_outcome:940000"

local function buildEffect()
    return {
        memoryType = "native_harness_conversation_memory",
        interactionType = "conversation_choice",
        approval = 36,
        respect = 18,
        familiarity = 6,
        morale = 4,
        decayPerDay = 0,
        permanent = true,
        shareable = true,
        tags = {
            native_harness = true,
        },
    }
end

local function buildContext()
    return {
        blockID = "pzharness_block",
        categoryID = "pzharness_category",
        nodeID = "pzharness_node",
        choiceID = "pzharness_choice",
        outcomeID = "pzharness_outcome",
        worldAgeHours = 940,
        cooldownType = "conversation",
        cooldownUntil = 975,
        sourceSystem = "native_harness",
        interactionKind = "choice",
    }
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after conversation-effect restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.ApplyConversationEffect,
        "native conversation-effect API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Conversation Effect NPC"
            and record.identitySeed == 7171
            and record.social and record.social.relationships,
        "native conversation-effect NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.approval == 36
            and relationship.respect == 18
            and relationship.familiarity == 6
            and relationship.state == "friend"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 940
            and relationship.lastEvaluatedAt == 940
            and relationship.cooldowns.conversation == 975
            and #relationship.memories == 1
            and memory and memory.id == EVENT_ID
            and memory.type == "native_harness_conversation_memory"
            and memory.aboutKey == TARGET_KEY
            and memory.createdAt == 940
            and memory.lastEvaluatedAt == 940
            and memory.approvalEffect == 36
            and memory.respectEffect == 18
            and memory.permanent == true
            and memory.shareable == true
            and memory.sourceKey == TARGET_KEY
            and memory.tags.native_harness == true
            and memory.tags.conversation == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.kind == "choice"
            and interaction.source == "native_harness"
            and interaction.interactionType == "conversation_choice"
            and interaction.blockID == "pzharness_block"
            and interaction.categoryID == "pzharness_category"
            and interaction.nodeID == "pzharness_node"
            and interaction.choiceID == "pzharness_choice"
            and interaction.outcomeID == "pzharness_outcome"
            and interaction.worldAgeHours == 940
            and interaction.applied == true,
        "native conversation effect did not survive restart"
    )
    PZHarness.assertTrue(
        record.social.morale == 4
            and record.social.recentEventIDs
            and #record.social.recentEventIDs == 1
            and record.social.recentEventIDs[1] == EVENT_ID,
        "native conversation-effect social state did not survive restart"
    )

    local duplicate, duplicateReason =
        relationships.ApplyConversationEffect(
            NPC_ID,
            TARGET_KEY,
            buildEffect(),
            buildContext()
        )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_event",
        "native conversation-effect duplicate rejection did not survive restart"
    )
    PZHarness.assertTrue(
        (tonumber(record.recordRevision) or 0) >= 1,
        "native conversation-effect NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native conversation-effect persistence schema did not survive restart"
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
            and raw.social and raw.social.morale == 4
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 1
            and raw.social.recentEventIDs[1] == EVENT_ID
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 36
            and rawRelationship.respect == 18
            and rawRelationship.familiarity == 6
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 940
            and rawRelationship.lastEvaluatedAt == 940
            and rawRelationship.cooldowns.conversation == 975
            and type(rawMemory) == "table"
            and rawMemory.id == EVENT_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.sourceKey == TARGET_KEY
            and rawMemory.permanent == true
            and rawMemory.tags.native_harness == true
            and rawMemory.tags.conversation == true
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.kind == "choice"
            and rawInteraction.source == "native_harness"
            and rawInteraction.interactionType == "conversation_choice"
            and rawInteraction.blockID == "pzharness_block"
            and rawInteraction.categoryID == "pzharness_category"
            and rawInteraction.nodeID == "pzharness_node"
            and rawInteraction.choiceID == "pzharness_choice"
            and rawInteraction.outcomeID == "pzharness_outcome"
            and rawInteraction.applied == true,
        "native conversation-effect ModData was not reloaded"
    )
end
