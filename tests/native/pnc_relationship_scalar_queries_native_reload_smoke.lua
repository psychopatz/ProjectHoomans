-- Target-owned native relationship restart fixture, phase two.
-- Exercise scalar relationship query recovery after JVM restart.

local NPC_ID = "npc_pzharness_relationship_scalar_queries_restart"
local TARGET_ID = "npc_pzharness_relationship_scalar_queries_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MISSING_TARGET_KEY = "npc:pzharness_relationship_scalar_queries_missing"

local function assertProjections(relationships, messagePrefix)
    local approval, approvalReason = relationships.GetApproval(
        NPC_ID,
        TARGET_KEY
    )
    local respect, respectReason = relationships.GetRespect(
        NPC_ID,
        TARGET_KEY
    )
    local familiarity, familiarityReason = relationships.GetFamiliarity(
        NPC_ID,
        TARGET_KEY
    )
    local state, stateReason = relationships.GetState(
        NPC_ID,
        TARGET_KEY
    )
    PZHarness.assertTrue(
        approval == 42 and approvalReason == nil,
        messagePrefix .. " approval projection did not survive restart"
    )
    PZHarness.assertTrue(
        respect == 24 and respectReason == nil,
        messagePrefix .. " respect projection did not survive restart"
    )
    PZHarness.assertTrue(
        familiarity == 7 and familiarityReason == nil,
        messagePrefix .. " familiarity projection did not survive restart"
    )
    PZHarness.assertTrue(
        state == "friend" and stateReason == nil,
        messagePrefix .. " state projection did not survive restart"
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after scalar-query restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get and relationships.GetApproval
            and relationships.GetRespect and relationships.GetFamiliarity
            and relationships.GetState,
        "native scalar-query API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Scalar Queries NPC"
            and record.identitySeed == 6969
            and record.social and record.social.relationships,
        "native scalar-query NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        relationship and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.approval == 42
            and relationship.respect == 24
            and relationship.familiarity == 7
            and relationship.state == "friend"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 900,
        "native scalar-query relationship did not survive restart"
    )
    assertProjections(relationships, "native scalar-query")

    local missing, missingReason = relationships.GetApproval(
        NPC_ID,
        MISSING_TARGET_KEY
    )
    PZHarness.assertTrue(
        missing == nil and missingReason == "relationship_not_found",
        "native scalar-query missing-target rejection did not survive restart"
    )
    PZHarness.assertTrue(
        (tonumber(record.recordRevision) or 0) >= 1,
        "native scalar-query NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native scalar-query persistence schema did not survive restart"
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
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 7
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1,
        "native scalar-query ModData was not reloaded"
    )
end
