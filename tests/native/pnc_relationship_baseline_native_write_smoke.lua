-- Target-owned native relationship restart fixture, phase one.
-- Exercise a synthetic NPC relationship baseline without live actors.

local NPC_ID = "npc_pzharness_relationship_restart"
local TARGET_ID = "npc_pzharness_relationship_target"
local TARGET_KEY = "npc:" .. TARGET_ID

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry relationship API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native relationship entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.Get,
        "native relationship baseline API was not available"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local recordOK, record = pcall(
        types.NewRecord,
        {
            id = NPC_ID,
            displayName = "PZ Harness Relationship NPC",
            identitySeed = 6161,
            archetypeID = "General",
            tacticalClass = "neutral",
            x = 160,
            y = 260,
            z = 0,
            identity = {
                seed = 6161,
                displayName = "PZ Harness Relationship NPC",
            },
        }
    )
    PZHarness.assertTrue(
        recordOK and type(record) == "table" and record.id == NPC_ID
            and record.social and record.social.relationships,
        "native synthetic NPC relationship record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC relationship record was not registered"
    )
    PZHarness.assertEqual(
        record.recordRevision,
        1,
        "native relationship record was not marked dirty"
    )

    local relationship, relationshipReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 42,
            respect = 24,
            familiarity = 7,
        },
        900
    )
    PZHarness.assertTrue(
        relationship and relationshipReason == nil,
        "native relationship baseline failed: " .. tostring(relationshipReason)
    )
    PZHarness.assertTrue(
        relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 42
            and relationship.baselineRespect == 24
            and relationship.approval == 42
            and relationship.respect == 24
            and relationship.familiarity == 7
            and relationship.state == "friend"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 900
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0,
        "native relationship baseline was not normalized"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        stored and stored.revision == 1
            and stored.state == "friend"
            and stored.baselineApproval == 42
            and stored.familiarity == 7,
        "native relationship baseline was not readable"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship mutation did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_baseline_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship baseline commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save NPC relationship state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native NPC relationship record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native relationship directory pointer was not committed"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 6161
            and type(rawRelationship) == "table"
            and rawRelationship.baselineApproval == 42
            and rawRelationship.baselineRespect == 24
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 7
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1,
        "native relationship ModData did not contain the baseline"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_BASELINE_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship GameWindow.save did not trigger OnSave"
        )
    end
end
