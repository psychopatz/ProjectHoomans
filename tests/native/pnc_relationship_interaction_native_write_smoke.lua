-- Target-owned native relationship-journal restart fixture, phase one.
-- Exercise one synthetic interaction entry and duplicate-event protection.

local NPC_ID = "npc_pzharness_relationship_interaction_restart"
local TARGET_ID = "npc_pzharness_relationship_interaction_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "social:pzharness:interaction-restart"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Interaction NPC",
        identitySeed = 6262,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 170,
        y = 270,
        z = 0,
        identity = {
            seed = 6262,
            displayName = "PZ Harness Interaction NPC",
        },
    })
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry interaction API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC interaction record constructor was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.RecordInteraction and relationships.Get,
        "native relationship interaction API was not available"
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
        "native synthetic NPC interaction record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC interaction record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 50,
            respect = 20,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "friend",
        "native interaction relationship baseline failed: "
            .. tostring(baselineReason)
    )

    local recorded, recordReason, relationship =
        relationships.RecordInteraction(
            NPC_ID,
            TARGET_KEY,
            {
                eventID = EVENT_ID,
                kind = "social_event",
                source = "native-harness",
                interactionType = "greeting",
                worldAgeHours = 912,
                at = 912,
                relationshipTier = "friend",
                responseKey = "native_harness_greeting",
                applied = true,
            }
        )
    PZHarness.assertTrue(
        recorded == true and recordReason == "recorded"
            and relationship,
        "native relationship interaction was not recorded: "
            .. tostring(recordReason)
    )
    PZHarness.assertTrue(
        relationship.state == "friend"
            and relationship.interactionRevision == 1
            and #relationship.interactionJournal == 1
            and relationship.interactionJournal[1].eventID == EVENT_ID
            and relationship.interactionJournal[1].sequence == 1
            and relationship.interactionJournal[1].interactionType
                == "greeting"
            and relationship.interactionJournal[1].worldAgeHours == 912
            and relationship.interactionJournal[1].applied == true,
        "native relationship interaction was not normalized"
    )

    local duplicate, duplicateReason = relationships.RecordInteraction(
        NPC_ID,
        TARGET_KEY,
        {
            eventID = EVENT_ID,
            interactionType = "duplicate",
            worldAgeHours = 913,
        }
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_interaction",
        "native relationship duplicate event was not rejected"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        stored and stored.interactionRevision == 1
            and #stored.interactionJournal == 1
            and stored.interactionJournal[1].eventID == EVENT_ID,
        "native relationship journal duplicate changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship interaction did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_interaction_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship interaction commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save interaction state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native interaction record remained dirty after commit"
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
            and raw.identity and raw.identity.seed == 6262
            and type(rawRelationship) == "table"
            and type(rawJournal) == "table"
            and #rawJournal == 1
            and rawJournal[1].eventID == EVENT_ID
            and rawJournal[1].sequence == 1
            and rawJournal[1].interactionType == "greeting"
            and rawJournal[1].worldAgeHours == 912
            and rawJournal[1].applied == true,
        "native relationship ModData did not contain the journal"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship interaction OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_INTERACTION_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship interaction GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship interaction GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship interaction GameWindow.save did not trigger OnSave"
        )
    end
end
