-- Target-owned native registry restart fixture, phase one.
-- Exercise AddRecord -> PersistenceCoordinator.Commit -> engine save.

local RECORD_ID = "native:pzharness:registry-restart"

local function buildRecord()
    return {
        id = RECORD_ID,
        name = "Native Registry Restart NPC",
        identitySeed = 5151,
        archetypeID = "Scavenger",
        tacticalClass = "hostile",
        x = 31,
        y = 47,
        z = 0,
        health = {
            current = 82,
            max = 100,
            state = "normal",
        },
        identity = {
            seed = 5151,
            archetypeID = "Scavenger",
            displayName = "Native Registry Restart NPC",
        },
        equipmentPoolID = "Default",
        equipmentSpawnMode = "none",
        equipment = { worn = {}, attached = {} },
        runtime = {},
    }
end

PZHarnessNativeTest = function()
    PZHarness.assertTrue(
        PNC and PNC.Registry and PNC.Registry.AddRecord,
        "native registry AddRecord API was not available"
    )

    local record = buildRecord()
    local addOK, added = pcall(PNC.Registry.AddRecord, record)
    PZHarness.assertTrue(addOK and added, "native registry AddRecord failed")

    local stored = PNC.Registry.Get(RECORD_ID)
    PZHarness.assertTrue(
        type(stored) == "table",
        "native registry did not return the added record"
    )
    PZHarness.assertEqual(
        stored and stored.id,
        RECORD_ID,
        "native registry changed the record identity"
    )
    PZHarness.assertEqual(
        stored and stored.recordRevision,
        1,
        "native registry did not mark the new record dirty"
    )
    PZHarness.assertTrue(
        PNC.Registry.DirtyByID
            and PNC.Registry.DirtyByID[RECORD_ID] == true,
        "native registry did not retain the dirty record"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_registry_restart"
    )
    PZHarness.assertTrue(
        commitOK,
        "native persistence coordinator raised: " .. tostring(committed)
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native persistence coordinator rejected registry commit: "
            .. tostring(commitReason)
    )

    local directory = PNC.Registry.GetStorageDirectory()
    local pointer = directory
        and directory.records
        and directory.records[RECORD_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native registry directory did not retain the committed record pointer"
    )
    PZHarness.assertTrue(
        PNC.Registry.DirtyByID[RECORD_ID] == nil,
        "native registry retained a dirty record after commit"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native registry OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_REGISTRY_WRITE_ON_SAVE:" .. RECORD_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native registry GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native registry GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native registry GameWindow.save did not trigger OnSave"
        )
    end
end
