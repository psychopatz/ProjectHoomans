-- Target-owned native relationship-recalculation fixture, phase two.
-- Exercise the aged relationship after JVM restart.

local NPC_ID = "npc_pzharness_relationship_recalculate_restart"
local TARGET_ID = "npc_pzharness_relationship_recalculate_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-recalculate"

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship-recalculate restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after relationship-recalculate restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Recalculate NPC"
            and record.identitySeed == 6666
            and record.social and record.social.relationships,
        "native relationship-recalculate NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local agedMemory = relationship and relationship.memories
        and relationship.memories[1]
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 30
            and relationship.baselineRespect == 12
            and relationship.approval == 30
            and relationship.respect == 12
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 3
            and relationship.lastEvaluatedAt == 948
            and #relationship.memories == 1
            and agedMemory and agedMemory.id == MEMORY_ID
            and agedMemory.createdAt == 900
            and agedMemory.lastEvaluatedAt == 948
            and agedMemory.approvalEffect == 10
            and agedMemory.respectEffect == 5
            and agedMemory.strength == 1
            and agedMemory.decayPerDay == 0.5
            and agedMemory.permanent == false
            and agedMemory.tags.native_harness == true,
        "native recalculated relationship did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship-recalculate NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship-recalculate persistence schema did not survive restart"
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
            and rawRelationship.approval == 30
            and rawRelationship.respect == 12
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 3
            and rawRelationship.lastEvaluatedAt == 948
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.lastEvaluatedAt == 948
            and rawMemory.decayPerDay == 0.5
            and rawMemory.permanent == false,
        "native relationship-recalculate ModData was not reloaded"
    )
end
