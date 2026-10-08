-- Target-owned native relationship restart fixture, phase one.
-- Exercise one bounded presentation interaction journal entry.

local NPC_ID = "npc_pzharness_relationship_record_interaction_restart"
local TARGET_ID = "npc_pzharness_relationship_record_interaction_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "interaction:pzharness:record-interaction"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Record Interaction NPC",
        identitySeed = 7272,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 270,
        y = 370,
        z = 0,
        identity = {
            seed = 7272,
            displayName = "PZ Harness Record Interaction NPC",
        },
    })
end

local function buildEntry()
    return {
        eventID = EVENT_ID,
        kind = "native_harness_interaction",
        source = "native_harness",
        interactionType = "wave",
        blockID = "pzharness_record_block",
        categoryID = "pzharness_record_category",
        nodeID = "pzharness_record_node",
        choiceID = "pzharness_record_choice",
        outcomeID = "pzharness_record_outcome",
        worldAgeHours = 950,
        at = 950,
        applied = true,
    }
end

local function assertRelationship(relationship, message)
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == 0
            and relationship.respect == 0
            and relationship.familiarity == 0
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 0
            and relationship.lastEvaluatedAt == 950
            and #relationship.memories == 0
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.sequence == 1
            and interaction.kind == "native_harness_interaction"
            and interaction.source == "native_harness"
            and interaction.interactionType == "wave"
            and interaction.blockID == "pzharness_record_block"
            and interaction.categoryID == "pzharness_record_category"
            and interaction.nodeID == "pzharness_record_node"
            and interaction.choiceID == "pzharness_record_choice"
            and interaction.outcomeID == "pzharness_record_outcome"
            and interaction.at == 950
            and interaction.worldAgeHours == 950
            and interaction.applied == true
            and interaction.before
            and interaction.before.approval == 0
            and interaction.before.respect == 0
            and interaction.before.familiarity == 0
            and interaction.before.state == "unknown"
            and interaction.before.revision == 0
            and interaction.after
            and interaction.after.approval == 0
            and interaction.after.respect == 0
            and interaction.after.familiarity == 0
            and interaction.after.state == "unknown"
            and interaction.after.revision == 0
            and interaction.delta
            and interaction.delta.approval == 0
            and interaction.delta.respect == 0
            and interaction.delta.familiarity == 0,
        message
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry interaction-journal API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC interaction-journal record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native interaction-journal entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.RecordInteraction,
        "native relationship interaction-journal API was not available"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local recordOK, record = pcall(buildRecord, types)
    PZHarness.assertTrue(
        recordOK and type(record) == "table" and record.id == NPC_ID
            and record.social and record.social.relationships,
        "native synthetic NPC interaction-journal record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC interaction-journal record was not registered"
    )

    local recorded, recordedReason, relationship =
        relationships.RecordInteraction(
            NPC_ID,
            TARGET_KEY,
            buildEntry()
        )
    PZHarness.assertTrue(
        recorded == true and recordedReason == "recorded"
            and relationship,
        "native relationship interaction recording failed: "
            .. tostring(recordedReason)
    )
    assertRelationship(
        relationship,
        "native relationship interaction journal was not normalized"
    )

    local duplicate, duplicateReason = relationships.RecordInteraction(
        NPC_ID,
        TARGET_KEY,
        buildEntry()
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_interaction",
        "native relationship interaction journal did not reject duplicates"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    assertRelationship(
        stored,
        "native duplicate interaction changed authoritative state"
    )
    PZHarness.assertTrue(
        record.social.recentEventIDs
            and #record.social.recentEventIDs == 0
            and record.social.morale == 0
            and registry.DirtyByID
            and registry.DirtyByID[NPC_ID] == true,
        "native interaction journal changed unrelated social state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_record_interaction_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native interaction-journal commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save interaction-journal state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native interaction-journal NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native interaction-journal directory pointer was not committed"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawInteraction = rawRelationship
        and rawRelationship.interactionJournal
        and rawRelationship.interactionJournal[1]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 7272
            and raw.social and raw.social.morale == 0
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 0
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 0
            and rawRelationship.respect == 0
            and rawRelationship.familiarity == 0
            and rawRelationship.state == "unknown"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 0
            and rawRelationship.lastEvaluatedAt == 950
            and rawRelationship.interactionRevision == 1
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.kind == "native_harness_interaction"
            and rawInteraction.source == "native_harness"
            and rawInteraction.interactionType == "wave"
            and rawInteraction.blockID == "pzharness_record_block"
            and rawInteraction.categoryID == "pzharness_record_category"
            and rawInteraction.nodeID == "pzharness_record_node"
            and rawInteraction.choiceID == "pzharness_record_choice"
            and rawInteraction.outcomeID == "pzharness_record_outcome"
            and rawInteraction.at == 950
            and rawInteraction.worldAgeHours == 950
            and rawInteraction.applied == true,
        "native interaction-journal ModData did not contain the committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native interaction-journal OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_RECORD_INTERACTION_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native interaction-journal GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native interaction-journal GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native interaction-journal GameWindow.save did not trigger OnSave"
        )
    end
end
