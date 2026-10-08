-- Target-owned native world-discovery restart fixture, phase one.
-- Exercise player-scoped discovery persistence with a synthetic player and
-- one already-resolved entity; do not scan the world or use network transfer.

local ACCOUNT = "pzharness_world_discovery_account"
local UUID = "char_pzharness_world_discovery_restart"
local ENTITY_ID = "settlement_pzharness_world_discovery_restart"
local SOURCE = "native_harness_world_discovery"

local playerData = {}
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
        discovery and discovery.SetResolvedPhase
            and discovery.MarkArrived and discovery.Load and discovery.Save
            and discovery.Internal and discovery.Internal.PlayerRecord,
        "native WorldDiscovery API was not available"
    )
    PZHarness.assertTrue(
        types and types.MODDATA_KEY and types.KIND_SETTLEMENT
            and types.PHASE_LOCATED and types.PRESENCE_PRESENT
            and types.ARRIVAL_SEARCHED,
        "native WorldDiscovery types were not available"
    )
    PZHarness.assertTrue(
        discovery.Loaded == true and discovery.Registry
            and discovery.Registry.players,
        "native WorldDiscovery was not loaded before the test"
    )
    PZHarness.assertTrue(
        PNC.PlayerCharacters and PNC.PlayerCharacters.EnsureIdentity
            and PNC.PlayerCharacters.GetCharacterUUID,
        "native player identity service was not available"
    )

    if PNC.PlayerCharacters.UUIDGenerator then
        PNC.PlayerCharacters.UUIDGenerator = function() return UUID end
    end
    local identity, identityReason = PNC.PlayerCharacters.EnsureIdentity(
        player,
        { callback = "native_harness_world_discovery" }
    )
    PZHarness.assertEqual(
        identity,
        UUID,
        "native synthetic player identity was not established: "
            .. tostring(identityReason)
    )
    PZHarness.assertEqual(
        playerData.PNC_CharacterUUID,
        UUID,
        "native synthetic player identity mirror was not written"
    )

    local entity = {
        entityID = ENTITY_ID,
        kind = types.KIND_SETTLEMENT,
        x = 321,
        y = 654,
        z = 0,
    }
    local resolved, resolvedReason = discovery.SetResolvedPhase(
        player,
        entity,
        types.PHASE_LOCATED,
        SOURCE,
        true
    )
    PZHarness.assertTrue(
        resolved and resolved.entityID == ENTITY_ID
            and resolved.phase == types.PHASE_LOCATED
            and resolved.source == SOURCE,
        "native WorldDiscovery phase was not recorded: "
            .. tostring(resolvedReason)
    )
    local arrived, arrivedReason = discovery.MarkArrived(
        player,
        entity,
        types.PRESENCE_PRESENT,
        SOURCE,
        true
    )
    PZHarness.assertTrue(
        arrived and arrived.arrivalState == types.ARRIVAL_SEARCHED
            and arrived.presenceStatus == types.PRESENCE_PRESENT
            and (tonumber(arrived.searchedAt) or 0) >= 0,
        "native WorldDiscovery arrival state was not recorded: "
            .. tostring(arrivedReason)
    )
    PZHarness.assertTrue(
        discovery.Dirty == true,
        "native WorldDiscovery did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_world_discovery_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native WorldDiscovery commit failed: "
            .. tostring(commitReason or committed)
    )
    local discoveryResult = commitDetails
        and commitDetails.results
        and commitDetails.results.worldDiscovery
    PZHarness.assertTrue(
        discoveryResult and discoveryResult.changed == true,
        "native persistence coordinator did not save WorldDiscovery"
    )
    PZHarness.assertTrue(
        discovery.Dirty == false,
        "native WorldDiscovery remained dirty after commit"
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
            and rawEntity.phase == types.PHASE_LOCATED
            and rawEntity.source == SOURCE
            and rawEntity.arrivalState == types.ARRIVAL_SEARCHED
            and rawEntity.presenceStatus == types.PRESENCE_PRESENT,
        "native WorldDiscovery ModData did not contain the entity"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native WorldDiscovery OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_WORLD_DISCOVERY_WRITE_ON_SAVE:"
                .. UUID .. "|" .. ENTITY_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native WorldDiscovery GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native WorldDiscovery GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native WorldDiscovery GameWindow.save did not trigger OnSave"
        )
    end
end
