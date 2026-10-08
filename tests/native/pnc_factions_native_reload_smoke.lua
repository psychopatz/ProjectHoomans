-- Target-owned native faction restart fixture, phase two.
-- Read the production faction registry after a fresh JVM loads ModData.

local FACTION_ID = "faction_pzharness_native_restart"
local FACTION_NAME = "Native Harness Restart Faction"
local MARKER = "faction-restart"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    local constants = PNC and PNC.FactionConstants or nil
    PZHarness.assertTrue(
        factions and factions.Registry and factions.Get,
        "native Factions API was not available after the JVM restart"
    )
    PZHarness.assertTrue(
        factions.Loaded == true,
        "native Factions registry was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        constants and constants.REGISTRY_MODDATA_KEY,
        "native FactionConstants registry key was not available"
    )

    local loaded = factions.Get(FACTION_ID)
    PZHarness.assertTrue(
        type(loaded) == "table",
        "native Factions registry did not reload the created faction"
    )
    PZHarness.assertEqual(
        loaded and loaded.id,
        FACTION_ID,
        "native faction identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.name,
        FACTION_NAME,
        "native faction name did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.archetypeID,
        "settler",
        "native faction archetype did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.status,
        "active",
        "native faction status did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.tags and loaded.tags.nativeHarness,
        MARKER,
        "native faction marker did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        factions.Registry.byArchetype
            and factions.Registry.byArchetype.settler
            and factions.Registry.byArchetype.settler[FACTION_ID] == true,
        "native Factions archetype index did not reload the faction"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawFaction = raw and raw.byID and raw.byID[FACTION_ID]
    PZHarness.assertTrue(
        type(rawFaction) == "table"
            and rawFaction.id == FACTION_ID
            and rawFaction.name == FACTION_NAME
            and rawFaction.tags
            and rawFaction.tags.nativeHarness == MARKER,
        "native faction ModData was not reloaded"
    )
end
