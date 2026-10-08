-- Target-owned native relationship restart fixture, phase one.
-- Exercise creation and read-only reuse of an empty synthetic-NPC relationship.

local NPC_ID = "npc_pzharness_relationship_get_or_create_restart"
local TARGET_ID = "npc_pzharness_relationship_get_or_create_target"
local TARGET_KEY = "npc:" .. TARGET_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness GetOrCreate NPC",
        identitySeed = 6868,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 230,
        y = 330,
        z = 0,
        identity = {
            seed = 6868,
            displayName = "PZ Harness GetOrCreate NPC",
        },
    })
end

local function assertEmptyRelationship(relationship, message)
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
            and relationship.lastEvaluatedAt == 0
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0,
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
        "native NPC registry relationship GetOrCreate API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC GetOrCreate record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native relationship GetOrCreate entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.GetOrCreate,
        "native relationship GetOrCreate API was not available"
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
        "native synthetic NPC GetOrCreate record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC GetOrCreate record was not registered"
    )
    PZHarness.assertEqual(
        record.recordRevision,
        1,
        "native GetOrCreate record was not marked dirty"
    )

    local missing, missingReason = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        missing == nil and missingReason == "relationship_not_found",
        "native GetOrCreate fixture did not begin without a relationship"
    )

    local created, createdReason = relationships.GetOrCreate(
        NPC_ID,
        TARGET_KEY
    )
    PZHarness.assertTrue(
        createdReason == "created",
        "native relationship GetOrCreate did not report creation: "
            .. tostring(createdReason)
    )
    assertEmptyRelationship(
        created,
        "native relationship GetOrCreate did not create a normalized empty relationship"
    )

    local existing, existingReason = relationships.GetOrCreate(
        NPC_ID,
        TARGET_KEY
    )
    PZHarness.assertTrue(
        existingReason == "existing",
        "native relationship GetOrCreate did not report an existing relationship: "
            .. tostring(existingReason)
    )
    assertEmptyRelationship(
        existing,
        "native relationship GetOrCreate existing read was not stable"
    )

    local stored = record.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(stored) == "table"
            and stored.targetID == TARGET_ID
            and stored.revision == 1,
        "native GetOrCreate did not retain the created relationship"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native GetOrCreate mutation did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_get_or_create_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native GetOrCreate commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save GetOrCreate NPC state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native GetOrCreate NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native GetOrCreate directory pointer was not committed"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 6868
            and type(rawRelationship) == "table"
            and rawRelationship.targetID == TARGET_ID
            and rawRelationship.approval == 0
            and rawRelationship.respect == 0
            and rawRelationship.familiarity == 0
            and rawRelationship.state == "unknown"
            and rawRelationship.revision == 1,
        "native GetOrCreate ModData did not contain the empty relationship"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native GetOrCreate OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_GET_OR_CREATE_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native GetOrCreate GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native GetOrCreate GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native GetOrCreate GameWindow.save did not trigger OnSave"
        )
    end
end
