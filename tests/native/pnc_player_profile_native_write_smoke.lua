-- Target-owned native player-profile restart fixture, phase one.
-- Exercise social-profile and conduct normalization against one synthetic
-- player-character identity only.

local ACCOUNT = "pzharness_player_profile_account"
local UUID = "char_pzharness_player_profile_restart"

local playerData = {}
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
    local profileTypes = PNC and PNC.SocialProfileTypes or nil
    local conductTypes = PNC and PNC.ConductTypes or nil
    PZHarness.assertTrue(
        characters and characters.Load and characters.Save
            and characters.EnsureIdentity and characters.GetCharacterUUID
            and characters.GetRegistryRecord,
        "native PlayerCharacters profile API was not available"
    )
    PZHarness.assertTrue(
        profileTypes and profileTypes.NormalizePlayerSocialProfile,
        "native social-profile normalizer was not available"
    )
    PZHarness.assertTrue(
        conductTypes and conductTypes.NormalizeConductRecord
            and conductTypes.AreEqual,
        "native conduct normalizer was not available"
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
            worldAgeHours = 456,
            callback = "native_harness_player_profile",
        }
    )
    PZHarness.assertEqual(
        identity,
        UUID,
        "native synthetic player profile identity was not created: "
            .. tostring(identityReason)
    )
    PZHarness.assertEqual(
        identityReason,
        "new_identity",
        "native PlayerCharacters did not report a new profile identity"
    )

    local profileChanged, profileReason, appliedProfile =
        characters.ApplyResolvedSocialProfile(
            UUID,
            {
                revision = 99,
                resolvedAt = 456,
                orientation = "gay",
                foodPreference = "spicy",
                romanceStyle = "flirty",
                jealousyStyle = "unpossessive",
                socialStyle = "friendly",
                sourceTraits = {
                    PNC_Gay = true,
                    PNC_Friendly = true,
                    invalid_profile_trait = true,
                },
            }
        )
    PZHarness.assertTrue(
        profileChanged == true and profileReason == "updated"
            and appliedProfile,
        "native social profile was not applied: " .. tostring(profileReason)
    )
    PZHarness.assertTrue(
        appliedProfile.schemaVersion == 1
            and appliedProfile.revision == 1
            and appliedProfile.resolvedAt == 456
            and appliedProfile.orientation == "gay"
            and appliedProfile.foodPreference == "spicy"
            and appliedProfile.romanceStyle == "flirty"
            and appliedProfile.jealousyStyle == "unpossessive"
            and appliedProfile.socialStyle == "friendly"
            and appliedProfile.sourceTraits.PNC_Gay == true
            and appliedProfile.sourceTraits.PNC_Friendly == true
            and appliedProfile.sourceTraits.invalid_profile_trait == nil,
        "native social profile was not normalized"
    )

    local conductChanged, conductReason, appliedConduct =
        characters.ApplyConductRecord(
            UUID,
            {
                revision = 8,
                lastEvaluatedAt = 777,
                baseline = {
                    reliability = 250,
                    generosity = -250,
                    compassion = 10,
                    courage = 20,
                    restraint = 30,
                    honesty = 40,
                    groupLoyalty = 50,
                },
                evidence = {},
                recentEvidenceIDs = {
                    "conduct:profile-restart",
                    "not-a-conduct-id",
                },
            }
        )
    PZHarness.assertTrue(
        conductChanged == true and conductReason == "updated"
            and appliedConduct,
        "native conduct record was not applied: " .. tostring(conductReason)
    )
    PZHarness.assertTrue(
        appliedConduct.schemaVersion == 1
            and appliedConduct.revision == 8
            and appliedConduct.lastEvaluatedAt == 777
            and appliedConduct.baseline.reliability == 100
            and appliedConduct.baseline.generosity == -100
            and appliedConduct.scores.reliability == 100
            and appliedConduct.scores.generosity == -100
            and appliedConduct.scores.groupLoyalty == 50
            and #appliedConduct.evidence == 0
            and #appliedConduct.recentEvidenceIDs == 1
            and appliedConduct.recentEvidenceIDs[1]
                == "conduct:profile-restart",
        "native conduct record was not normalized"
    )

    local record = characters.GetRegistryRecord(UUID)
    PZHarness.assertTrue(
        record and record.uuid == UUID
            and record.socialProfile
            and record.socialProfile.revision == 1
            and record.socialProfile.orientation == "gay"
            and record.conduct
            and record.conduct.revision == 8
            and record.conduct.scores.reliability == 100,
        "native PlayerCharacters record did not retain social state"
    )
    PZHarness.assertTrue(
        characters.Dirty == true,
        "native PlayerCharacters did not retain profile dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_player_profile_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native PlayerCharacters profile commit failed: "
            .. tostring(commitReason or committed)
    )
    local identityResult = commitDetails
        and commitDetails.results
        and commitDetails.results.identity
    PZHarness.assertTrue(
        identityResult and identityResult.changed == true,
        "native persistence coordinator did not save profile state"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters profile remained dirty after commit"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawRecord = raw and raw.byUUID and raw.byUUID[UUID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and type(rawRecord) == "table"
            and rawRecord.socialProfile
            and rawRecord.socialProfile.orientation == "gay"
            and rawRecord.socialProfile.revision == 1
            and rawRecord.conduct
            and rawRecord.conduct.revision == 8
            and rawRecord.conduct.scores.generosity == -100,
        "native PlayerCharacters ModData did not contain social state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native PlayerCharacters profile OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_PLAYER_PROFILE_WRITE_ON_SAVE:" .. UUID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native PlayerCharacters profile GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native PlayerCharacters profile GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native PlayerCharacters profile GameWindow.save did not trigger OnSave"
        )
    end
end
