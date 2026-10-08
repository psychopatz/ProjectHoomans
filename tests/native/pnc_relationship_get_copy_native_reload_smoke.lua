-- Target-owned native relationship restart fixture, phase two.
-- Exercise immutable returned-copy behavior after JVM restart.

local NPC_ID = "npc_pzharness_relationship_get_copy_restart"
local TARGET_ID = "npc_pzharness_relationship_get_copy_target"
local TARGET_KEY = "npc:" .. TARGET_ID

local function mutateReturnedCopy(relationship)
    relationship.approval = -99
    relationship.targetID = "mutated_target"
    relationship.state = "enemy"
    relationship.memories[1] = {
        id = "memory:pzharness:mutated-copy-reload",
    }
    relationship.cooldowns.mutated = 999
    relationship.interactionJournal[1] = {
        eventID = "interaction:pzharness:mutated-copy-reload",
    }
end

local function assertCanonical(relationship, message)
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 30
            and relationship.baselineRespect == 12
            and relationship.approval == 30
            and relationship.respect == 12
            and relationship.familiarity == 8
            and relationship.state == "neutral"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 900
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0
            and relationship.cooldowns
            and relationship.cooldowns.mutated == nil,
        message
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after Get-copy restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship Get API was not available after restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Get Copy NPC"
            and record.identitySeed == 7373
            and record.social and record.social.relationships,
        "native Get-copy NPC record was not reloaded"
    )
    local returned = relationships.Get(NPC_ID, TARGET_KEY)
    assertCanonical(
        returned,
        "native canonical Get-copy relationship did not survive restart"
    )
    mutateReturnedCopy(returned)
    local reread = relationships.Get(NPC_ID, TARGET_KEY)
    assertCanonical(
        reread,
        "native reloaded Get returned copy mutated authoritative state"
    )
    PZHarness.assertTrue(
        record.social.relationships[TARGET_KEY].approval == 30
            and record.social.relationships[TARGET_KEY].state == "neutral"
            and #record.social.relationships[TARGET_KEY].memories == 0,
        "native reloaded Get-copy mutation changed authoritative state"
    )
    PZHarness.assertTrue(
        (tonumber(record.recordRevision) or 0) >= 1,
        "native Get-copy NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native Get-copy persistence schema did not survive restart"
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
            and rawRelationship.approval == 30
            and rawRelationship.respect == 12
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "neutral"
            and rawRelationship.revision == 1
            and rawRelationship.lastEvaluatedAt == 900
            and #rawRelationship.memories == 0
            and #rawRelationship.interactionJournal == 0,
        "native Get-copy ModData was not reloaded"
    )
end
