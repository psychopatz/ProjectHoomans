-- Target-owned native settlement restart fixture, phase two.
-- Read the exported production base after a fresh JVM loads ModData.

local BASE_ID = "pzharness:settlement-restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.SettlementRepository or nil
    PZHarness.assertTrue(
        repository and repository.State and repository.Loaded == true,
        "native SettlementRepository was not loaded after the JVM restart"
    )

    local loaded = repository.GetBase(BASE_ID)
    PZHarness.assertTrue(
        type(loaded) == "table",
        "native SettlementRepository base was not reloaded"
    )
    PZHarness.assertEqual(
        loaded and loaded.id,
        BASE_ID,
        "native settlement base identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.name,
        "Native Settlement Restart Base",
        "native settlement base name did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.nativeMarker,
        "settlement-restart",
        "native settlement marker did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.revision,
        1,
        "native settlement base revision did not survive the JVM restart"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawBase = raw and raw.bases and raw.bases[BASE_ID]
    PZHarness.assertTrue(
        type(rawBase) == "table"
            and rawBase.id == BASE_ID
            and rawBase.nativeMarker == "settlement-restart"
            and rawBase.revision == 1,
        "native settlement ModData base was not reloaded"
    )
end
