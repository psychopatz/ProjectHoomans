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
local mirroredUUID = Internal.mirroredUUID
local markRecordChanged = Internal.markRecordChanged
local updateInformation = Internal.updateInformation
local bind = Internal.bind
local unbindRuntime = Internal.unbindRuntime

function PlayerCharacters.MarkDead(player, at, reason)
    local uuid
    local record
    local accountKey
    local claimedUUID
    local boundPlayer
    at = worldAgeHours(at)
    PlayerCharacters.EnsureLoaded()
    uuid = PlayerCharacters.RuntimeByPlayer[player]
    if not uuid then
        accountKey = accountKeyFor(player)
        claimedUUID = Types.ResolveUUID(
            PlayerCharacters.Registry, mirroredUUID(player)
        )
        record = claimedUUID
            and PlayerCharacters.Registry.byUUID[claimedUUID] or nil
        if record
            and record.accountKey == accountKey
            and record.status == Constants.STATUS_DEAD
        then
            return false, "already_dead", claimedUUID
        end
        boundPlayer = claimedUUID
            and PlayerCharacters.RuntimeByUUID[claimedUUID] or nil
        if record
            and record.accountKey == accountKey
            and record.status == Constants.STATUS_ACTIVE
            and (not boundPlayer or boundPlayer == player)
        then
            uuid = claimedUUID
            bind(player, uuid, accountKey)
        else
            uuid = PlayerCharacters.EnsureIdentity(player, {
                callback = "death_fallback",
                worldAgeHours = at,
            })
        end
    end
    record = uuid and PlayerCharacters.Registry.byUUID[uuid] or nil
    accountKey = accountKey or accountKeyFor(player)
    if not record
        or PlayerCharacters.RuntimeByPlayer[player] ~= uuid
        or record.accountKey ~= accountKey
    then
        unbindRuntime(player)
        return false, "death_identity_unavailable"
    end
    if record.status == Constants.STATUS_DEAD then
        unbindRuntime(player)
        return false, "already_dead"
    end
    if record.status ~= Constants.STATUS_ACTIVE then
        unbindRuntime(player)
        return false, "character_not_active"
    end
    updateInformation(record, player, at, true)
    record.status = Constants.STATUS_DEAD
    record.diedAt = at
    markRecordChanged(record)
    unbindRuntime(player)
    logIdentity({
        callback = "player_death",
        accountKey = accountKey,
        characterUUID = uuid,
        status = record.status,
        worldAgeHours = at,
        onlineID = onlineIDFor(player),
        result = "marked_dead",
        reason = reason or "death",
    })
    return true, "marked_dead", uuid
end

function PlayerCharacters.Unbind(
    player,
    reason,
    at,
    updatePersistent
)
    local uuid = PlayerCharacters.RuntimeByPlayer[player]
    local record
    if not uuid then
        return false, "not_bound"
    end
    record = PlayerCharacters.Registry.byUUID[uuid]
    if updatePersistent == true
        and record
        and record.status == Constants.STATUS_ACTIVE
        and updateInformation(
            record,
            player,
            worldAgeHours(at),
            true
        )
    then
        markRecordChanged(record)
    end
    unbindRuntime(player)
    logIdentity({
        callback = "runtime_unbind",
        accountIdentity = record and record.accountIdentity,
        characterUUID = uuid,
        status = record and record.status,
        worldAgeHours = worldAgeHours(at),
        onlineID = onlineIDFor(player),
        result = "cleared",
        reason = reason or "unbind",
    })
    return true, "unbound", uuid
end

function PlayerCharacters.SweepBindings(seenPlayers, at)
    local stale = {}
    local player
    local index
    for player, _ in pairs(PlayerCharacters.RuntimeByPlayer) do
        if not seenPlayers[player] then
            stale[#stale + 1] = player
        end
    end
    for index = 1, #stale do
        PlayerCharacters.Unbind(
            stale[index],
            "player_not_observed",
            at,
            true
        )
    end
    return #stale
end

function PlayerCharacters.ResetRuntimeBindings(reason)
    local player
    local players = {}
    local index
    for player, _ in pairs(PlayerCharacters.RuntimeByPlayer) do
        players[#players + 1] = player
    end
    for index = 1, #players do
        PlayerCharacters.Unbind(
            players[index],
            reason or "runtime_reset"
        )
    end
    PlayerCharacters.RuntimeByPlayer =
        setmetatable({}, { __mode = "k" })
    PlayerCharacters.RuntimeByUUID = {}
    PlayerCharacters.RuntimeContexts =
        setmetatable({}, { __mode = "k" })
end


return PlayerCharacters
