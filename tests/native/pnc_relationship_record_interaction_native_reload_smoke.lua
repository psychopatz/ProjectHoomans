-- Target-owned native relationship restart fixture, phase two.
-- Exercise one presentation interaction journal after JVM restart.

local NPC_ID = "npc_pzharness_relationship_record_interaction_restart"
local TARGET_ID = "npc_pzharness_relationship_record_interaction_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "interaction:pzharness:record-interaction"

local function buildEntry()
    return {
        eventID = EVENT_ID,
        kind = "native_harness_interaction",
        source = "native_harness",
        interactionType = "wave",
        blockID = "pzharness_record_block",
        categoryID = "pzharness_record_category",
        nodeID = "pzharness_record_node",
        choiceID = "pzharness_record_choice",
        outcomeID = "pzharness_record_outcome",
        worldAgeHours = 950,
        at = 950,
        applied = true,
    }
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after interaction-journal restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.RecordInteraction,
        "native interaction-journal API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Record Interaction NPC"
            and record.identitySeed == 7272
            and record.social and record.social.relationships,
        "native interaction-journal NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.approval == 0
            and relationship.respect == 0
            and relationship.familiarity == 0
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 0
            and relationship.lastEvaluatedAt == 950
            and #relationship.memories == 0
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.sequence == 1
            and interaction.kind == "native_harness_interaction"
            and interaction.source == "native_harness"
            and interaction.interactionType == "wave"
            and interaction.blockID == "pzharness_record_block"
            and interaction.categoryID == "pzharness_record_category"
            and interaction.nodeID == "pzharness_record_node"
            and interaction.choiceID == "pzharness_record_choice"
            and interaction.outcomeID == "pzharness_record_outcome"
            and interaction.at == 950
            and interaction.worldAgeHours == 950
            and interaction.applied == true
            and interaction.before
            and interaction.before.state == "unknown"
            and interaction.before.revision == 0
            and interaction.after
            and interaction.after.state == "unknown"
            and interaction.after.revision == 0
            and interaction.delta
            and interaction.delta.approval == 0
            and interaction.delta.respect == 0
            and interaction.delta.familiarity == 0,
        "native interaction journal did not survive restart"
    )
    PZHarness.assertTrue(
        record.social.recentEventIDs
            and #record.social.recentEventIDs == 0
            and record.social.morale == 0,
        "native interaction-journal unrelated social state did not survive restart"
    )

    local duplicate, duplicateReason = relationships.RecordInteraction(
        NPC_ID,
        TARGET_KEY,
        buildEntry()
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_interaction",
        "native interaction-journal duplicate rejection did not survive restart"
    )
    PZHarness.assertTrue(
        (tonumber(record.recordRevision) or 0) >= 1,
        "native interaction-journal NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native interaction-journal persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
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
            and raw.social and raw.social.morale == 0
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 0
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 0
            and rawRelationship.respect == 0
            and rawRelationship.familiarity == 0
            and rawRelationship.state == "unknown"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 0
            and rawRelationship.lastEvaluatedAt == 950
            and rawRelationship.interactionRevision == 1
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.kind == "native_harness_interaction"
            and rawInteraction.source == "native_harness"
            and rawInteraction.interactionType == "wave"
            and rawInteraction.blockID == "pzharness_record_block"
            and rawInteraction.categoryID == "pzharness_record_category"
            and rawInteraction.nodeID == "pzharness_record_node"
            and rawInteraction.choiceID == "pzharness_record_choice"
            and rawInteraction.outcomeID == "pzharness_record_outcome"
            and rawInteraction.at == 950
            and rawInteraction.worldAgeHours == 950
            and rawInteraction.applied == true,
        "native interaction-journal ModData was not reloaded"
    )
end
