-- Target-owned native starting-companion restart fixture, phase one.
-- Exercise one character-owned companion grant without spawning an NPC.

local ACCOUNT = "pzharness_starting_companion_account"
local UUID = "char_pzharness_starting_companion_restart"
local NPC_ID = "npc_pzharness_starting_companion_restart"

local playerData = {}
local player = {
    getUsername = function() return ACCOUNT end,
    getOnlineID = function() return 95 end,
    getModData = function() return playerData end,
    getDisplayName = function() return "PZ Harness Companion" end,
    getDescriptor = function()
        return {
            getForename = function() return "Harness" end,
            getSurname = function() return "Companion" end,
        }
    end,
    getX = function() return 150 end,
    getY = function() return 250 end,
    getZ = function() return 0 end,
}

PZHarnessNativeTest = function()
    local characters = PNC and PNC.PlayerCharacters or nil
    local constants = PNC and PNC.PlayerCharacterConstants or nil
    local types = PNC and PNC.PlayerCharacterTypes or nil
    PZHarness.assertTrue(
        characters and characters.Load and characters.Save
            and characters.EnsureIdentity and characters.GetRegistryRecord
            and characters.ApplyStartingCompanionState,
        "native PlayerCharacters companion API was not available"
    )
    PZHarness.assertTrue(
        types and types.NormalizeStartingCompanionState,
        "native starting-companion normalizer was not available"
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
            worldAgeHours = 500,
            callback = "native_harness_starting_companion",
        }
    )
    PZHarness.assertEqual(
        identity,
        UUID,
        "native synthetic companion identity was not created: "
            .. tostring(identityReason)
    )
    PZHarness.assertEqual(
        identityReason,
        "new_identity",
        "native PlayerCharacters did not report a new companion identity"
    )

    local changed, changeReason, applied =
        characters.ApplyStartingCompanionState(
            UUID,
            {
                resolved = true,
                grants = {
                    PNC_HasBrother = {
                        status = "granted",
                        traitID = "PNC_HasBrother",
                        relationshipKind = "brother",
                        npcID = NPC_ID,
                        selectedAt = 500,
                        grantedAt = 501,
                        enrichmentVersion = 2,
                        relationshipKeyVersion = 3,
                    },
                    PNC_Invalid = {
                        status = "invalid-status",
                        traitID = "PNC_Invalid",
                        npcID = "npc_should_be_discarded",
                    },
                },
            }
        )
    PZHarness.assertTrue(
        changed == true and changeReason == "updated" and applied,
        "native starting-companion state was not applied: "
            .. tostring(changeReason)
    )
    local grant = applied.grants.PNC_HasBrother
    PZHarness.assertTrue(
        applied.resolved == true
            and type(applied.grants) == "table"
            and grant
            and grant.status == "granted"
            and grant.traitID == "PNC_HasBrother"
            and grant.relationshipKind == "brother"
            and grant.npcID == NPC_ID
            and grant.selectedAt == 500
            and grant.grantedAt == 501
            and grant.enrichmentVersion == 2
            and grant.relationshipKeyVersion == 3
            and applied.grants.PNC_Invalid == nil,
        "native starting-companion state was not normalized"
    )

    local record = characters.GetRegistryRecord(UUID)
    PZHarness.assertTrue(
        record and record.uuid == UUID
            and record.startingCompanions
            and record.startingCompanions.resolved == true
            and record.startingCompanions.grants.PNC_HasBrother
            and record.startingCompanions.grants.PNC_HasBrother.npcID == NPC_ID
            and record.startingCompanions.grants.PNC_Invalid == nil,
        "native PlayerCharacters record did not retain companion state"
    )
    PZHarness.assertTrue(
        characters.Dirty == true,
        "native PlayerCharacters did not retain companion dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_starting_companion_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native starting-companion commit failed: "
            .. tostring(commitReason or committed)
    )
    local identityResult = commitDetails
        and commitDetails.results
        and commitDetails.results.identity
    PZHarness.assertTrue(
        identityResult and identityResult.changed == true,
        "native persistence coordinator did not save companion state"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters companion state remained dirty after commit"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawRecord = raw and raw.byUUID and raw.byUUID[UUID]
    local rawState = rawRecord and rawRecord.startingCompanions
    PZHarness.assertTrue(
        type(raw) == "table"
            and type(rawRecord) == "table"
            and type(rawState) == "table"
            and rawState.resolved == true
            and rawState.grants
            and rawState.grants.PNC_HasBrother
            and rawState.grants.PNC_HasBrother.npcID == NPC_ID
            and rawState.grants.PNC_Invalid == nil,
        "native PlayerCharacters ModData did not contain companion state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native starting-companion OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_STARTING_COMPANION_WRITE_ON_SAVE:" .. UUID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native starting-companion GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native starting-companion GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native starting-companion GameWindow.save did not trigger OnSave"
        )
    end
end
