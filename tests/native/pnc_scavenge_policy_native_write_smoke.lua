-- Target-owned native scavenge-policy restart fixture, phase one.
-- Exercise player-owned preferences with a synthetic server-side player only.

local ACCOUNT = "pzharness_scavenge_account"
local UUID = "char_pzharness_scavenge_restart"
local FULL_TYPE = "Base.TinCan"

local playerData = {}
local player = {
    getUsername = function() return ACCOUNT end,
    getOnlineID = function() return 91 end,
    getModData = function() return playerData end,
    getDisplayName = function() return "PZ Harness Scavenge" end,
    getDescriptor = function()
        return {
            getForename = function() return "Harness" end,
            getSurname = function() return "Scavenge" end,
        }
    end,
    getX = function() return 100 end,
    getY = function() return 200 end,
    getZ = function() return 0 end,
}

PZHarnessNativeTest = function()
    local policy = PNC and PNC.ScavengePolicy or nil
    PZHarness.assertTrue(
        policy and policy.GetPreferences and policy.SetPreferences
            and policy.GetAutoGrab and policy.SetAutoGrab
            and policy.Load and policy.Save,
        "native ScavengePolicy API was not available"
    )
    PZHarness.assertTrue(
        policy and policy.Loaded == true and policy.Data
            and policy.Data.owners,
        "native ScavengePolicy was not loaded before the test"
    )
    PZHarness.assertTrue(
        PNC.PlayerCharacters and PNC.PlayerCharacters.GetEntityKey,
        "native player identity service was not available"
    )

    if PNC.PlayerCharacters.UUIDGenerator then
        PNC.PlayerCharacters.UUIDGenerator = function() return UUID end
    end
    local ownerKey, ownerReason = PNC.PlayerCharacters.GetEntityKey(player)
    PZHarness.assertTrue(
        ownerKey and tostring(ownerKey) ~= "",
        "native synthetic player identity was not resolved: "
            .. tostring(ownerReason)
    )
    PZHarness.assertEqual(
        playerData.PNC_CharacterUUID,
        UUID,
        "native synthetic player identity mirror was not written"
    )

    local preferencesOK, preferences = policy.SetPreferences(player, {
        containers = false,
        floorItems = true,
        corpses = false,
    })
    PZHarness.assertTrue(
        preferencesOK and preferences and preferences.containers == false
            and preferences.floorItems == true
            and preferences.corpses == false,
        "native ScavengePolicy preferences were not normalized: "
            .. tostring(preferences)
    )
    local autoGrabOK, autoGrab = policy.SetAutoGrab(
        player, FULL_TYPE, true
    )
    PZHarness.assertTrue(
        autoGrabOK and autoGrab and autoGrab[FULL_TYPE] == true,
        "native ScavengePolicy auto-grab was not retained: "
            .. tostring(autoGrab)
    )
    PZHarness.assertTrue(
        policy.Dirty == true,
        "native ScavengePolicy did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_scavenge_policy_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native scavenge-policy commit failed: "
            .. tostring(commitReason or committed)
    )
    local policyResult = commitDetails
        and commitDetails.results
        and commitDetails.results.scavengePolicy
    PZHarness.assertTrue(
        policyResult and policyResult.changed == true,
        "native persistence coordinator did not save ScavengePolicy"
    )
    PZHarness.assertTrue(
        policy.Dirty == false,
        "native ScavengePolicy remained dirty after commit"
    )

    local raw = ModData.get(policy.MODDATA_KEY)
    local rawOwner = raw and raw.owners and raw.owners[ownerKey]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == 1
            and type(rawOwner) == "table"
            and rawOwner.preferences.containers == false
            and rawOwner.preferences.floorItems == true
            and rawOwner.preferences.corpses == false
            and rawOwner.autoGrab[FULL_TYPE] == true,
        "native scavenge-policy ModData did not contain preferences"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native scavenge-policy OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_SCAVENGE_POLICY_WRITE_ON_SAVE:" .. tostring(ownerKey))
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native scavenge-policy GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native scavenge-policy GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native scavenge-policy GameWindow.save did not trigger OnSave"
        )
    end
end
