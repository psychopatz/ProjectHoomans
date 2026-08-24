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
local copy = Internal.copy
local accountKeyFor = Internal.accountKeyFor

function PlayerCharacters.IsCharacterActive(characterUUID)
    local record = PlayerCharacters.GetRegistryRecord(characterUUID)
    return record ~= nil
        and record.status == Constants.STATUS_ACTIVE
end

function PlayerCharacters.IsCharacterDead(characterUUID)
    local record = PlayerCharacters.GetRegistryRecord(characterUUID)
    return record ~= nil
        and record.status == Constants.STATUS_DEAD
end

function PlayerCharacters.ValidateClaim(player, claimedUUID)
    local accountKey
    local record
    local boundPlayer
    PlayerCharacters.EnsureLoaded()
    if not player or not player.getModData then
        return false, "invalid_player"
    end
    accountKey = accountKeyFor(player)
    if not accountKey then
        return false, "account_identity_unavailable"
    end
    claimedUUID = Types.ResolveUUID(PlayerCharacters.Registry, claimedUUID)
    if not claimedUUID then
        return false, "malformed_uuid"
    end
    record = PlayerCharacters.Registry.byUUID[claimedUUID]
    if not record then
        return false, "unknown_uuid"
    end
    if record.accountKey ~= accountKey then
        return false, "account_mismatch"
    end
    if record.status == Constants.STATUS_DEAD then
        return false, "character_dead"
    end
    if record.status ~= Constants.STATUS_ACTIVE then
        return false, "character_not_active"
    end
    boundPlayer = PlayerCharacters.RuntimeByUUID[claimedUUID]
    if boundPlayer and boundPlayer ~= player then
        return false, "duplicate_live_binding"
    end
    return true, "valid", copy(record)
end

function PlayerCharacters.GenerateUUID()
    local attempt
    local candidate
    PlayerCharacters.EnsureLoaded()
    for attempt = 1, Constants.MAX_GENERATION_ATTEMPTS do
        candidate = Types.NormalizeUUID(
            PlayerCharacters.UUIDGenerator(attempt)
        )
        if candidate
            and not PlayerCharacters.Registry.byUUID[candidate]
        then
            return candidate
        end
    end
    return nil, "uuid_generation_exhausted"
end


return PlayerCharacters
