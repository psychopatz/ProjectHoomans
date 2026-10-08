-- Target-owned native relationship-journal restart fixture, phase two.
-- Exercise one synthetic interaction entry after JVM restart.

local NPC_ID = "npc_pzharness_relationship_interaction_restart"
local TARGET_ID = "npc_pzharness_relationship_interaction_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "social:pzharness:interaction-restart"

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.Get and registry.GetStorageDirectory,
        "native NPC registry was not available after interaction restart"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available after interaction restart"
    )

    local record = registry.Get(NPC_ID)
    PZHarness.assertTrue(
        type(record) == "table"
            and record.id == NPC_ID
            and record.name == "PZ Harness Interaction NPC"
            and record.identitySeed == 6262
            and record.social and record.social.relationships,
        "native interaction NPC record was not reloaded"
    )
    local relationship = relationships.Get(NPC_ID, TARGET_KEY)
    local journal = relationship and relationship.interactionJournal
    PZHarness.assertTrue(
        relationship and relationship.state == "friend"
            and relationship.baselineApproval == 50
            and relationship.baselineRespect == 20
            and relationship.familiarity == 8
            and relationship.interactionRevision == 1
            and type(journal) == "table"
            and #journal == 1
            and journal[1].eventID == EVENT_ID
            and journal[1].sequence == 1
            and journal[1].interactionType == "greeting"
            and journal[1].worldAgeHours == 912
            and journal[1].applied == true,
        "native relationship journal did not survive restart"
    )
    local loadedRevision = tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native interaction NPC record revision did not survive restart"
    )
    PZHarness.assertEqual(
        record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native interaction persistence schema did not survive restart"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawJournal = rawRelationship
        and rawRelationship.interactionJournal
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.recordRevision == 1
            and type(rawJournal) == "table"
            and #rawJournal == 1
            and rawJournal[1].eventID == EVENT_ID
            and rawJournal[1].sequence == 1
            and rawJournal[1].interactionType == "greeting"
            and rawJournal[1].worldAgeHours == 912
            and rawJournal[1].applied == true,
        "native relationship journal ModData was not reloaded"
    )
end
