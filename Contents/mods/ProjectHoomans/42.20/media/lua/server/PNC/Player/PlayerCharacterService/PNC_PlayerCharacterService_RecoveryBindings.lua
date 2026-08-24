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
local informationalFields = Internal.informationalFields

local function recoverAccountCharacter(accountKey, player)
    local candidates = PlayerCharacters.Registry.byAccountKey[accountKey]
        or {}
    local info = informationalFields(player)
    local selected
    local matchCount = 0
    local function matchesPlayer(record)
        -- Display name and username are mutable presentation. Descriptor
        -- names are only a guard against binding a genuinely different live
        -- survivor when the engine dropped the ModData mirror.
        if info and info.forename and record.forename
            and info.forename ~= record.forename
        then
            return false
        end
        if info and info.surname and record.surname
            and info.surname ~= record.surname
        then
            return false
        end
        return true
    end
    local function newerThan(left, right)
        local leftSeen = tonumber(left.lastSeenAt) or 0
        local rightSeen = tonumber(right.lastSeenAt) or 0
        if leftSeen ~= rightSeen then return leftSeen > rightSeen end
        local leftCreated = tonumber(left.createdAt) or 0
        local rightCreated = tonumber(right.createdAt) or 0
        if leftCreated ~= rightCreated then return leftCreated > rightCreated end
        return tostring(left.uuid) > tostring(right.uuid)
    end
    for uuid in pairs(candidates) do
        local record = PlayerCharacters.Registry.byUUID[uuid]
        if record
            and record.status == Constants.STATUS_ACTIVE
            and record.accountKey == accountKey
            and not PlayerCharacters.RuntimeByUUID[uuid]
            and matchesPlayer(record)
        then
            matchCount = matchCount + 1
            if not selected or newerThan(record, selected) then
                selected = record
            end
        end
    end
    if matchCount > 1 then return nil, "identity_ambiguous" end
    return selected, selected and "recovered" or "not_found"
end

local function bind(player, uuid, accountKey)
    PlayerCharacters.RuntimeByPlayer[player] = uuid
    PlayerCharacters.RuntimeByUUID[uuid] = player
    local record = PlayerCharacters.Registry.byUUID[uuid]
    local revision = math.max(0, math.floor(tonumber(
        PlayerCharacters.Registry.revision
    ) or 0))
    PlayerCharacters.RuntimeContexts[player] = {
        accountKey = accountKey or (record and record.accountKey),
        characterUUID = uuid,
        entityKey = EntityRef.ForPlayerIdentity(
            accountKey or (record and record.accountKey), uuid
        ),
        bindingRevision = revision,
    }
end

local function unbindRuntime(player)
    local uuid = PlayerCharacters.RuntimeByPlayer[player]
    if not uuid then
        return nil
    end
    PlayerCharacters.RuntimeByPlayer[player] = nil
    PlayerCharacters.RuntimeContexts[player] = nil
    if PlayerCharacters.RuntimeByUUID[uuid] == player then
        PlayerCharacters.RuntimeByUUID[uuid] = nil
    end
    return uuid
end


Internal.recoverAccountCharacter = recoverAccountCharacter
Internal.bind = bind
Internal.unbindRuntime = unbindRuntime

return PlayerCharacters
