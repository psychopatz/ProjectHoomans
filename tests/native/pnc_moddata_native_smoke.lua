-- Target-owned native persistence boundary fixture.
-- Exercise the real ModData/GlobalModData APIs and observe the engine save hook.
-- Restart/reload assertions belong to a separate multi-process runner fixture.

local MODDATA_KEY = "PZHarness_Native_ModData"
local GLOBAL_KEY = "PZHarness_Native_GlobalModData"

local function hasTableName(names, expected)
    if names == nil then return false end
    if names.size and names.get then
        for index = 0, names:size() - 1 do
            if tostring(names:get(index)) == expected then return true end
        end
        return false
    end
    for _, name in pairs(names) do
        if tostring(name) == expected then return true end
    end
    return false
end

PZHarnessNativeTest = function()
    local modDataOK, modData = pcall(ModData.getOrCreate, MODDATA_KEY)
    PZHarness.assertTrue(modDataOK, "native ModData.getOrCreate failed")
    PZHarness.assertTrue(type(modData) == "table", "native ModData table was not created")

    if modDataOK and type(modData) == "table" then
        modData.nativeMarker = "moddata-boundary"
        modData.revision = 1
    end
    local fetchedModData = ModData.get(MODDATA_KEY)
    PZHarness.assertTrue(
        type(fetchedModData) == "table"
            and fetchedModData.nativeMarker == "moddata-boundary"
            and fetchedModData.revision == 1,
        "native ModData.get did not return the written table"
    )

    local namesOK, names = pcall(ModData.getTableNames)
    PZHarness.assertTrue(namesOK, "native ModData.getTableNames failed")
    PZHarness.assertTrue(
        namesOK and hasTableName(names, MODDATA_KEY),
        "native ModData table name was not discoverable"
    )

    -- ModData is the supported Lua facade over the engine's GlobalModData
    -- store. Build 42.21 does not expose GlobalModData itself as a Lua class,
    -- so keep the direct save call conditional for runtimes that do expose it.
    local globalOK, globalData = pcall(ModData.getOrCreate, GLOBAL_KEY)
    PZHarness.assertTrue(globalOK, "native GlobalModData-backed getOrCreate failed")
    PZHarness.assertTrue(
        type(globalData) == "table",
        "native GlobalModData-backed table was not created"
    )
    if globalOK and type(globalData) == "table" then
        globalData.nativeMarker = "global-moddata-boundary"
        globalData.revision = 1
    end
    local fetchedGlobalData = ModData.get(GLOBAL_KEY)
    PZHarness.assertTrue(
        type(fetchedGlobalData) == "table"
            and fetchedGlobalData.nativeMarker == "global-moddata-boundary"
            and fetchedGlobalData.revision == 1,
        "native GlobalModData-backed get did not return the written table"
    )

    local directGlobalSaveAvailable = GlobalModData
        and GlobalModData.save ~= nil
    if directGlobalSaveAvailable then
        local saveOK, saveError = pcall(GlobalModData.save)
        PZHarness.assertTrue(
            saveOK,
            "native GlobalModData.save failed: " .. tostring(saveError)
        )
    end
    print(
        "PZ_HARNESS_GLOBALMODDATA_BACKEND:directLuaSave="
            .. tostring(directGlobalSaveAvailable)
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_ON_SAVE_OBSERVED:" .. GLOBAL_KEY)
        end)
    end

    local engineSaveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        engineSaveAvailable,
        "native GameWindow.save path was not available"
    )
    if engineSaveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native GameWindow.save did not trigger OnSave"
        )
    end
end
