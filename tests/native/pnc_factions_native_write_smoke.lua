-- Target-owned native faction restart fixture, phase one.
-- Exercise the production faction registry through the commit coordinator.

local FACTION_ID = "faction_pzharness_native_restart"
local FACTION_NAME = "Native Harness Restart Faction"
local MARKER = "faction-restart"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    local constants = PNC and PNC.FactionConstants or nil
    PZHarness.assertTrue(
        factions and factions.Create and factions.Get
            and factions.Save and factions.Load,
        "native Factions API was not available"
    )
    PZHarness.assertTrue(
        factions and factions.Loaded == true,
        "native Factions registry was not loaded before the test"
    )
    PZHarness.assertTrue(
        constants and constants.REGISTRY_MODDATA_KEY,
        "native FactionConstants registry key was not available"
    )

    factions.IDGenerator = function()
        return FACTION_ID
    end
    local created, createReason, faction = factions.Create({
        name = FACTION_NAME,
        archetypeID = "settler",
        createdAt = 42,
        tags = { nativeHarness = MARKER },
    })
    PZHarness.assertTrue(
        created == true and type(faction) == "table",
        "native Factions.Create failed: " .. tostring(createReason)
    )
    PZHarness.assertEqual(
        faction and faction.id,
        FACTION_ID,
        "native faction identity was not created deterministically"
    )
    PZHarness.assertEqual(
        faction and faction.name,
        FACTION_NAME,
        "native faction name was not retained"
    )
    PZHarness.assertEqual(
        faction and faction.archetypeID,
        "settler",
        "native faction archetype was not retained"
    )
    PZHarness.assertEqual(
        faction and faction.status,
        "active",
        "native faction status was not initialized"
    )
    PZHarness.assertEqual(
        faction and faction.tags and faction.tags.nativeHarness,
        MARKER,
        "native faction marker was not retained"
    )
    PZHarness.assertTrue(
        factions.Dirty == true,
        "native Factions registry did not retain its dirty state"
    )

    local queried = factions.Get(FACTION_ID)
    PZHarness.assertTrue(
        type(queried) == "table"
            and queried.id == FACTION_ID
            and queried.name == FACTION_NAME,
        "native Factions.Get did not return the created faction"
    )
    PZHarness.assertTrue(
        factions.Registry and factions.Registry.byArchetype
            and factions.Registry.byArchetype.settler
            and factions.Registry.byArchetype.settler[FACTION_ID] == true,
        "native Factions archetype index did not retain the created faction"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_factions_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native factions commit failed: "
            .. tostring(commitReason or committed)
    )
    local factionResult = commitDetails
        and commitDetails.results
        and commitDetails.results.factions
    PZHarness.assertTrue(
        factionResult and factionResult.changed == true,
        "native persistence coordinator did not save Factions"
    )
    PZHarness.assertTrue(
        factions.Dirty == false,
        "native Factions registry remained dirty after commit"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawFaction = raw and raw.byID and raw.byID[FACTION_ID]
    PZHarness.assertTrue(
        type(rawFaction) == "table"
            and rawFaction.id == FACTION_ID
            and rawFaction.name == FACTION_NAME
            and rawFaction.tags
            and rawFaction.tags.nativeHarness == MARKER,
        "native faction ModData did not contain the committed faction"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native factions OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_FACTIONS_WRITE_ON_SAVE:" .. FACTION_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native factions GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native factions GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native factions GameWindow.save did not trigger OnSave"
        )
    end
end
