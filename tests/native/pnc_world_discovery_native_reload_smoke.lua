-- Target-owned native world-discovery restart fixture, phase two.
-- Read one player-scoped discovery entity with a synthetic player only.

local ACCOUNT = "pzharness_world_discovery_account"
local UUID = "char_pzharness_world_discovery_restart"
local ENTITY_ID = "settlement_pzharness_world_discovery_restart"
local SOURCE = "native_harness_world_discovery"

local playerData = {
    PNC_CharacterUUID = UUID,
    PNC_CharacterIdentityVersion = 2,
    PNC_CharacterAccountKey = ACCOUNT,
}
local player = {
    getUsername = function() return ACCOUNT end,
    getOnlineID = function() return 92 end,
    getModData = function() return playerData end,
    getDisplayName = function() return "PZ Harness Discovery" end,
    getDescriptor = function()
        return {
            getForename = function() return "Harness" end,
            getSurname = function() return "Discovery" end,
        }
    end,
    getX = function() return 120 end,
    getY = function() return 220 end,
    getZ = function() return 0 end,
}

PZHarnessNativeTest = function()
    local discovery = PNC and PNC.WorldDiscovery or nil
    local types = PNC and PNC.WorldDiscoveryTypes or nil
    PZHarness.assertTrue(
        discovery and discovery.Loaded == true and discovery.Registry
            and discovery.Registry.players and discovery.Internal
            and discovery.Internal.PlayerRecord,
        "native WorldDiscovery was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        types and types.KIND_SETTLEMENT
            and types.PHASE_LOCATED and types.PRESENCE_PRESENT
            and types.ARRIVAL_SEARCHED,
        "native WorldDiscovery types were not available after restart"
    )

    local characterUUID, identityReason =
        PNC.PlayerCharacters.GetCharacterUUID(player)
    PZHarness.assertEqual(
        characterUUID,
        UUID,
        "native synthetic player identity was not recovered: "
            .. tostring(identityReason)
    )
    local record, recordUUID = discovery.Internal.PlayerRecord(player, false)
    PZHarness.assertTrue(
        record and recordUUID == UUID,
        "native WorldDiscovery player record was not resolved"
    )
    local entry = record.entities[types.KIND_SETTLEMENT]
        and record.entities[types.KIND_SETTLEMENT][ENTITY_ID]
    PZHarness.assertTrue(
        entry and entry.entityID == ENTITY_ID
            and entry.kind == types.KIND_SETTLEMENT
            and entry.phase == types.PHASE_LOCATED
            and entry.source == SOURCE
            and entry.x == 321 and entry.y == 654 and entry.z == 0
            and entry.arrivalState == types.ARRIVAL_SEARCHED
            and entry.presenceStatus == types.PRESENCE_PRESENT
            and (tonumber(entry.searchedAt) or 0) >= 0,
        "native WorldDiscovery entity did not survive restart"
    )
    PZHarness.assertTrue(
        discovery.Dirty == false,
        "native WorldDiscovery was unexpectedly dirty after reload"
    )

    local coreAuthority = PNC and PNC.CoreSurvivorWorldAuthority or nil
    local coreRegistry = coreAuthority and coreAuthority.Registry or nil
    local coreDiscovery = coreRegistry and coreRegistry:GetDiscovery() or nil
    local corePlayer = coreDiscovery and coreDiscovery.players
        and coreDiscovery.players[UUID]
    local coreEntity = corePlayer and corePlayer.entities
        and corePlayer.entities.community
        and corePlayer.entities.community[ENTITY_ID]
    PZHarness.assertTrue(
        type(coreEntity) == "table"
            and coreEntity.source == SOURCE,
        "Core SurvivorWorld discovery did not survive restart"
    )
    local retired = ModData.get("PNC_WorldDiscovery_v1")
    PZHarness.assertTrue(
        retired == nil or next(retired) == nil,
        "retired discovery root reappeared after restart"
    )
end
