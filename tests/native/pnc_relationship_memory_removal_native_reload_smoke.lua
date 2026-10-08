-- Target-owned native relationship-memory removal fixture, phase two.
-- Exercise the removed synthetic memory after JVM restart.

local NPC_ID = "npc_pzharness_relationship_memory_removal_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_removal_target"
local TARGET_KEY = "npc:" .. TARGET_ID

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship-memory removal restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after relationship-memory removal restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Memory Removal NPC"
            and record.identitySeed == 6464
            and record.social and record.social.relationships,
        "native relationship-memory removal NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 24
            and relationship.baselineRespect == 10
            and relationship.approval == 24
            and relationship.respect == 10
            and relationship.familiarity == 8
            and relationship.state == "neutral"
            and relationship.revision == 3
            and relationship.lastEvaluatedAt == 930
            and #relationship.memories == 0,
        "native relationship memory removal did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship-memory removal NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship-memory removal persistence schema did not survive restart"
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
            and rawRelationship.approval == 24
            and rawRelationship.respect == 10
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "neutral"
            and rawRelationship.revision == 3
            and type(rawRelationship.memories) == "table"
            and #rawRelationship.memories == 0
            and rawRelationship.memories[1] == nil,
        "native relationship-memory removal ModData was not reloaded"
    )
end
