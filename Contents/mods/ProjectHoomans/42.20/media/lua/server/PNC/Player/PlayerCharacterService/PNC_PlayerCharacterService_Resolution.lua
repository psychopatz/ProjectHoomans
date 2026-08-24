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
local mirroredUUID = Internal.mirroredUUID

function PlayerCharacters.GetCharacterUUID(player)
    local runtimeUUID
    local valid
    local reason
    local record
    local claim
    PlayerCharacters.EnsureLoaded()
    if not player then
        return nil, "invalid_player"
    end
    runtimeUUID = PlayerCharacters.RuntimeByPlayer[player]
    if runtimeUUID then
        record = PlayerCharacters.Registry.byUUID[runtimeUUID]
        if record
            and record.status == Constants.STATUS_ACTIVE
            and PlayerCharacters.RuntimeByUUID[runtimeUUID] == player
        then
            return runtimeUUID
        end
        return nil, "invalid_runtime_binding"
    end
    claim = mirroredUUID(player)
    valid, reason, record =
        PlayerCharacters.ValidateClaim(player, claim)
    if valid then
        return record.uuid
    end
    return nil, reason
end

function PlayerCharacters.GetEntityKey(player, context)
    local uuid
    local reason
    local contextValue
    uuid, reason = PlayerCharacters.EnsureIdentity(player, context)
    if not uuid then
        return nil, reason
    end
    contextValue = PlayerCharacters.RuntimeContexts[player]
    local key = contextValue and contextValue.entityKey
        or EntityRef.ForPlayerIdentity(accountKeyFor(player), uuid)
    if not key then
        return nil, "entity_key_invalid"
    end
    return key, "resolved"
end

function PlayerCharacters.ResolveEntityKey(entityKey)
    local parsed = EntityRef.Parse(entityKey)
    local record
    PlayerCharacters.EnsureLoaded()
    if not parsed or parsed.kind ~= "player" then
        return nil, "invalid_player_entity_key"
    end
    local canonicalUUID = Types.ResolveUUID(
        PlayerCharacters.Registry, parsed.characterUUID
    )
    record = PlayerCharacters.Registry.byUUID[canonicalUUID]
    local legacyMatch = record and record.legacyAccountIdentities
        and record.legacyAccountIdentities[parsed.accountIdentity] == true
    if not record
        or (record.accountKey ~= parsed.accountIdentity
            and record.accountIdentity ~= parsed.accountIdentity
            and not legacyMatch)
    then
        return nil, "player_character_not_found"
    end
    return copy(record), "resolved"
end


return PlayerCharacters
