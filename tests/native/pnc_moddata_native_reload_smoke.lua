-- Target-owned native restart fixture, phase two.
-- Read the table written by pnc_moddata_native_write_smoke.lua after a JVM restart.

local MODDATA_KEY = "PZHarness_Native_Restart_ModData"

PZHarnessNativeTest = function()
    local fetched = ModData.get(MODDATA_KEY)
    PZHarness.assertTrue(
        type(fetched) == "table",
        "native restart ModData table was not reloaded"
    )
    PZHarness.assertEqual(
        fetched and fetched.nativeMarker,
        "restart-write",
        "native restart ModData marker did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        fetched and fetched.revision,
        1,
        "native restart ModData revision did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        fetched
            and type(fetched.payload) == "table"
            and fetched.payload.source == "pnc_moddata_native_write_smoke"
            and fetched.payload.stableValue == 4242,
        "native restart ModData payload did not survive the JVM restart"
    )
end
