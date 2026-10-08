-- Target-owned native colony-storage restart fixture, phase one.
-- Exercise GetPrimary -> SerializeStorage -> coordinator save.

local FACTION_ID = "pzharness:faction"
local SETTLEMENT_ID = "pzharness:settlement"
local STORAGE_ID = "storage:" .. FACTION_ID .. ":primary"
local TRANSACTION_ID = "pzharness:restart-transaction"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.ColonyStorageRepository or nil
    PZHarness.assertTrue(
        repository and repository.GetPrimary and repository.MarkDirty,
        "native ColonyStorageRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true,
        "native ColonyStorageRepository was not loaded before the test"
    )

    local storage = repository.GetPrimary(FACTION_ID, SETTLEMENT_ID)
    PZHarness.assertTrue(
        type(storage) == "table",
        "native ColonyStorageRepository did not create primary storage"
    )
    PZHarness.assertEqual(
        storage and storage.id,
        STORAGE_ID,
        "native colony storage identity changed"
    )
    PZHarness.assertEqual(
        storage and storage.ownerFactionId,
        FACTION_ID,
        "native colony storage faction identity changed"
    )
    PZHarness.assertEqual(
        storage and storage.settlementId,
        SETTLEMENT_ID,
        "native colony storage settlement identity changed"
    )
    PZHarness.assertTrue(
        storage and type(storage.inventory) == "table",
        "native colony storage did not create a virtual inventory"
    )

    storage.revision = 1
    storage.productionTransactions[TRANSACTION_ID] = {
        state = "committed",
        quantity = 42,
    }
    repository.MarkDirty()
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native ColonyStorageRepository did not retain its dirty state"
    )

    local payload = repository.SerializeStorage(storage)
    PZHarness.assertTrue(
        type(payload) == "table"
            and payload.storageId == STORAGE_ID
            and type(payload.inventorySnapshot) == "table"
            and type(payload.productionTransactions) == "table"
            and type(payload.productionTransactions[TRANSACTION_ID]) == "table"
            and payload.productionTransactions[TRANSACTION_ID].quantity == 42,
        "native colony storage serializer did not retain the transaction"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_colony_storage_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native colony-storage commit failed: "
            .. tostring(commitReason or committed)
    )
    local storageResult = commitDetails
        and commitDetails.results
        and commitDetails.results.colonyStorage
    PZHarness.assertTrue(
        storageResult and storageResult.changed == true,
        "native persistence coordinator did not save ColonyStorageRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native ColonyStorageRepository remained dirty after commit"
    )

    local raw = ModData.get(PNC.ColonyStorageDefinitions.MODDATA_KEY)
    local rawStorage = raw and raw.byID and raw.byID[STORAGE_ID]
    PZHarness.assertTrue(
        type(rawStorage) == "table"
            and rawStorage.storageId == STORAGE_ID
            and rawStorage.revision == 1
            and type(rawStorage.productionTransactions) == "table"
            and type(rawStorage.productionTransactions[TRANSACTION_ID]) == "table"
            and rawStorage.productionTransactions[TRANSACTION_ID].quantity == 42,
        "native colony-storage ModData did not contain the committed storage"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native colony-storage OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_COLONY_STORAGE_WRITE_ON_SAVE:" .. STORAGE_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native colony-storage GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native colony-storage GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native colony-storage GameWindow.save did not trigger OnSave"
        )
    end
end
