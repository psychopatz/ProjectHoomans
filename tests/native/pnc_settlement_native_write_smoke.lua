-- Target-owned native settlement restart fixture, phase one.
-- Exercise the production SettlementRepository through the commit coordinator.

local BASE_ID = "pzharness:settlement-restart"

local function base()
    return {
        id = BASE_ID,
        name = "Native Settlement Restart Base",
        ownerType = "projecthoomans.base",
        colonyId = "pzharness:colony",
        nativeMarker = "settlement-restart",
        revision = 1,
    }
end

PZHarnessNativeTest = function()
    local repository = PNC and PNC.SettlementRepository or nil
    PZHarness.assertTrue(
        repository and repository.State and repository.MarkDirty,
        "native SettlementRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true,
        "native SettlementRepository was not loaded before the test"
    )

    repository.State.bases[BASE_ID] = base()
    repository.MarkDirty()
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native SettlementRepository did not retain its dirty state"
    )
    local stored = repository.GetBase(BASE_ID)
    PZHarness.assertTrue(
        type(stored) == "table"
            and stored.id == BASE_ID
            and stored.nativeMarker == "settlement-restart",
        "native SettlementRepository did not retain the written base"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_settlement_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native settlement commit failed: "
            .. tostring(commitReason or committed)
    )
    local settlementResult = commitDetails
        and commitDetails.results
        and commitDetails.results.settlements
    PZHarness.assertTrue(
        settlementResult and settlementResult.changed == true,
        "native persistence coordinator did not save SettlementRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native SettlementRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawBase = raw and raw.bases and raw.bases[BASE_ID]
    PZHarness.assertTrue(
        type(rawBase) == "table"
            and rawBase.id == BASE_ID
            and rawBase.nativeMarker == "settlement-restart",
        "native settlement ModData did not contain the committed base"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native settlement OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_SETTLEMENT_WRITE_ON_SAVE:" .. BASE_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native settlement GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native settlement GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native settlement GameWindow.save did not trigger OnSave"
        )
    end
end
