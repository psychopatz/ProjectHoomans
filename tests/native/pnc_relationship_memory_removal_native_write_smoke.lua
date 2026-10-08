-- Target-owned native relationship-memory removal fixture, phase one.
-- Exercise one synthetic memory, removal, and missing-memory protection.

local NPC_ID = "npc_pzharness_relationship_memory_removal_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_removal_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-memory-removal"
local SOURCE_KEY = "npc:" .. NPC_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Memory Removal NPC",
        identitySeed = 6464,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 190,
        y = 290,
        z = 0,
        identity = {
            seed = 6464,
            displayName = "PZ Harness Memory Removal NPC",
        },
    })
end

local function buildMemory()
    return {
        id = MEMORY_ID,
        type = "native_harness_memory",
        aboutKey = TARGET_KEY,
        createdAt = 930,
        lastEvaluatedAt = 930,
        approvalEffect = 18,
        respectEffect = 7,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
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
        "native NPC registry relationship-memory removal API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC relationship-memory removal record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY
            and entityRef.ForNPC(NPC_ID) == SOURCE_KEY,
        "native relationship-memory removal entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.AddMemory and relationships.RemoveMemory
            and relationships.Get,
        "native relationship-memory removal API was not available"
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
        "native synthetic NPC relationship-memory removal record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC relationship-memory removal record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 24,
            respect = 10,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "neutral",
        "native relationship-memory removal baseline failed: "
            .. tostring(baselineReason)
    )

    local addedMemory, memoryReason, withMemory = relationships.AddMemory(
        NPC_ID,
        TARGET_KEY,
        buildMemory()
    )
    PZHarness.assertTrue(
        addedMemory == true and memoryReason == "added"
            and withMemory and #withMemory.memories == 1
            and withMemory.approval == 42
            and withMemory.respect == 17
            and withMemory.state == "friend"
            and withMemory.revision == 2,
        "native relationship memory setup failed: " .. tostring(memoryReason)
    )

    local removed, removeReason = relationships.RemoveMemory(
        NPC_ID,
        TARGET_KEY,
        MEMORY_ID
    )
    PZHarness.assertTrue(
        removed == true and removeReason == "removed",
        "native relationship memory was not removed: "
            .. tostring(removeReason)
    )
    local afterRemoval = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        afterRemoval and afterRemoval.baselineApproval == 24
            and afterRemoval.baselineRespect == 10
            and afterRemoval.approval == 24
            and afterRemoval.respect == 10
            and afterRemoval.familiarity == 8
            and afterRemoval.state == "neutral"
            and afterRemoval.revision == 3
            and afterRemoval.lastEvaluatedAt == 930
            and #afterRemoval.memories == 0,
        "native relationship memory removal was not recalculated"
    )

    local missing, missingReason = relationships.RemoveMemory(
        NPC_ID,
        TARGET_KEY,
        MEMORY_ID
    )
    PZHarness.assertTrue(
        missing == false and missingReason == "memory_not_found",
        "native relationship missing-memory removal was not rejected"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        stored and #stored.memories == 0
            and stored.approval == 24
            and stored.respect == 10
            and stored.revision == 3,
        "native relationship missing-memory removal changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship memory removal did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_memory_removal_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship-memory removal commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save relationship-memory removal"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native relationship-memory removal record remained dirty after commit"
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
            and raw.identity and raw.identity.seed == 6464
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 24
            and rawRelationship.respect == 10
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "neutral"
            and rawRelationship.revision == 3
            and type(rawRelationship.memories) == "table"
            and #rawRelationship.memories == 0,
        "native relationship ModData did not contain the removal"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship-memory removal OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_MEMORY_REMOVAL_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship-memory removal GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship-memory removal GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship-memory removal GameWindow.save did not trigger OnSave"
        )
    end
end
