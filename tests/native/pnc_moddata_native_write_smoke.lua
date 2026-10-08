-- Target-owned native restart fixture, phase one.
-- Write a unique engine-backed ModData table and force the real save hook.

local MODDATA_KEY = "PZHarness_Native_Restart_ModData"

PZHarnessNativeTest = function()
    local createOK, data = pcall(ModData.getOrCreate, MODDATA_KEY)
    PZHarness.assertTrue(
        createOK,
        "native restart ModData.getOrCreate failed"
    )
    PZHarness.assertTrue(
        type(data) == "table",
        "native restart ModData table was not created"
    )

    if createOK and type(data) == "table" then
        data.nativeMarker = "restart-write"
        data.revision = 1
        data.payload = {
            source = "pnc_moddata_native_write_smoke",
            stableValue = 4242,
        }
    end

    local fetched = ModData.get(MODDATA_KEY)
    PZHarness.assertTrue(
        type(fetched) == "table"
            and fetched.nativeMarker == "restart-write"
            and fetched.revision == 1
            and type(fetched.payload) == "table"
            and fetched.payload.source == "pnc_moddata_native_write_smoke"
            and fetched.payload.stableValue == 4242,
        "native restart ModData.get did not return the written table"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native restart OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RESTART_WRITE_ON_SAVE:" .. MODDATA_KEY)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native restart GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native restart GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native restart GameWindow.save did not trigger OnSave"
        )
    end
end
