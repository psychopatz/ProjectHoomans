-- Target-owned native scavenge-policy restart fixture, phase two.
-- Read player-owned preferences with a synthetic server-side player only.

local ACCOUNT = "pzharness_scavenge_account"
local UUID = "char_pzharness_scavenge_restart"
local FULL_TYPE = "Base.TinCan"

local playerData = {
    PNC_CharacterUUID = UUID,
    PNC_CharacterIdentityVersion = 2,
    PNC_CharacterAccountKey = ACCOUNT,
}
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
        policy and policy.GetPreferences and policy.GetAutoGrab
            and policy.Loaded == true and policy.Data
            and policy.Data.owners,
        "native ScavengePolicy was not loaded after the JVM restart"
    )
    PZHarness.assertEqual(
        policy.MODDATA_KEY,
        "PNC_ScavengePolicy",
        "native ScavengePolicy ModData key was not available after restart"
    )

    local ownerKey, ownerReason = PNC.PlayerCharacters.GetEntityKey(player)
    PZHarness.assertTrue(
        ownerKey and tostring(ownerKey) ~= "",
        "native synthetic player identity was not recovered: "
            .. tostring(ownerReason)
    )
    local preferences, preferencesReason = policy.GetPreferences(player)
    PZHarness.assertTrue(
        preferences and preferences.containers == false
            and preferences.floorItems == true
            and preferences.corpses == false,
        "native ScavengePolicy preferences did not survive restart: "
            .. tostring(preferencesReason)
    )
    local autoGrab, autoGrabReason = policy.GetAutoGrab(player)
    PZHarness.assertTrue(
        autoGrab and autoGrab[FULL_TYPE] == true,
        "native ScavengePolicy auto-grab did not survive restart: "
            .. tostring(autoGrabReason)
    )
    PZHarness.assertTrue(
        policy.Dirty == false,
        "native ScavengePolicy was unexpectedly dirty after reload"
    )

    local raw = ModData.get(policy.MODDATA_KEY)
    local rawOwner = raw and raw.owners and raw.owners[ownerKey]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == 1
            and type(rawOwner) == "table"
            and rawOwner.preferences.containers == false
            and rawOwner.autoGrab[FULL_TYPE] == true,
        "native scavenge-policy ModData was not reloaded"
    )
end
