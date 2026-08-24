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
local playerModData = Internal.playerModData
local informationalFields = Internal.informationalFields

local function setMirror(player, uuid, accountKey)
    local data = playerModData(player)
    if not data then
        return false
    end
    data[Constants.MODDATA_UUID_FIELD] = uuid
    data[Constants.MODDATA_VERSION_FIELD] =
        Constants.IDENTITY_VERSION
    data[Constants.MODDATA_ACCOUNT_KEY_FIELD] = accountKey
    return true
end

local function mirroredUUID(player)
    local data = playerModData(player)
    return data and data[Constants.MODDATA_UUID_FIELD] or nil
end

local function incrementRegistryRevision()
    PlayerCharacters.Registry.revision = math.max(
        0,
        math.floor(
            tonumber(PlayerCharacters.Registry.revision) or 0
        )
    ) + 1
    PlayerCharacters.Dirty = true
end

local function markRecordChanged(record)
    record.revision = math.max(
        0,
        math.floor(tonumber(record.revision) or 0)
    ) + 1
    incrementRegistryRevision()
end

local function indexRecord(record)
    local accountIdentity = record.accountIdentity
    local accountKey = record.accountKey or accountIdentity
    local uuid = record.uuid
    PlayerCharacters.Registry.byAccountKey[accountKey] =
        PlayerCharacters.Registry.byAccountKey[accountKey] or {}
    PlayerCharacters.Registry.byAccountKey[accountKey][uuid] = true
    PlayerCharacters.Registry.byAccount[accountIdentity] =
        PlayerCharacters.Registry.byAccount[accountIdentity] or {}
    PlayerCharacters.Registry.byAccount[accountIdentity][uuid] = true
end

local function updateInformation(record, player, at, updateLastSeen)
    local info = informationalFields(player)
    local changed = false
    local fields = {
        "forename",
        "surname",
        "displayName",
        "lastKnownX",
        "lastKnownY",
        "lastKnownZ",
    }
    local index
    local field
    local value
    for index = 1, #fields do
        field = fields[index]
        value = info and info[field] or nil
        if value ~= nil and record[field] ~= value then
            record[field] = value
            changed = true
        end
    end
    if updateLastSeen == true
        and record.lastSeenAt ~= at
    then
        record.lastSeenAt = at
        changed = true
    end
    return changed
end

-- The engine does not reliably preserve player ModData for every local
-- single-player restart. The registry is authoritative, so recover the most
-- recent unbound active character for this account when that mirror is gone.
-- A valid mirror still wins, and an invalid mirror is never silently replaced.

Internal.setMirror = setMirror
Internal.mirroredUUID = mirroredUUID
Internal.incrementRegistryRevision = incrementRegistryRevision
Internal.markRecordChanged = markRecordChanged
Internal.indexRecord = indexRecord
Internal.updateInformation = updateInformation

return PlayerCharacters
