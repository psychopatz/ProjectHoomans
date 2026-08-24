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
local worldAgeHours = Internal.worldAgeHours
local logIdentity = Internal.logIdentity
local accountKeyFor = Internal.accountKeyFor
local onlineIDFor = Internal.onlineIDFor
local setMirror = Internal.setMirror
local mirroredUUID = Internal.mirroredUUID
local markRecordChanged = Internal.markRecordChanged
local updateInformation = Internal.updateInformation
local recoverAccountCharacter = Internal.recoverAccountCharacter
local bind = Internal.bind
local unbindRuntime = Internal.unbindRuntime
local createIdentity = Internal.createIdentity

local function reuseIdentity(
    player, record, accountKey, at, callback, source, bindNeeded
)
    if bindNeeded then
        bind(player, record.uuid, accountKey)
    end
    setMirror(player, record.uuid, record.accountKey)
    local changed = updateInformation(
        record, player, at, bindNeeded == true)
    if bindNeeded and changed then
        PlayerCharacters.Registry.byUUID[record.uuid] = record
        markRecordChanged(record)
    end
    logIdentity({
        callback = callback,
        accountKey = record.accountKey,
        characterUUID = record.uuid,
        status = record.status,
        worldAgeHours = at,
        onlineID = onlineIDFor(player),
        result = "reused",
        reason = source,
    })
    return record.uuid, "reused"
end

function PlayerCharacters.EnsureIdentity(player, context)
    local at = worldAgeHours(
        type(context) == "table" and context.worldAgeHours or nil
    )
    local callback = type(context) == "table"
        and context.callback or "ensure"
    local accountKey
    local runtimeUUID
    local record
    local claimedUUID
    local valid
    local reason
    local uuid
    PlayerCharacters.EnsureLoaded()
    if not player or not player.getModData then
        return nil, "invalid_player"
    end
    accountKey = accountKeyFor(player)
    if not accountKey then
        unbindRuntime(player)
        logIdentity({
            callback = callback,
            onlineID = onlineIDFor(player),
            worldAgeHours = at,
            result = "rejected",
            reason = "account_identity_unavailable",
        })
        return nil, "account_identity_unavailable"
    end
    if not PlayerCharacters.RuntimeByPlayer[player]
        and PNC.PlayerIdentityMigration
        and PNC.PlayerIdentityMigration.RunForPlayer
    then
        local _, migrationReason =
            PNC.PlayerIdentityMigration.RunForPlayer(player, accountKey, at)
        if migrationReason == "identity_ambiguous" then
            return nil, migrationReason
        end
        if migrationReason and migrationReason ~= "migrated"
            and migrationReason ~= "already_migrated"
            and migrationReason ~= "not_singleplayer"
            and migrationReason ~= "no_legacy_candidate"
        then
            return nil, migrationReason
        end
    end
    runtimeUUID = PlayerCharacters.RuntimeByPlayer[player]
    record = runtimeUUID
        and PlayerCharacters.Registry.byUUID[runtimeUUID] or nil
    if record
        and record.status == Constants.STATUS_ACTIVE
        and PlayerCharacters.RuntimeByUUID[runtimeUUID] == player
    then
        -- A binding is immutable for the lifetime of this IsoPlayer. Username
        -- and display-name changes are presentation updates only.
        return reuseIdentity(
            player, record, record.accountKey, at, callback,
            "runtime_binding", false)
    end
    if runtimeUUID then
        unbindRuntime(player)
    end
    claimedUUID = mirroredUUID(player)
    valid, reason, record =
        PlayerCharacters.ValidateClaim(player, claimedUUID)
    if valid then
        return reuseIdentity(
            player, record, accountKey, at, callback,
            "validated_claim", true)
    end
    if claimedUUID ~= nil then
        logIdentity({
            callback = callback,
            accountKey = accountKey,
            characterUUID = Types.NormalizeUUID(claimedUUID),
            worldAgeHours = at,
            onlineID = onlineIDFor(player),
            result = "rejected",
            reason = reason,
        })
    else
        local recoveryReason
        record, recoveryReason = recoverAccountCharacter(accountKey, player)
        if recoveryReason == "identity_ambiguous" then
            PlayerCharacters.Registry.migration.status = "ambiguous"
            PlayerCharacters.Registry.migration.diagnostic =
                "multiple_active_account_bindings"
            PlayerCharacters.Dirty = true
            return nil, "identity_ambiguous"
        end
        if record then
            return reuseIdentity(
                player, record, accountKey, at, callback,
                "account_recovery", true)
        end
    end
    -- An authority migration may detect multiple plausible survivors. Never
    -- mint another record in that state; surface a diagnostic instead.
    if PlayerCharacters.Registry.migration
        and PlayerCharacters.Registry.migration.status == "ambiguous"
    then
        return nil, "identity_ambiguous"
    end
    uuid, reason = createIdentity(player, accountKey, at)
    if not uuid then
        return nil, reason
    end
    logIdentity({
        callback = callback,
        accountKey = accountKey,
        characterUUID = uuid,
        status = Constants.STATUS_ACTIVE,
        worldAgeHours = at,
        onlineID = onlineIDFor(player),
        result = "assigned",
        reason = reason,
    })
    return uuid, reason
end


return PlayerCharacters
