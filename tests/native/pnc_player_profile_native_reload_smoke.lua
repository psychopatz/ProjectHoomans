-- Target-owned native player-profile restart fixture, phase two.
-- Exercise social-profile and conduct recovery from the persisted registry.

local ACCOUNT = "pzharness_player_profile_account"
local UUID = "char_pzharness_player_profile_restart"

local playerData = {
    PNC_CharacterUUID = UUID,
    PNC_CharacterIdentityVersion = 2,
    PNC_CharacterAccountKey = ACCOUNT,
}
local player = {
    getUsername = function() return ACCOUNT end,
    getOnlineID = function() return 94 end,
    getModData = function() return playerData end,
    getDisplayName = function() return "PZ Harness Profile" end,
    getDescriptor = function()
        return {
            getForename = function() return "Harness" end,
            getSurname = function() return "Profile" end,
        }
    end,
    getX = function() return 140 end,
    getY = function() return 240 end,
    getZ = function() return 0 end,
}

PZHarnessNativeTest = function()
    local characters = PNC and PNC.PlayerCharacters or nil
    local constants = PNC and PNC.PlayerCharacterConstants or nil
    PZHarness.assertTrue(
        characters and characters.Loaded == true and characters.Registry
            and characters.Registry.byUUID and characters.GetCharacterUUID
            and characters.GetRegistryRecord,
        "native PlayerCharacters was not loaded after the profile restart"
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
        "native PlayerCharacters profile mirror recovery failed: "
            .. tostring(resolvedReason)
    )
    local record = characters.GetRegistryRecord(UUID)
    PZHarness.assertTrue(
        record and record.uuid == UUID
            and record.accountKey == ACCOUNT
            and record.socialProfile
            and record.socialProfile.schemaVersion == 1
            and record.socialProfile.revision == 1
            and record.socialProfile.resolvedAt == 456
            and record.socialProfile.orientation == "gay"
            and record.socialProfile.foodPreference == "spicy"
            and record.socialProfile.romanceStyle == "flirty"
            and record.socialProfile.jealousyStyle == "unpossessive"
            and record.socialProfile.socialStyle == "friendly"
            and record.socialProfile.sourceTraits.PNC_Gay == true
            and record.socialProfile.sourceTraits.PNC_Friendly == true
            and record.conduct
            and record.conduct.schemaVersion == 1
            and record.conduct.revision == 8
            and record.conduct.lastEvaluatedAt == 777
            and record.conduct.baseline.reliability == 100
            and record.conduct.baseline.generosity == -100
            and record.conduct.scores.reliability == 100
            and record.conduct.scores.generosity == -100
            and #record.conduct.evidence == 0
            and #record.conduct.recentEvidenceIDs == 1
            and record.conduct.recentEvidenceIDs[1]
                == "conduct:profile-restart",
        "native PlayerCharacters social state did not survive restart"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters profile was unexpectedly dirty after reload"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawRecord = raw and raw.byUUID and raw.byUUID[UUID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == constants.REGISTRY_SCHEMA_VERSION
            and type(rawRecord) == "table"
            and rawRecord.socialProfile
            and rawRecord.socialProfile.orientation == "gay"
            and rawRecord.socialProfile.revision == 1
            and rawRecord.conduct
            and rawRecord.conduct.revision == 8
            and rawRecord.conduct.scores.generosity == -100,
        "native PlayerCharacters social ModData was not reloaded"
    )
end
