-- Target-owned native relationship restart fixture, phase one.
-- Exercise scalar relationship query projections over one synthetic NPC.

local NPC_ID = "npc_pzharness_relationship_scalar_queries_restart"
local TARGET_ID = "npc_pzharness_relationship_scalar_queries_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MISSING_TARGET_KEY = "npc:pzharness_relationship_scalar_queries_missing"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Scalar Queries NPC",
        identitySeed = 6969,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 240,
        y = 340,
        z = 0,
        identity = {
            seed = 6969,
            displayName = "PZ Harness Scalar Queries NPC",
        },
    })
end

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
        messagePrefix .. " approval projection was not normalized"
    )
    PZHarness.assertTrue(
        respect == 24 and respectReason == nil,
        messagePrefix .. " respect projection was not normalized"
    )
    PZHarness.assertTrue(
        familiarity == 7 and familiarityReason == nil,
        messagePrefix .. " familiarity projection was not normalized"
    )
    PZHarness.assertTrue(
        state == "friend" and stateReason == nil,
        messagePrefix .. " state projection was not normalized"
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
        "native NPC registry scalar-query API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC scalar-query record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native relationship scalar-query entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.Get and relationships.GetApproval
            and relationships.GetRespect and relationships.GetFamiliarity
            and relationships.GetState,
        "native relationship scalar-query API was not available"
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
        "native synthetic NPC scalar-query record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC scalar-query record was not registered"
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
        relationship and relationshipReason == nil
            and relationship.state == "friend"
            and relationship.revision == 1,
        "native scalar-query relationship baseline failed: "
            .. tostring(relationshipReason)
    )
    assertProjections(relationships, "native scalar-query")

    local missing, missingReason = relationships.GetState(
        NPC_ID,
        MISSING_TARGET_KEY
    )
    PZHarness.assertTrue(
        missing == nil and missingReason == "relationship_not_found",
        "native scalar-query missing-target rejection was not preserved"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native scalar-query setup did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_scalar_queries_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native scalar-query commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save scalar-query NPC state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native scalar-query NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native scalar-query directory pointer was not committed"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 6969
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 7
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1,
        "native scalar-query ModData did not contain the relationship"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native scalar-query OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_SCALAR_QUERIES_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native scalar-query GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native scalar-query GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native scalar-query GameWindow.save did not trigger OnSave"
        )
    end
end
