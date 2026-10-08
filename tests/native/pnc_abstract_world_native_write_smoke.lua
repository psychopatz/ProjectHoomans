-- Target-owned native abstract-world restart fixture, phase one.
-- Exercise the production AbstractWorldStore through the commit coordinator.

local DEFINITION_ID = "pzharness:abstract-world-restart"

local function entry()
    return {
        definitionId = DEFINITION_ID,
        status = "reserved",
        identitySeed = 6262,
        definitionVersion = 1,
        reservedAt = 0,
        spawnedAt = 0,
        diedAt = 0,
    }
end

PZHarnessNativeTest = function()
    local store = PNC and PNC.AbstractWorldStore or nil
    PZHarness.assertTrue(
        store and store.Registry and store.Touch,
        "native AbstractWorldStore API was not available"
    )
    PZHarness.assertTrue(
        store and store.Loaded == true,
        "native AbstractWorldStore was not loaded before the test"
    )

    local beforeRevision = store and tonumber(store.Registry.revision) or 0
    store.Registry.uniqueNPCsByID[DEFINITION_ID] = entry()
    store.Touch("native_harness_abstract_world_restart")
    PZHarness.assertTrue(
        (tonumber(store.Registry.revision) or 0) > beforeRevision,
        "native AbstractWorldStore.Touch did not advance the revision"
    )
    PZHarness.assertTrue(
        store.Dirty == true,
        "native AbstractWorldStore did not retain its dirty state"
    )

    local stored = store.Registry.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(stored) == "table"
            and stored.definitionId == DEFINITION_ID
            and stored.status == "reserved"
            and stored.identitySeed == 6262,
        "native AbstractWorldStore did not retain the written entry"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_abstract_world_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native abstract-world commit failed: "
            .. tostring(commitReason or committed)
    )
    local abstractResult = commitDetails
        and commitDetails.results
        and commitDetails.results.abstractWorld
    PZHarness.assertTrue(
        abstractResult and abstractResult.changed == true,
        "native persistence coordinator did not save AbstractWorldStore"
    )
    PZHarness.assertTrue(
        store.Dirty == false,
        "native AbstractWorldStore remained dirty after commit"
    )

    local raw = ModData.get(PNC.DirectorConfig.MODDATA_KEY)
    local rawEntry = raw
        and raw.uniqueNPCsByID
        and raw.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(rawEntry) == "table"
            and rawEntry.definitionId == DEFINITION_ID
            and rawEntry.identitySeed == 6262,
        "native abstract-world ModData did not contain the committed entry"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native abstract-world OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_ABSTRACT_WORLD_WRITE_ON_SAVE:" .. DEFINITION_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native abstract-world GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native abstract-world GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native abstract-world GameWindow.save did not trigger OnSave"
        )
    end
end
