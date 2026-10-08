-- Target-owned native relationship-memory restart fixture, phase two.
-- Exercise one synthetic memory after JVM restart.

local NPC_ID = "npc_pzharness_relationship_memory_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-memory-restart"
local SOURCE_KEY = "npc:" .. NPC_ID

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship-memory restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after relationship-memory restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Memory NPC"
            and record.identitySeed == 6363
            and record.social and record.social.relationships,
        "native relationship-memory NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 24
            and relationship.baselineRespect == 10
            and relationship.approval == 42
            and relationship.respect == 17
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 2
            and relationship.lastEvaluatedAt == 930
            and #relationship.memories == 1
            and memory and memory.id == MEMORY_ID
            and memory.type == "native_harness_memory"
            and memory.aboutKey == TARGET_KEY
            and memory.createdAt == 930
            and memory.lastEvaluatedAt == 930
            and memory.approvalEffect == 18
            and memory.respectEffect == 7
            and memory.strength == 1
            and memory.decayPerDay == 0
            and memory.permanent == true
            and memory.shareable == true
            and memory.knowledgeSource == "experienced"
            and memory.sourceKey == SOURCE_KEY
            and memory.tags.native_harness == true,
        "native relationship memory did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship-memory NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship-memory persistence schema did not survive restart"
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
            and rawRelationship.approval == 42
            and rawRelationship.respect == 17
            and rawRelationship.revision == 2
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.createdAt == 930
            and rawMemory.lastEvaluatedAt == 930
            and rawMemory.approvalEffect == 18
            and rawMemory.respectEffect == 7
            and rawMemory.permanent == true
            and rawMemory.sourceKey == SOURCE_KEY
            and rawMemory.tags
            and rawMemory.tags.native_harness == true,
        "native relationship-memory ModData was not reloaded"
    )
end
