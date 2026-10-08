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
        types and types.MODDATA_KEY and types.KIND_SETTLEMENT
            and types.PHASE_LOCATED and types.PRESENCE_PRESENT
            and types.ARRIVAL_SEARCHED,
        "native WorldDiscovery types were not available after restart"
    )
    PZHarness.assertEqual(
        types.MODDATA_KEY,
        "PNC_WorldDiscovery_v1",
        "native WorldDiscovery ModData key was not stable"
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

    local raw = ModData.get(types.MODDATA_KEY)
    local rawPlayer = raw and raw.players and raw.players[UUID]
    local rawEntity = rawPlayer and rawPlayer.entities
        and rawPlayer.entities[types.KIND_SETTLEMENT]
        and rawPlayer.entities[types.KIND_SETTLEMENT][ENTITY_ID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == types.SCHEMA_VERSION
            and type(rawPlayer) == "table"
            and type(rawEntity) == "table"
            and rawEntity.entityID == ENTITY_ID
            and rawEntity.phase == types.PHASE_LOCATED
            and rawEntity.source == SOURCE
            and rawEntity.arrivalState == types.ARRIVAL_SEARCHED
            and rawEntity.presenceStatus == types.PRESENCE_PRESENT,
        "native WorldDiscovery ModData was not reloaded"
    )
end
