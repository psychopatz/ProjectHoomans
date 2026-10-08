-- Target-owned native registry restart fixture, phase two.
-- Read the production registry record after a fresh JVM loads GlobalModData.

local RECORD_ID = "native:pzharness:registry-restart"

PZHarnessNativeTest = function()
    PZHarness.assertTrue(
        PNC and PNC.Registry and PNC.Registry.Get,
        "native registry Get API was not available"
    )
    local record = PNC.Registry.Get(RECORD_ID)
    PZHarness.assertTrue(
        type(record) == "table",
        "native registry record was not reloaded"
    )
    PZHarness.assertEqual(
        record and record.id,
        RECORD_ID,
        "native registry record identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        record and record.name,
        "Native Registry Restart NPC",
        "native registry display identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        record and record.identitySeed,
        5151,
        "native registry identity seed did not survive the JVM restart"
    )
    -- Server startup may mark a loaded record dirty again before the bridge
    -- runs. The raw record and directory pointer below assert the durable
    -- revision; the live record only needs to remain at or above it.
    local loadedRevision = record and tonumber(record.recordRevision) or 0
    PZHarness.assertTrue(
        loadedRevision >= 1,
        "native registry record revision did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        record and record.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "native registry persistence schema did not survive the JVM restart"
    )

    local directory = PNC.Registry.GetStorageDirectory()
    local pointer = directory
        and directory.records
        and directory.records[RECORD_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native registry directory pointer was not reloaded"
    )

    local raw = pointer and ModData.get(pointer.storageKey) or nil
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == RECORD_ID
            and raw.recordRevision == 1,
        "native registry record ModData was not reloaded"
    )
end
