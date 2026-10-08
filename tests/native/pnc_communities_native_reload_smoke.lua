-- Target-owned native community restart fixture, phase two.
-- Read the production community registry after a fresh JVM loads ModData.

local FACTION_ID = "faction_pzharness_community_restart"
local COMMUNITY_ID = "community_pzharness_native_restart"
local FACTION_NAME = "Native Harness Community Faction"
local COMMUNITY_NAME = "Native Harness Restart Community"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    local communities = PNC and PNC.Communities or nil
    local factionConstants = PNC and PNC.FactionConstants or nil
    local communityConstants = PNC and PNC.CommunityConstants or nil
    PZHarness.assertTrue(
        factions and factions.Get and factions.Registry
            and communities and communities.Get and communities.Registry,
        "native community registries were not available after the JVM restart"
    )
    PZHarness.assertTrue(
        factions.Loaded == true and communities.Loaded == true,
        "native community registries were not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        factionConstants and factionConstants.REGISTRY_MODDATA_KEY
            and communityConstants
            and communityConstants.REGISTRY_MODDATA_KEY,
        "native community registry keys were not available after restart"
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

    local raw = ModData.get(communityConstants.REGISTRY_MODDATA_KEY)
    local rawCommunity = raw
        and raw.byID
        and raw.byID[COMMUNITY_ID]
    PZHarness.assertTrue(
        type(rawCommunity) == "table"
            and rawCommunity.id == COMMUNITY_ID
            and rawCommunity.name == COMMUNITY_NAME
            and rawCommunity.factionID == FACTION_ID
            and rawCommunity.home
            and rawCommunity.home.x == 4242
            and rawCommunity.home.y == 2424,
        "native community ModData was not reloaded"
    )
end
