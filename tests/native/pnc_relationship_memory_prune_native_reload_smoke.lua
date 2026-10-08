-- Target-owned native relationship-memory pruning fixture, phase two.
-- Exercise the permanent survivor after JVM restart.

local NPC_ID = "npc_pzharness_relationship_memory_prune_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_prune_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local PERMANENT_MEMORY_ID = "memory:pzharness:relationship-prune-permanent"

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship-memory prune restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after relationship-memory prune restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Memory Prune NPC"
            and record.identitySeed == 6565
            and record.social and record.social.relationships,
        "native relationship-memory prune NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local survivor = relationship and relationship.memories
        and relationship.memories[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 20
            and relationship.baselineRespect == 8
            and relationship.approval == 38
            and relationship.respect == 15
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 4
            and relationship.lastEvaluatedAt == 930
            and #relationship.memories == 1
            and survivor and survivor.id == PERMANENT_MEMORY_ID
            and survivor.createdAt == 910
            and survivor.lastEvaluatedAt == 930
            and survivor.approvalEffect == 18
            and survivor.respectEffect == 7
            and survivor.strength == 1
            and survivor.decayPerDay == 0
            and survivor.permanent == true
            and survivor.shareable == true
            and survivor.knowledgeSource == "experienced"
            and survivor.tags.native_harness == true,
        "native relationship-memory prune survivor did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship-memory prune NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship-memory prune persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 38
            and rawRelationship.respect == 15
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 4
            and type(rawRelationship.memories) == "table"
            and #rawRelationship.memories == 1
            and type(rawMemory) == "table"
            and rawMemory.id == PERMANENT_MEMORY_ID
            and rawMemory.createdAt == 910
            and rawMemory.lastEvaluatedAt == 930
            and rawMemory.permanent == true,
        "native relationship-memory prune ModData was not reloaded"
    )
end
