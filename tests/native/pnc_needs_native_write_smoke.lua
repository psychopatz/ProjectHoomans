-- Target-owned native needs restart fixture, phase one.
-- Exercise synthetic non-player needs state without a player or network.

local RECORD_ID = "npc_pzharness_needs_restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.NeedsRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Save
            and repository.Load and repository.MarkDirty,
        "native NeedsRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true,
        "native NeedsRepository was not loaded before the test"
    )
    PZHarness.assertTrue(
        repository and repository.MODDATA_KEY,
        "native NeedsRepository ModData key was not available"
    )

    local state = repository.Get(RECORD_ID, true)
    PZHarness.assertTrue(
        type(state) == "table" and type(state.needs) == "table",
        "native NeedsRepository did not create synthetic NPC state"
    )
    state.needs.hunger = 0.73
    state.needs.thirst = 0.41
    state.needs.fatigue = 0.29
    state.hungerOverflow = 1.25
    state.nutrition = {
        calories = 1234,
        carbohydrates = 12,
        proteins = 23,
        lipids = 34,
        weight = 72.5,
    }
    state.morale = {
        conditions = {
            steady = { value = 0.25, days = 3 },
        },
        lastDay = 12,
    }
    repository.MarkDirty()
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native NeedsRepository did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_needs_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native needs commit failed: "
            .. tostring(commitReason or committed)
    )
    local needsResult = commitDetails
        and commitDetails.results
        and commitDetails.results.needs
    PZHarness.assertTrue(
        needsResult and needsResult.changed == true,
        "native persistence coordinator did not save NeedsRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native NeedsRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local packed = raw and raw.n and raw.n[RECORD_ID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.v == 2
            and type(packed) == "table"
            and packed[1] == 730
            and packed[2] == 410
            and packed[3] == 290
            and packed[12] == 1250,
        "native needs ModData did not contain the encoded state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native needs OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_NEEDS_WRITE_ON_SAVE:" .. RECORD_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native needs GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native needs GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native needs GameWindow.save did not trigger OnSave"
        )
    end
end
