-- Target-owned native abstract-world restart fixture, phase two.
-- Read the normalized production registry after a fresh JVM loads ModData.

local DEFINITION_ID = "pzharness:abstract-world-restart"

PZHarnessNativeTest = function()
    local store = PNC and PNC.AbstractWorldStore or nil
    PZHarness.assertTrue(
        store and store.Registry and store.Loaded == true,
        "native AbstractWorldStore was not loaded after the JVM restart"
    )

    local loaded = store
        and store.Registry.uniqueNPCsByID
        and store.Registry.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(loaded) == "table",
        "native AbstractWorldStore entry was not reloaded"
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

    local raw = ModData.get(PNC.DirectorConfig.MODDATA_KEY)
    local rawEntry = raw
        and raw.uniqueNPCsByID
        and raw.uniqueNPCsByID[DEFINITION_ID]
    PZHarness.assertTrue(
        type(rawEntry) == "table"
            and rawEntry.definitionId == DEFINITION_ID
            and rawEntry.status == "reserved"
            and rawEntry.identitySeed == 6262,
        "native abstract-world ModData entry was not reloaded"
    )
end
