-- Target-owned native relationship target-key migration fixture, phase one.
-- Exercise an old NPC key moving to a canonical NPC key.

local NPC_ID = "npc_pzharness_relationship_target_migration_restart"
local LEGACY_TARGET_ID = "npc_pzharness_relationship_target_legacy"
local CANONICAL_TARGET_ID = "npc_pzharness_relationship_target_canonical"
local LEGACY_TARGET_KEY = "npc:" .. LEGACY_TARGET_ID
local CANONICAL_TARGET_KEY = "npc:" .. CANONICAL_TARGET_ID
local MEMORY_ID = "memory:pzharness:relationship-target-migration"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Target Migration NPC",
        identitySeed = 6767,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 220,
        y = 320,
        z = 0,
        identity = {
            seed = 6767,
            displayName = "PZ Harness Target Migration NPC",
        },
    })
end

local function buildMemory()
    return {
        id = MEMORY_ID,
        type = "native_harness_memory",
        aboutKey = LEGACY_TARGET_KEY,
        createdAt = 900,
        lastEvaluatedAt = 900,
        approvalEffect = 18,
        respectEffect = 7,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        shareable = true,
        knowledgeSource = "experienced",
        sourceKey = LEGACY_TARGET_KEY,
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
        "native NPC registry target-migration API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC target-migration record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(LEGACY_TARGET_ID) == LEGACY_TARGET_KEY
            and entityRef.ForNPC(CANONICAL_TARGET_ID) == CANONICAL_TARGET_KEY,
        "native relationship target-migration entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.SetInitialBaseline
            and relationships.AddMemory and relationships.MigrateTargetKey
            and relationships.Get,
        "native relationship target-migration API was not available"
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
        "native synthetic NPC target-migration record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC target-migration record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        LEGACY_TARGET_KEY,
        {
            approval = 22,
            respect = 9,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "neutral",
        "native relationship target-migration baseline failed: "
            .. tostring(baselineReason)
    )

    local addedMemory, memoryReason, legacyRelationship =
        relationships.AddMemory(
            NPC_ID,
            LEGACY_TARGET_KEY,
            buildMemory()
        )
    PZHarness.assertTrue(
        addedMemory == true and memoryReason == "added"
            and legacyRelationship and legacyRelationship.targetID
                == LEGACY_TARGET_ID
            and legacyRelationship.approval == 40
            and legacyRelationship.respect == 16
            and legacyRelationship.state == "friend"
            and legacyRelationship.revision == 2
            and #legacyRelationship.memories == 1
            and legacyRelationship.memories[1].aboutKey == LEGACY_TARGET_KEY
            and legacyRelationship.memories[1].sourceKey == LEGACY_TARGET_KEY,
        "native legacy relationship target setup failed: "
            .. tostring(memoryReason)
    )

    local migrated, migrateReason, canonicalRelationship =
        relationships.MigrateTargetKey(
            NPC_ID,
            LEGACY_TARGET_KEY,
            CANONICAL_TARGET_KEY,
            1000
        )
    PZHarness.assertTrue(
        migrated == true and migrateReason == "migrated"
            and canonicalRelationship,
        "native relationship target migration failed: "
            .. tostring(migrateReason)
    )
    local migratedMemory = canonicalRelationship.memories[1]
    PZHarness.assertTrue(
        canonicalRelationship.targetKind == "npc"
            and canonicalRelationship.targetID == CANONICAL_TARGET_ID
            and canonicalRelationship.baselineApproval == 22
            and canonicalRelationship.baselineRespect == 9
            and canonicalRelationship.approval == 40
            and canonicalRelationship.respect == 16
            and canonicalRelationship.familiarity == 8
            and canonicalRelationship.state == "friend"
            and canonicalRelationship.revision == 3
            and canonicalRelationship.lastEvaluatedAt == 900
            and #canonicalRelationship.memories == 1
            and migratedMemory and migratedMemory.id == MEMORY_ID
            and migratedMemory.aboutKey == CANONICAL_TARGET_KEY
            and migratedMemory.sourceKey == CANONICAL_TARGET_KEY,
        "native relationship target migration was not normalized"
    )
    PZHarness.assertTrue(
        record.social.relationships[LEGACY_TARGET_KEY] == nil
            and type(record.social.relationships[CANONICAL_TARGET_KEY])
                == "table"
            and record.social.relationships[CANONICAL_TARGET_KEY].targetID
                == CANONICAL_TARGET_ID,
        "native relationship target migration did not replace the legacy key"
    )

    local sameTarget, sameTargetReason = relationships.MigrateTargetKey(
        NPC_ID,
        CANONICAL_TARGET_KEY,
        CANONICAL_TARGET_KEY,
        1001
    )
    PZHarness.assertTrue(
        sameTarget == true and sameTargetReason == "same_target_key",
        "native same-target migration was not idempotent"
    )
    local missingSource, missingSourceReason = relationships.MigrateTargetKey(
        NPC_ID,
        LEGACY_TARGET_KEY,
        CANONICAL_TARGET_KEY,
        1001
    )
    PZHarness.assertTrue(
        missingSource == false and missingSourceReason == "source_not_found",
        "native migrated legacy target was still available"
    )
    local stored = relationships.Get(NPC_ID, CANONICAL_TARGET_KEY)
    PZHarness.assertTrue(
        stored and stored.targetID == CANONICAL_TARGET_ID
            and stored.revision == 3
            and stored.approval == 40
            and stored.respect == 16
            and #stored.memories == 1
            and stored.memories[1].aboutKey == CANONICAL_TARGET_KEY
            and stored.memories[1].sourceKey == CANONICAL_TARGET_KEY,
        "native repeated relationship target migration changed durable state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID and registry.DirtyByID[NPC_ID] == true,
        "native relationship target migration did not retain NPC dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_target_migration_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native relationship target-migration commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save relationship target migration"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native relationship target-migration record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationships = raw and raw.social and raw.social.relationships
    local rawRelationship = rawRelationships
        and rawRelationships[CANONICAL_TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 6767
            and type(rawRelationships) == "table"
            and rawRelationships[LEGACY_TARGET_KEY] == nil
            and type(rawRelationship) == "table"
            and rawRelationship.targetID == CANONICAL_TARGET_ID
            and rawRelationship.approval == 40
            and rawRelationship.respect == 16
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 3
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == CANONICAL_TARGET_KEY
            and rawMemory.sourceKey == CANONICAL_TARGET_KEY,
        "native relationship ModData did not contain the migrated key"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native relationship target-migration OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RELATIONSHIP_TARGET_MIGRATION_WRITE_ON_SAVE:" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native relationship target-migration GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native relationship target-migration GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native relationship target-migration GameWindow.save did not trigger OnSave"
        )
    end
end
