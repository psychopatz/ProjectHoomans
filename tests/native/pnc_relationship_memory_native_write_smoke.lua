-- Target-owned native relationship-memory restart fixture, phase one.
-- Exercise one synthetic memory and duplicate-ID protection.

local NPC_ID = "npc_pzharness_relationship_memory_restart"
local TARGET_ID = "npc_pzharness_relationship_memory_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-memory-restart"
local SOURCE_KEY = "npc:" .. NPC_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Memory NPC",
        identitySeed = 6363,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 180,
        y = 280,
        z = 0,
        identity = {
            seed = 6363,
            displayName = "PZ Harness Memory NPC",
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
        "native NPC registry relationship-memory API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC relationship-memory record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY
            and entityRef.ForNPC(NPC_ID) == SOURCE_KEY,
        "native relationship-memory entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.AddMemory and relationships.Get,
        "native relationship-memory API was not available"
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
        "native synthetic NPC relationship-memory record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC relationship-memory record was not registered"
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
        "native relationship-memory baseline failed: "
            .. tostring(baselineReason)
    )

    local memory = buildMemory()
    local addedMemory, memoryReason, relationship = relationships.AddMemory(
        NPC_ID,
        TARGET_KEY,
        memory
    )
    PZHarness.assertTrue(
        addedMemory == true and memoryReason == "added"
            and relationship,
        "native relationship memory was not added: "
            .. tostring(memoryReason)
    )
    PZHarness.assertTrue(
        relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 24
            and relationship.baselineRespect == 10
            and relationship.approval == 42
            and relationship.respect == 17
            and relationship.familiarity == 8
            and relationship.state == "friend"
            and relationship.revision == 2
            and relationship.lastEvaluatedAt == 930
            and #relationship.memories == 1,
        "native relationship-memory relationship was not recalculated"
    )
    local storedMemory = relationship.memories[1]
    PZHarness.assertTrue(
        storedMemory and storedMemory.id == MEMORY_ID
            and storedMemory.type == "native_harness_memory"
            and storedMemory.aboutKey == TARGET_KEY
            and storedMemory.createdAt == 930
            and storedMemory.lastEvaluatedAt == 930
            and storedMemory.approvalEffect == 18
            and storedMemory.respectEffect == 7
            and storedMemory.strength == 1
            and storedMemory.decayPerDay == 0
            and storedMemory.permanent == true
            and storedMemory.shareable == true
            and storedMemory.knowledgeSource == "experienced"
            and storedMemory.sourceKey == SOURCE_KEY
            and storedMemory.tags.native_harness == true,
        "native relationship memory was not normalized"
    )

    local duplicate, duplicateReason = relationships.AddMemory(
        NPC_ID,
        TARGET_KEY,
        {
            id = MEMORY_ID,
            type = "duplicate_memory",
            aboutKey = TARGET_KEY,
            createdAt = 931,
            approvalEffect = 99,
            respectEffect = 99,
        }
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_memory_id",
        "native relationship-memory duplicate ID was not rejected"
    )
    local afterDuplicate = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        afterDuplicate and #afterDuplicate.memories == 1
            and afterDuplicate.memories[1].id == MEMORY_ID
            and afterDuplicate.approval == 42
            and afterDuplicate.respect == 17
            and afterDuplicate.revision == 2,
        "native relationship-memory duplicate changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship memory did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_memory_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship-memory commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save relationship memory"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native relationship-memory record remained dirty after commit"
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
            and raw.identity and raw.identity.seed == 6363
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 42
            and rawRelationship.respect == 17
            and rawRelationship.revision == 2
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.createdAt == 930
            and rawMemory.lastEvaluatedAt == 930
            and rawMemory.approvalEffect == 18
            and rawMemory.respectEffect == 7
            and rawMemory.permanent == true
            and rawMemory.sourceKey == SOURCE_KEY
            and rawMemory.tags
            and rawMemory.tags.native_harness == true,
        "native relationship ModData did not contain the memory"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship-memory OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_MEMORY_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship-memory GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship-memory GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship-memory GameWindow.save did not trigger OnSave"
        )
    end
end
