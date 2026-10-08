-- Target-owned native relationship-memory pruning fixture, phase one.
-- Exercise one expired temporary memory and one permanent survivor.

local NPC_ID = "npc_pzharness_relationship_memory_prune_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_prune_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local SOURCE_KEY = "npc:" .. NPC_ID
local TEMP_MEMORY_ID = "memory:pzharness:relationship-prune-expired"
local PERMANENT_MEMORY_ID = "memory:pzharness:relationship-prune-permanent"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Memory Prune NPC",
        identitySeed = 6565,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 200,
        y = 300,
        z = 0,
        identity = {
            seed = 6565,
            displayName = "PZ Harness Memory Prune NPC",
        },
    })
end

local function buildMemory(
    memoryID,
    createdAt,
    approvalEffect,
    respectEffect,
    permanent,
    decayPerDay
)
    return {
        id = memoryID,
        type = "native_harness_memory",
        aboutKey = TARGET_KEY,
        createdAt = createdAt,
        lastEvaluatedAt = createdAt,
        approvalEffect = approvalEffect,
        respectEffect = respectEffect,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = decayPerDay,
        permanent = permanent,
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
        "native NPC registry relationship-memory prune API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC relationship-memory prune record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY
            and entityRef.ForNPC(NPC_ID) == SOURCE_KEY,
        "native relationship-memory prune entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.AddMemory and relationships.PruneMemories
            and relationships.Get,
        "native relationship-memory prune API was not available"
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
        "native synthetic NPC relationship-memory prune record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC relationship-memory prune record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 20,
            respect = 8,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "neutral",
        "native relationship-memory prune baseline failed: "
            .. tostring(baselineReason)
    )

    local temporaryAdded, temporaryReason, withTemporary =
        relationships.AddMemory(
            NPC_ID,
            TARGET_KEY,
            buildMemory(TEMP_MEMORY_ID, 900, 10, 5, false, 1)
        )
    PZHarness.assertTrue(
        temporaryAdded == true and temporaryReason == "added"
            and withTemporary and withTemporary.approval == 30
            and withTemporary.respect == 13
            and withTemporary.state == "neutral"
            and withTemporary.revision == 2
            and #withTemporary.memories == 1,
        "native temporary relationship memory setup failed: "
            .. tostring(temporaryReason)
    )

    local permanentAdded, permanentReason, withBoth = relationships.AddMemory(
        NPC_ID,
        TARGET_KEY,
        buildMemory(PERMANENT_MEMORY_ID, 910, 18, 7, true, 0)
    )
    PZHarness.assertTrue(
        permanentAdded == true and permanentReason == "added"
            and withBoth and withBoth.approval > 43
            and withBoth.approval < 44
            and withBoth.respect > 17
            and withBoth.respect < 18
            and withBoth.state == "friend"
            and withBoth.revision == 3
            and withBoth.lastEvaluatedAt == 910
            and #withBoth.memories == 2,
        "native permanent relationship memory setup failed: "
            .. tostring(permanentReason)
    )

    local pruned, pruneReason, removed = relationships.PruneMemories(
        NPC_ID,
        TARGET_KEY,
        930
    )
    PZHarness.assertTrue(
        pruned == true and pruneReason == "pruned" and removed == 1,
        "native relationship memories were not pruned: "
            .. tostring(pruneReason) .. ":" .. tostring(removed)
    )
    local afterPrune = relationships.Get(NPC_ID, TARGET_KEY)
    local survivor = afterPrune and afterPrune.memories
        and afterPrune.memories[1]
    PZHarness.assertTrue(
        afterPrune and afterPrune.baselineApproval == 20
            and afterPrune.baselineRespect == 8
            and afterPrune.approval == 38
            and afterPrune.respect == 15
            and afterPrune.familiarity == 8
            and afterPrune.state == "friend"
            and afterPrune.revision == 4
            and afterPrune.lastEvaluatedAt == 930
            and #afterPrune.memories == 1
            and survivor and survivor.id == PERMANENT_MEMORY_ID
            and survivor.createdAt == 910
            and survivor.lastEvaluatedAt == 930
            and survivor.approvalEffect == 18
            and survivor.respectEffect == 7
            and survivor.permanent == true
            and survivor.decayPerDay == 0
            and survivor.tags.native_harness == true,
        "native relationship memory pruning was not normalized"
    )

    local repeatPrune, repeatReason, repeatRemoved =
        relationships.PruneMemories(NPC_ID, TARGET_KEY, 930)
    PZHarness.assertTrue(
        repeatPrune == false and repeatReason == "unchanged"
            and repeatRemoved == 0,
        "native relationship memory pruning was not idempotent"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        stored and #stored.memories == 1
            and stored.memories[1].id == PERMANENT_MEMORY_ID
            and stored.approval == 38
            and stored.respect == 15
            and stored.revision == 4,
        "native repeated relationship-memory pruning changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship memory pruning did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_memory_prune_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship-memory prune commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save relationship-memory prune"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native relationship-memory prune record remained dirty after commit"
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
            and raw.identity and raw.identity.seed == 6565
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 38
            and rawRelationship.respect == 15
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 4
            and type(rawRelationship.memories) == "table"
            and #rawRelationship.memories == 1
            and type(rawMemory) == "table"
            and rawMemory.id == PERMANENT_MEMORY_ID
            and rawMemory.createdAt == 910
            and rawMemory.lastEvaluatedAt == 930
            and rawMemory.permanent == true
            and rawMemory.tags
            and rawMemory.tags.native_harness == true,
        "native relationship ModData did not contain the pruned memory set"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship-memory prune OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_MEMORY_PRUNE_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship-memory prune GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship-memory prune GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship-memory prune GameWindow.save did not trigger OnSave"
        )
    end
end
