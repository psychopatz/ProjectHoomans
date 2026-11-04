-- Target-owned native community restart fixture, phase one.
-- Exercise the production community registry through the commit coordinator.

local FACTION_ID = "faction_pzharness_community_restart"
local COMMUNITY_ID = "community_pzharness_native_restart"
local FACTION_NAME = "Native Harness Community Faction"
local COMMUNITY_NAME = "Native Harness Restart Community"

PZHarnessNativeTest = function()
    local factions = PNC and PNC.Factions or nil
    local communities = PNC and PNC.Communities or nil
    PZHarness.assertTrue(
        factions and factions.Create and factions.Get,
        "native Factions dependency was not available"
    )
    PZHarness.assertTrue(
        communities and communities.Create and communities.Get
            and communities.Commit and communities.Load,
        "native Communities API was not available"
    )
    PZHarness.assertTrue(
        factions.Loaded == true and communities.Loaded == true,
        "native community dependencies were not loaded before the test"
    )
    factions.IDGenerator = function()
        return FACTION_ID
    end
    local factionCreated, factionReason, faction = factions.Create({
        name = FACTION_NAME,
        archetypeID = "settler",
        createdAt = 42,
    })
    PZHarness.assertTrue(
        factionCreated == true and type(faction) == "table",
        "native community dependency faction creation failed: "
            .. tostring(factionReason)
    )
    PZHarness.assertEqual(
        faction and faction.id,
        FACTION_ID,
        "native community dependency faction identity was not retained"
    )

    communities.IDGenerator = function()
        return COMMUNITY_ID
    end
    local created, createReason, community = communities.Create({
        factionID = FACTION_ID,
        name = COMMUNITY_NAME,
        mode = "settled",
        createdAt = 84,
        home = { x = 4242, y = 2424, z = 0, radius = 18 },
        capacity = { population = 17, beds = 8, storage = 123 },
        security = 61,
        morale = 27,
    })
    PZHarness.assertTrue(
        created == true and type(community) == "table",
        "native Communities.Create failed: " .. tostring(createReason)
    )
    PZHarness.assertEqual(
        community and community.id,
        COMMUNITY_ID,
        "native community identity was not created deterministically"
    )
    PZHarness.assertEqual(
        community and community.name,
        COMMUNITY_NAME,
        "native community name was not retained"
    )
    PZHarness.assertEqual(
        community and community.factionID,
        FACTION_ID,
        "native community faction identity was not retained"
    )
    PZHarness.assertEqual(
        community and community.mode,
        "settled",
        "native community mode was not retained"
    )
    PZHarness.assertEqual(
        community and community.status,
        "active",
        "native community status was not initialized"
    )
    PZHarness.assertEqual(
        community and community.home and community.home.x,
        4242,
        "native community home X was not retained"
    )
    PZHarness.assertEqual(
        community and community.home and community.home.y,
        2424,
        "native community home Y was not retained"
    )
    PZHarness.assertEqual(
        community and community.home and community.home.radius,
        18,
        "native community home radius was not retained"
    )
    PZHarness.assertEqual(
        community and community.capacity
            and community.capacity.population,
        17,
        "native community population capacity was not retained"
    )
    PZHarness.assertEqual(
        community and community.security,
        61,
        "native community security was not retained"
    )
    PZHarness.assertEqual(
        community and community.morale,
        27,
        "native community morale was not retained"
    )
    PZHarness.assertTrue(
        communities.Dirty == true,
        "native Communities registry did not retain its dirty state"
    )

    local queried = communities.Get(COMMUNITY_ID)
    PZHarness.assertTrue(
        type(queried) == "table"
            and queried.id == COMMUNITY_ID
            and queried.name == COMMUNITY_NAME,
        "native Communities.Get did not return the created community"
    )
    PZHarness.assertTrue(
        communities.Registry and communities.Registry.byFaction
            and communities.Registry.byFaction[FACTION_ID]
            and communities.Registry.byFaction[FACTION_ID][COMMUNITY_ID]
                == true,
        "native Communities faction index did not retain the community"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_communities_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native communities commit failed: "
            .. tostring(commitReason or committed)
    )
    local factionResult = commitDetails
        and commitDetails.results
        and commitDetails.results.factions
    PZHarness.assertTrue(
        factionResult and factionResult.changed == true,
        "native community dependency faction was not saved"
    )
    local communityResult = commitDetails
        and commitDetails.results
        and commitDetails.results.communities
    PZHarness.assertTrue(
        communityResult and communityResult.changed == true,
        "native persistence coordinator did not save Communities"
    )
    PZHarness.assertTrue(
        communities.Dirty == false,
        "native Communities registry remained dirty after commit"
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
        "Core SurvivorWorld did not contain the committed community"
    )
    for _, key in ipairs({ "PNC_Factions", "PNC_Communities" }) do
        local retired = ModData.get(key)
        PZHarness.assertTrue(
            retired == nil
            or (PNC.ModDataStore
                and PNC.ModDataStore.IsEmpty
                and PNC.ModDataStore.IsEmpty(retired)),
            "retired generic root became active again: " .. key
        )
    end

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native communities OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_COMMUNITIES_WRITE_ON_SAVE:" .. COMMUNITY_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native communities GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native communities GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native communities GameWindow.save did not trigger OnSave"
        )
    end
end
