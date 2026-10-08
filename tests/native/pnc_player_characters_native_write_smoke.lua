-- Target-owned native player-character restart fixture, phase one.
-- Exercise deterministic identity creation and registry persistence with a
-- synthetic server-side player only.

local ACCOUNT = "pzharness_player_characters_account"
local UUID = "char_pzharness_player_characters_restart"

local playerData = {}
local player = {
    getUsername = function() return ACCOUNT end,
    getOnlineID = function() return 93 end,
    getModData = function() return playerData end,
    getDisplayName = function() return "PZ Harness Identity" end,
    getDescriptor = function()
        return {
            getForename = function() return "Harness" end,
            getSurname = function() return "Identity" end,
        }
    end,
    getX = function() return 130 end,
    getY = function() return 230 end,
    getZ = function() return 0 end,
}

PZHarnessNativeTest = function()
    local characters = PNC and PNC.PlayerCharacters or nil
    local constants = PNC and PNC.PlayerCharacterConstants or nil
    PZHarness.assertTrue(
        characters and characters.Load and characters.Save
            and characters.GetCharacterUUID and characters.EnsureIdentity
            and characters.GetRegistryRecord
            and characters.GetRegistrySnapshot,
        "native PlayerCharacters API was not available"
    )
    PZHarness.assertTrue(
        constants and constants.REGISTRY_MODDATA_KEY
            and constants.REGISTRY_SCHEMA_VERSION,
        "native PlayerCharacters constants were not available"
    )
    PZHarness.assertTrue(
        characters.Loaded == true and characters.Registry
            and characters.Registry.byUUID
            and characters.Registry.byAccountKey,
        "native PlayerCharacters registry was not loaded before the test"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    if characters.UUIDGenerator then
        characters.UUIDGenerator = function() return UUID end
    end
    local identity, identityReason = characters.EnsureIdentity(
        player,
        {
            worldAgeHours = 123,
            callback = "native_harness_player_characters",
        }
    )
    PZHarness.assertEqual(
        identity,
        UUID,
        "native synthetic player identity was not created: "
            .. tostring(identityReason)
    )
    PZHarness.assertEqual(
        identityReason,
        "new_identity",
        "native PlayerCharacters did not report a new identity"
    )
    PZHarness.assertEqual(
        playerData.PNC_CharacterUUID,
        UUID,
        "native PlayerCharacters UUID mirror was not written"
    )
    PZHarness.assertEqual(
        playerData.PNC_CharacterIdentityVersion,
        constants.IDENTITY_VERSION,
        "native PlayerCharacters identity mirror version was not written"
    )
    PZHarness.assertEqual(
        playerData.PNC_CharacterAccountKey,
        ACCOUNT,
        "native PlayerCharacters account mirror was not written"
    )

    local resolvedUUID, resolvedReason = characters.GetCharacterUUID(player)
    PZHarness.assertEqual(
        resolvedUUID,
        UUID,
        "native PlayerCharacters UUID resolution failed: "
            .. tostring(resolvedReason)
    )
    local record = characters.GetRegistryRecord(UUID)
    PZHarness.assertTrue(
        record and record.uuid == UUID
            and record.accountKey == ACCOUNT
            and record.accountIdentity == ACCOUNT
            and record.status == constants.STATUS_ACTIVE
            and record.displayName == "PZ Harness Identity"
            and record.forename == "Harness"
            and record.surname == "Identity"
            and record.lastKnownX == 130
            and record.lastKnownY == 230
            and record.lastKnownZ == 0,
        "native PlayerCharacters registry record was not normalized"
    )
    local snapshot = characters.GetRegistrySnapshot()
    PZHarness.assertTrue(
        snapshot and snapshot.byUUID and snapshot.byUUID[UUID]
            and snapshot.byAccountKey[ACCOUNT]
            and snapshot.byAccountKey[ACCOUNT][UUID] == true
            and snapshot.byAccount[ACCOUNT]
            and snapshot.byAccount[ACCOUNT][UUID] == true,
        "native PlayerCharacters registry indexes were not rebuilt"
    )
    PZHarness.assertTrue(
        characters.Dirty == true,
        "native PlayerCharacters did not retain its dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_player_characters_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native PlayerCharacters commit failed: "
            .. tostring(commitReason or committed)
    )
    local identityResult = commitDetails
        and commitDetails.results
        and commitDetails.results.identity
    PZHarness.assertTrue(
        identityResult and identityResult.changed == true,
        "native persistence coordinator did not save PlayerCharacters"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters remained dirty after commit"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawRecord = raw and raw.byUUID and raw.byUUID[UUID]
    local rawByAccountKey = raw and raw.byAccountKey
        and raw.byAccountKey[ACCOUNT]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == constants.REGISTRY_SCHEMA_VERSION
            and type(rawRecord) == "table"
            and rawRecord.uuid == UUID
            and rawRecord.accountKey == ACCOUNT
            and rawRecord.status == constants.STATUS_ACTIVE
            and type(rawByAccountKey) == "table"
            and rawByAccountKey[UUID] == true,
        "native PlayerCharacters ModData did not contain the identity"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native PlayerCharacters OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_PLAYER_CHARACTERS_WRITE_ON_SAVE:" .. UUID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native PlayerCharacters GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native PlayerCharacters GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native PlayerCharacters GameWindow.save did not trigger OnSave"
        )
    end
end
