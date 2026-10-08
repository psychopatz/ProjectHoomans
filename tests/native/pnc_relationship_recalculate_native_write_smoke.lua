-- Target-owned native relationship-recalculation fixture, phase one.
-- Exercise world-age advancement without pruning the aged memory.

local NPC_ID = "npc_pzharness_relationship_recalculate_restart"
local TARGET_ID = "npc_pzharness_relationship_recalculate_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-recalculate"
local SOURCE_KEY = "npc:" .. NPC_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Recalculate NPC",
        identitySeed = 6666,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 210,
        y = 310,
        z = 0,
        identity = {
            seed = 6666,
            displayName = "PZ Harness Recalculate NPC",
        },
    })
end

local function buildMemory()
    return {
        id = MEMORY_ID,
        type = "native_harness_memory",
        aboutKey = TARGET_KEY,
        createdAt = 900,
        lastEvaluatedAt = 900,
        approvalEffect = 10,
        respectEffect = 5,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0.5,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        sourceKey = SOURCE_KEY,
        tags = {
            native_harness = true,
        },
    }
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry relationship-recalculate API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC relationship-recalculate record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY
            and entityRef.ForNPC(NPC_ID) == SOURCE_KEY,
        "native relationship-recalculate entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.AddMemory and relationships.Recalculate
            and relationships.Get,
        "native relationship-recalculate API was not available"
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
        "native synthetic NPC relationship-recalculate record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC relationship-recalculate record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 30,
            respect = 12,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "neutral",
        "native relationship-recalculate baseline failed: "
            .. tostring(baselineReason)
    )

    local addedMemory, memoryReason, withMemory = relationships.AddMemory(
        NPC_ID,
        TARGET_KEY,
        buildMemory()
    )
    PZHarness.assertTrue(
        addedMemory == true and memoryReason == "added"
            and withMemory and withMemory.approval == 40
            and withMemory.respect == 17
            and withMemory.state == "friend"
            and withMemory.revision == 2
            and withMemory.lastEvaluatedAt == 900
            and #withMemory.memories == 1,
        "native relationship-recalculate memory setup failed: "
            .. tostring(memoryReason)
    )

    local recalculated, recalculateReason, relationship =
        relationships.Recalculate(NPC_ID, TARGET_KEY, 948)
    PZHarness.assertTrue(
        recalculated == true and recalculateReason == "recalculated"
            and relationship,
        "native relationship was not recalculated: "
            .. tostring(recalculateReason)
    )
    local agedMemory = relationship.memories[1]
    PZHarness.assertTrue(
        relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 30
            and relationship.baselineRespect == 12
            and relationship.approval == 30
            and relationship.respect == 12
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 3
            and relationship.lastEvaluatedAt == 948
            and #relationship.memories == 1
            and agedMemory and agedMemory.id == MEMORY_ID
            and agedMemory.createdAt == 900
            and agedMemory.lastEvaluatedAt == 948
            and agedMemory.approvalEffect == 10
            and agedMemory.respectEffect == 5
            and agedMemory.strength == 1
            and agedMemory.decayPerDay == 0.5
            and agedMemory.permanent == false
            and agedMemory.tags.native_harness == true,
        "native relationship recalculation was not normalized"
    )

    local repeated, repeatedReason, repeatedRelationship =
        relationships.Recalculate(NPC_ID, TARGET_KEY, 948)
    PZHarness.assertTrue(
        repeated == false and repeatedReason == "unchanged"
            and repeatedRelationship
            and repeatedRelationship.revision == 3
            and repeatedRelationship.lastEvaluatedAt == 948
            and #repeatedRelationship.memories == 1,
        "native relationship recalculation was not idempotent"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        stored and stored.approval == 30
            and stored.respect == 12
            and stored.state == "friend"
            and stored.revision == 3
            and #stored.memories == 1
            and stored.memories[1].id == MEMORY_ID,
        "native repeated relationship recalculation changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship recalculation did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_recalculate_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship-recalculate commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save relationship recalculation"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native relationship-recalculate record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 6666
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 30
            and rawRelationship.respect == 12
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 3
            and rawRelationship.lastEvaluatedAt == 948
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.lastEvaluatedAt == 948
            and rawMemory.decayPerDay == 0.5
            and rawMemory.permanent == false
            and rawMemory.tags
            and rawMemory.tags.native_harness == true,
        "native relationship ModData did not contain the recalculated state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship-recalculate OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_RECALCULATE_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship-recalculate GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship-recalculate GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship-recalculate GameWindow.save did not trigger OnSave"
        )
    end
end
