-- Target-owned native relationship restart fixture, phase two.
-- Exercise empty synthetic-NPC relationship recovery after JVM restart.

local NPC_ID = "npc_pzharness_relationship_get_or_create_restart"
local TARGET_ID = "npc_pzharness_relationship_get_or_create_target"
local TARGET_KEY = "npc:" .. TARGET_ID

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship GetOrCreate restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after GetOrCreate restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness GetOrCreate NPC"
            and record.identitySeed == 6868
            and record.social and record.social.relationships,
        "native GetOrCreate NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == 0
            and relationship.respect == 0
            and relationship.familiarity == 0
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 0
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0,
        "native empty relationship did not survive restart"
    )
    PZHarness.assertEqual(
        tonumber(record.recordRevision) or 0,
        1,
        "native GetOrCreate NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native GetOrCreate persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and type(rawRelationship) == "table"
            and rawRelationship.targetID == TARGET_ID
            and rawRelationship.approval == 0
            and rawRelationship.respect == 0
            and rawRelationship.familiarity == 0
            and rawRelationship.state == "unknown"
            and rawRelationship.revision == 1,
        "native empty relationship ModData was not reloaded"
    )
end
