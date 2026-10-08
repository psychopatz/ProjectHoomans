-- Target-owned native colony-storage restart fixture, phase two.
-- Read the hydrated production storage after a fresh JVM loads ModData.

local FACTION_ID = "pzharness:faction"
local SETTLEMENT_ID = "pzharness:settlement"
local STORAGE_ID = "storage:" .. FACTION_ID .. ":primary"
local TRANSACTION_ID = "pzharness:restart-transaction"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.ColonyStorageRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Loaded == true,
        "native ColonyStorageRepository was not loaded after the JVM restart"
    )

    local storage = repository.Get(STORAGE_ID)
    PZHarness.assertTrue(
        type(storage) == "table",
        "native colony storage was not reloaded"
    )
    PZHarness.assertEqual(
        storage and storage.id,
        STORAGE_ID,
        "native colony storage identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        storage and storage.ownerFactionId,
        FACTION_ID,
        "native colony storage faction did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        storage and storage.settlementId,
        SETTLEMENT_ID,
        "native colony storage settlement did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        storage and storage.revision,
        1,
        "native colony storage revision did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        storage and type(storage.inventory) == "table"
            and type(storage.productionTransactions) == "table"
            and type(storage.productionTransactions[TRANSACTION_ID]) == "table"
            and storage.productionTransactions[TRANSACTION_ID].quantity == 42,
        "native colony storage transaction did not survive the JVM restart"
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
        "native colony-storage ModData was not reloaded"
    )
end
