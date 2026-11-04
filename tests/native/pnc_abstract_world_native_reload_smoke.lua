-- Target-owned native abstract-world restart fixture, phase two.
-- Read the normalized production registry after a fresh JVM loads ModData.

local DEFINITION_ID = "pzharness:abstract-world-restart"

PZHarnessNativeTest = function()
    local store = PNC and PNC.HoomansWorldView or nil
    PZHarness.assertTrue(
        store and store.Registry and store.Loaded == true,
        "native HoomansWorldView was not loaded after the JVM restart"
    )

    local loaded = store
        and store.Registry.uniqueNPCsByID
        and store.Registry.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(loaded) == "table",
        "native HoomansWorldView entry was not reloaded"
    )
    PZHarness.assertEqual(
        loaded and loaded.definitionId,
        DEFINITION_ID,
        "native abstract-world definition identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.status,
        "reserved",
        "native abstract-world status did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.identitySeed,
        6262,
        "native abstract-world identity seed did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        (tonumber(store.Registry.revision) or 0) >= 1,
        "native abstract-world revision did not survive the JVM restart"
    )

    local extensionKey = PNC.SurvivorWorldExtensions
        and PNC.SurvivorWorldExtensions.STORAGE_KEY
    local raw = extensionKey and ModData.get(extensionKey) or nil
    local rawEntry = raw and raw.abstract
        and raw.abstract.uniqueNPCsByID
        and raw.abstract.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(rawEntry) == "table"
            and rawEntry.definitionId == DEFINITION_ID
            and rawEntry.status == "reserved"
            and rawEntry.identitySeed == 6262,
        "Hoomans extension entry was not reloaded"
    )
    local retired = ModData.get("PNC_AbstractWorld_v1")
    PZHarness.assertTrue(
        retired == nil
            or (PNC.ModDataStore
                and PNC.ModDataStore.IsEmpty
                and PNC.ModDataStore.IsEmpty(retired)),
        "retired abstract-world root reappeared after restart"
    )
end
