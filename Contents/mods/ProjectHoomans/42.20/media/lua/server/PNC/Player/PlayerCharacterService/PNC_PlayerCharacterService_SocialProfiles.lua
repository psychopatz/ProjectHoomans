if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}
PNC.PlayerContext = PNC.PlayerContext or {}
PNC.PlayerCharacters.Internal = PNC.PlayerCharacters.Internal or {}

local PlayerCharacters = PNC.PlayerCharacters
local Internal = PlayerCharacters.Internal
local Constants = PNC.PlayerCharacterConstants
local Types = PNC.PlayerCharacterTypes
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local deepEqual = Internal.deepEqual
local copy = Internal.copy
local markRecordChanged = Internal.markRecordChanged

function PlayerCharacters.ApplyResolvedSocialProfile(
    characterUUID,
    value
)
    local record
    local existing
    local normalized
    PlayerCharacters.EnsureLoaded()
    characterUUID = Types.NormalizeUUID(characterUUID)
    record = characterUUID
        and PlayerCharacters.Registry.byUUID[characterUUID] or nil
    if not record then
        return false, "character_not_found"
    end
    if not PNC.SocialProfileTypes
        or not PNC.SocialProfileTypes.NormalizePlayerSocialProfile
    then
        return false, "profile_types_unavailable"
    end
    existing = PNC.SocialProfileTypes.NormalizePlayerSocialProfile(
        record.socialProfile
    )
    normalized = PNC.SocialProfileTypes.NormalizePlayerSocialProfile(
        value
    )
    normalized.revision = existing.revision
    if deepEqual(existing, normalized) then
        return false, "unchanged", copy(existing)
    end
    normalized.revision = existing.revision + 1
    record.socialProfile = normalized
    markRecordChanged(record)
    return true, "updated", copy(normalized)
end

-- Authoritative idempotence marker for character-creation companion grants.
-- It belongs to the character UUID rather than the account, so multiplayer
-- reconnects cannot duplicate it and a genuinely new survivor remains
-- eligible for their own selected trait.
function PlayerCharacters.ApplyStartingCompanionState(characterUUID, value)
    local record
    local normalized
    PlayerCharacters.EnsureLoaded()
    characterUUID = Types.NormalizeUUID(characterUUID)
    record = characterUUID
        and PlayerCharacters.Registry.byUUID[characterUUID] or nil
    if not record then return false, "character_not_found" end
    normalized = Types.NormalizeStartingCompanionState(value)
    if deepEqual(record.startingCompanions, normalized) then
        return false, "unchanged", copy(normalized)
    end
    record.startingCompanions = normalized
    markRecordChanged(record)
    return true, "updated", copy(normalized)
end


-- Version 5 compatibility for external integrations that still submit one
-- grant. New code should commit the complete state atomically.
function PlayerCharacters.ApplyStartingCompanionGrant(characterUUID, value)
    local record = PlayerCharacters.GetRegistryRecord(characterUUID)
    local state = Types.NormalizeStartingCompanionState(
        record and record.startingCompanions
    )
    local grant = Types.NormalizeStartingCompanionGrant(value)
    if not grant then return false, "invalid_grant" end
    state.resolved = true
    if grant.status ~= "none" and grant.traitID then
        state.grants[grant.traitID] = grant
    end
    return PlayerCharacters.ApplyStartingCompanionState(characterUUID, state)
end

-- Internal conduct commit boundary. The conduct service performs evidence
-- validation and revision calculation; this method owns character/registry
-- revision updates.
function PlayerCharacters.ApplyConductRecord(characterUUID, value)
    local record
    local normalized
    PlayerCharacters.EnsureLoaded()
    characterUUID = Types.NormalizeUUID(characterUUID)
    record = characterUUID
        and PlayerCharacters.Registry.byUUID[characterUUID] or nil
    if not record then
        return false, "character_not_found"
    end
    if not PNC.ConductTypes then
        return false, "conduct_types_unavailable"
    end
    normalized = PNC.ConductTypes.NormalizeConductRecord(value)
    if PNC.ConductTypes.AreEqual(record.conduct, normalized) then
        return false, "unchanged", copy(normalized)
    end
    record.conduct = normalized
    markRecordChanged(record)
    return true, "updated", copy(normalized)
end


return PlayerCharacters
