-- Target-owned native faction restart fixture, phase two.
-- Read the production faction registry after a fresh JVM loads ModData.

local FACTION_ID = "faction_pzharness_native_restart"
local FACTION_NAME = "Native Harness Restart Faction"
local MARKER = "faction-restart"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    PZHarness.assertTrue(
        factions and factions.Registry and factions.Get,
        "native Factions API was not available after the JVM restart"
    )
    PZHarness.assertTrue(
        factions.Loaded == true,
        "native Factions registry was not loaded after the JVM restart"
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

    local coreAuthority = PNC and PNC.CoreSurvivorWorldAuthority or nil
    local coreRegistry = coreAuthority and coreAuthority.Registry or nil
    local coreFaction = coreRegistry and coreRegistry:GetFaction(FACTION_ID) or nil
    PZHarness.assertTrue(
        type(coreFaction) == "table"
            and coreFaction.id == FACTION_ID
            and coreFaction.name == FACTION_NAME,
        "Core SurvivorWorld faction did not survive restart"
    )
    local retired = ModData.get("PNC_Factions")
    PZHarness.assertTrue(
        retired == nil
            or (PNC.ModDataStore
                and PNC.ModDataStore.IsEmpty
                and PNC.ModDataStore.IsEmpty(retired)),
        "retired PNC faction root reappeared after restart"
    )
end
