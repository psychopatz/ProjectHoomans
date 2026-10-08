-- Target-owned native relationship restart fixture, phase two.
-- Exercise synthetic NPC relationship baseline recovery after JVM restart.

local NPC_ID = "npc_pzharness_relationship_restart"
local TARGET_ID = "npc_pzharness_relationship_target"
local TARGET_KEY = "npc:" .. TARGET_ID

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Relationship NPC"
            and record.identitySeed == 6161
            and record.social and record.social.relationships,
        "native relationship NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 42
            and relationship.baselineRespect == 24
            and relationship.approval == 42
            and relationship.respect == 24
            and relationship.familiarity == 7
            and relationship.state == "friend"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 900
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0,
        "native relationship baseline did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native relationship directory pointer was not reloaded"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and type(rawRelationship) == "table"
            and rawRelationship.baselineApproval == 42
            and rawRelationship.baselineRespect == 24
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 7
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1,
        "native relationship baseline ModData was not reloaded"
    )
end
