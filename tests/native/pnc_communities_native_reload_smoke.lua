-- Target-owned native community restart fixture, phase two.
-- Read the production community registry after a fresh JVM loads ModData.

local FACTION_ID = "faction_pzharness_community_restart"
local COMMUNITY_ID = "community_pzharness_native_restart"
local FACTION_NAME = "Native Harness Community Faction"
local COMMUNITY_NAME = "Native Harness Restart Community"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    local communities = PNC and PNC.Communities or nil
    PZHarness.assertTrue(
        factions and factions.Get and factions.Registry
            and communities and communities.Get and communities.Registry,
        "native community registries were not available after the JVM restart"
    )
    PZHarness.assertTrue(
        factions.Loaded == true and communities.Loaded == true,
        "native community registries were not loaded after the JVM restart"
    )
    local faction = factions.Get(FACTION_ID)
    PZHarness.assertTrue(
        type(faction) == "table",
        "native community dependency faction did not reload"
    )
    PZHarness.assertEqual(
        faction and faction.id,
        FACTION_ID,
        "native community dependency faction identity did not survive restart"
    )
    PZHarness.assertEqual(
        faction and faction.name,
        FACTION_NAME,
        "native community dependency faction name did not survive restart"
    )

    local loaded = communities.Get(COMMUNITY_ID)
    PZHarness.assertTrue(
        type(loaded) == "table",
        "native Communities registry did not reload the created community"
    )
    PZHarness.assertEqual(
        loaded and loaded.id,
        COMMUNITY_ID,
        "native community identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.name,
        COMMUNITY_NAME,
        "native community name did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.factionID,
        FACTION_ID,
        "native community faction identity did not survive restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.mode,
        "settled",
        "native community mode did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.status,
        "active",
        "native community status did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.home and loaded.home.x,
        4242,
        "native community home X did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.home and loaded.home.y,
        2424,
        "native community home Y did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.home and loaded.home.radius,
        18,
        "native community home radius did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.capacity
            and loaded.capacity.population,
        17,
        "native community population capacity did not survive restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.security,
        61,
        "native community security did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        loaded and loaded.morale,
        27,
        "native community morale did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        communities.Registry.byFaction
            and communities.Registry.byFaction[FACTION_ID]
            and communities.Registry.byFaction[FACTION_ID][COMMUNITY_ID]
                == true,
        "native Communities faction index did not reload the community"
    )

    local coreAuthority = PNC and PNC.CoreSurvivorWorldAuthority or nil
    local coreRegistry = coreAuthority and coreAuthority.Registry or nil
    local coreCommunity = coreRegistry
        and coreRegistry:GetCommunity(COMMUNITY_ID) or nil
    PZHarness.assertTrue(
        type(coreCommunity) == "table"
            and coreCommunity.id == COMMUNITY_ID
            and coreCommunity.name == COMMUNITY_NAME
            and coreCommunity.factionID == FACTION_ID,
        "Core SurvivorWorld community did not survive restart"
    )
    for _, key in ipairs({ "PNC_Factions", "PNC_Communities" }) do
        local retired = ModData.get(key)
        PZHarness.assertTrue(
            retired == nil
            or (PNC.ModDataStore
                and PNC.ModDataStore.IsEmpty
                and PNC.ModDataStore.IsEmpty(retired)),
            "retired generic root reappeared after restart: " .. key
        )
    end
end
