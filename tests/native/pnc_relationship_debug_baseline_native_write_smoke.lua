-- Target-owned native relationship restart fixture, phase one.
-- Exercise the bounded debug baseline setter on one synthetic NPC.

local NPC_ID = "npc_pzharness_relationship_debug_baseline_restart"
local TARGET_ID = "npc_pzharness_relationship_debug_baseline_target"
local TARGET_KEY = "npc:" .. TARGET_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Debug Baseline NPC",
        identitySeed = 7474,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 290,
        y = 390,
        z = 0,
        identity = {
            seed = 7474,
            displayName = "PZ Harness Debug Baseline NPC",
        },
    })
end

local function assertRelationship(
    relationship,
    approval,
    respect,
    familiarity,
    revision,
    worldAgeHours,
    message
)
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == approval
            and relationship.baselineRespect == respect
            and relationship.approval == approval
            and relationship.respect == respect
            and relationship.familiarity == familiarity
            and relationship.state == "friend"
            and relationship.previousState == "unknown"
            and relationship.revision == revision
            and relationship.lastEvaluatedAt == worldAgeHours
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0,
        message
    )
end

local function assertDebugChange(record, index, approval, respect, revision)
    local changes = record.runtime
        and record.runtime.relationshipDebugChanges
    local change = changes and changes[index]
    PZHarness.assertTrue(
        type(change) == "table"
            and change.kind == "debug_baseline_set"
            and change.targetKey == TARGET_KEY
            and change.approvalAfter == approval
            and change.respectAfter == respect
            and change.relationshipRevision == revision,
        "native debug baseline change was not recorded"
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
        "native NPC registry debug-baseline API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC debug-baseline record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native debug-baseline entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.SetDebugBaseline,
        "native relationship debug-baseline API was not available"
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
        "native synthetic NPC debug-baseline record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC debug-baseline record was not registered"
    )

    local first = relationships.SetDebugBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 35,
            respect = 15,
            familiarity = 7,
        },
        900
    )
    assertRelationship(
        first,
        35,
        15,
        7,
        1,
        900,
        "native debug baseline creation was not normalized"
    )
    assertDebugChange(record, 1, 35, 15, 1)

    local second = relationships.SetDebugBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 42,
            respect = 24,
            familiarity = 9,
        },
        930
    )
    assertRelationship(
        second,
        42,
        24,
        9,
        2,
        930,
        "native debug baseline update was not normalized"
    )
    assertDebugChange(record, 2, 42, 24, 2)
    PZHarness.assertTrue(
        record.social.relationships[TARGET_KEY].approval == 42
            and record.social.relationships[TARGET_KEY].revision == 2
            and registry.DirtyByID
            and registry.DirtyByID[NPC_ID] == true,
        "native debug baseline did not retain authoritative state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_debug_baseline_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native debug-baseline commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save debug-baseline state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native debug-baseline NPC record remained dirty after commit"
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
            and raw.identity and raw.identity.seed == 7474
            and type(rawRelationship) == "table"
            and rawRelationship.baselineApproval == 42
            and rawRelationship.baselineRespect == 24
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 9
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 2
            and rawRelationship.lastEvaluatedAt == 930
            and #rawRelationship.memories == 0,
        "native debug-baseline ModData did not contain the update"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native debug-baseline OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_DEBUG_BASELINE_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native debug-baseline GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native debug-baseline GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native debug-baseline GameWindow.save did not trigger OnSave"
        )
    end
end
