-- Target-owned native starting-companion restart fixture, phase two.
-- Exercise recovery of one character-owned companion grant.

local ACCOUNT = "pzharness_starting_companion_account"
local UUID = "char_pzharness_starting_companion_restart"
local NPC_ID = "npc_pzharness_starting_companion_restart"

local playerData = {
    PNC_CharacterUUID = UUID,
    PNC_CharacterIdentityVersion = 2,
    PNC_CharacterAccountKey = ACCOUNT,
}
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
    PZHarness.assertTrue(
        characters and characters.Loaded == true and characters.Registry
            and characters.Registry.byUUID and characters.GetCharacterUUID
            and characters.GetRegistryRecord,
        "native PlayerCharacters was not loaded after the companion restart"
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
        "native PlayerCharacters companion mirror recovery failed: "
            .. tostring(resolvedReason)
    )
    local record = characters.GetRegistryRecord(UUID)
    local state = record and record.startingCompanions
    local grant = state and state.grants and state.grants.PNC_HasBrother
    PZHarness.assertTrue(
        record and record.uuid == UUID
            and record.accountKey == ACCOUNT
            and state and state.resolved == true
            and grant
            and grant.status == "granted"
            and grant.traitID == "PNC_HasBrother"
            and grant.relationshipKind == "brother"
            and grant.npcID == NPC_ID
            and grant.selectedAt == 500
            and grant.grantedAt == 501
            and grant.enrichmentVersion == 2
            and grant.relationshipKeyVersion == 3
            and state.grants.PNC_Invalid == nil,
        "native PlayerCharacters companion state did not survive restart"
    )
    PZHarness.assertTrue(
        characters.Dirty == false,
        "native PlayerCharacters companion state was unexpectedly dirty"
    )

    local raw = ModData.get(constants.REGISTRY_MODDATA_KEY)
    local rawRecord = raw and raw.byUUID and raw.byUUID[UUID]
    local rawState = rawRecord and rawRecord.startingCompanions
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == constants.REGISTRY_SCHEMA_VERSION
            and type(rawRecord) == "table"
            and type(rawState) == "table"
            and rawState.resolved == true
            and rawState.grants
            and rawState.grants.PNC_HasBrother
            and rawState.grants.PNC_HasBrother.npcID == NPC_ID
            and rawState.grants.PNC_Invalid == nil,
        "native PlayerCharacters companion ModData was not reloaded"
    )
end
