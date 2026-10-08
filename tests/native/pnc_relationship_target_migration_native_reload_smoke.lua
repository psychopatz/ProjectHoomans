-- Target-owned native relationship target-key migration fixture, phase two.
-- Exercise the canonical relationship after JVM restart.

local NPC_ID = "npc_pzharness_relationship_target_migration_restart"
local LEGACY_TARGET_ID = "npc_pzharness_relationship_target_legacy"
local CANONICAL_TARGET_ID = "npc_pzharness_relationship_target_canonical"
local LEGACY_TARGET_KEY = "npc:" .. LEGACY_TARGET_ID
local CANONICAL_TARGET_KEY = "npc:" .. CANONICAL_TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-target-migration"

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after relationship target-migration restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after relationship target-migration restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Target Migration NPC"
            and record.identitySeed == 6767
            and record.social and record.social.relationships,
        "native relationship target-migration NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, CANONICAL_TARGET_KEY)
    local legacyRelationship = record.social.relationships[LEGACY_TARGET_KEY]
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    PZHarness.assertTrue(
        relationship and legacyRelationship == nil
            and relationship.targetKind == "npc"
            and relationship.targetID == CANONICAL_TARGET_ID
            and relationship.baselineApproval == 22
            and relationship.baselineRespect == 9
            and relationship.approval == 40
            and relationship.respect == 16
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 3
            and relationship.lastEvaluatedAt == 900
            and #relationship.memories == 1
            and memory and memory.id == MEMORY_ID
            and memory.aboutKey == CANONICAL_TARGET_KEY
            and memory.sourceKey == CANONICAL_TARGET_KEY
            and memory.permanent == true
            and memory.tags.native_harness == true,
        "native migrated relationship did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native relationship target-migration NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native relationship target-migration persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationships = raw and raw.social and raw.social.relationships
    local rawRelationship = rawRelationships
        and rawRelationships[CANONICAL_TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and type(rawRelationships) == "table"
            and rawRelationships[LEGACY_TARGET_KEY] == nil
            and type(rawRelationship) == "table"
            and rawRelationship.targetID == CANONICAL_TARGET_ID
            and rawRelationship.approval == 40
            and rawRelationship.respect == 16
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 3
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == CANONICAL_TARGET_KEY
            and rawMemory.sourceKey == CANONICAL_TARGET_KEY,
        "native relationship target-migration ModData was not reloaded"
    )
end
