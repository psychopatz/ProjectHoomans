-- Target-owned native player-character restart fixture, phase two.
-- Exercise mirror-based identity recovery from the persisted registry only.

local ACCOUNT = "pzharness_player_characters_account"
local UUID = "char_pzharness_player_characters_restart"

local playerData = {
    PNC_CharacterUUID = UUID,
    PNC_CharacterIdentityVersion = 2,
    PNC_CharacterAccountKey = ACCOUNT,
}
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
        characters and characters.Loaded == true and characters.Registry
            and characters.Registry.byUUID
            and characters.Registry.byAccountKey
            and characters.GetCharacterUUID
            and characters.GetRegistryRecord
            and characters.GetRegistrySnapshot,
        "native PlayerCharacters was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        constants and constants.REGISTRY_MODDATA_KEY
            and constants.REGISTRY_SCHEMA_VERSION,
        "native PlayerCharacters constants were not available after restart"
    )

    local resolvedUUID, resolvedReason = characters.GetCharacterUUID(player)
    PZHarness.assertEqual(
        resolvedUUID,
        UUID,
        "native PlayerCharacters mirror recovery failed: "
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
        "native PlayerCharacters record did not survive restart"
    )
    local snapshot = characters.GetRegistrySnapshot()
    PZHarness.assertTrue(
        snapshot and snapshot.byUUID and snapshot.byUUID[UUID]
            and snapshot.byAccountKey[ACCOUNT]
            and snapshot.byAccountKey[ACCOUNT][UUID] == true
            and snapshot.byAccount[ACCOUNT]
            and snapshot.byAccount[ACCOUNT][UUID] == true,
        "native PlayerCharacters indexes did not survive restart"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters was unexpectedly dirty after reload"
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
        "native PlayerCharacters ModData was not reloaded"
    )
end
