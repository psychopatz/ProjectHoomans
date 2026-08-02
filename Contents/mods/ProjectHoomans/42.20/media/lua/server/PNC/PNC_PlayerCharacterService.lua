-- Server-authoritative persistent player-character identity registry.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}

local PlayerCharacters = PNC.PlayerCharacters
local Constants = PNC.PlayerCharacterConstants
local Types = PNC.PlayerCharacterTypes
local EntityRef = PNC.EntityRef
local Core = PNC.Core

PlayerCharacters.Registry = PlayerCharacters.Registry
    or Types.NewRegistry()
PlayerCharacters.Loaded = PlayerCharacters.Loaded == true
PlayerCharacters.Dirty = PlayerCharacters.Dirty == true
PlayerCharacters.RuntimeByPlayer = PlayerCharacters.RuntimeByPlayer
    or setmetatable({}, { __mode = "k" })
PlayerCharacters.RuntimeByUUID =
    PlayerCharacters.RuntimeByUUID or {}
PlayerCharacters.UUIDGenerator =
    PlayerCharacters.UUIDGenerator or function()
        return Core.GenerateID(Constants.UUID_PREFIX)
    end

local function worldAgeHours(value)
    value = tonumber(value)
    if value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function call(player, methodName)
    local method = player and player[methodName] or nil
    local ok
    local value
    if not method then
        return nil
    end
    ok, value = pcall(method, player)
    if not ok then
        return nil
    end
    return value
end

local function deepEqual(left, right, seen)
    local key
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] == right then
        return true
    end
    seen[left] = right
    for key, _ in pairs(left) do
        if not deepEqual(left[key], right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function copy(value)
    if Core and Core.DeepCopy then
        return Core.DeepCopy(value)
    end
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table"
            and copy(item) or item
    end
    return output
end

local function assignTable(target, source)
    local key
    for key, _ in pairs(target) do
        target[key] = nil
    end
    for key, value in pairs(source) do
        target[key] = type(value) == "table"
            and copy(value) or value
    end
end

local function logIdentity(fields)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogIdentity
    then
        PNC.PlayerCharacterDebug.LogIdentity(fields)
    end
end

local function accountIdentityFor(player)
    return Types.NormalizeAccountIdentity(call(player, "getUsername"))
end

local function onlineIDFor(player)
    return call(player, "getOnlineID")
end

local function playerModData(player)
    local data = call(player, "getModData")
    return type(data) == "table" and data or data
end

local function informationalFields(player)
    local descriptor = call(player, "getDescriptor")
    local output = {
        displayName = call(player, "getDisplayName"),
        lastKnownX = call(player, "getX"),
        lastKnownY = call(player, "getY"),
        lastKnownZ = call(player, "getZ"),
    }
    if descriptor then
        output.forename = call(descriptor, "getForename")
        output.surname = call(descriptor, "getSurname")
    end
    return Types.NewCharacterRecord({
        uuid = "char_information",
        accountIdentity = "information",
        forename = output.forename,
        surname = output.surname,
        displayName = output.displayName,
        lastKnownX = output.lastKnownX,
        lastKnownY = output.lastKnownY,
        lastKnownZ = output.lastKnownZ,
    })
end

local function setMirror(player, uuid)
    local data = playerModData(player)
    if not data then
        return false
    end
    data[Constants.MODDATA_UUID_FIELD] = uuid
    data[Constants.MODDATA_VERSION_FIELD] =
        Constants.IDENTITY_VERSION
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
    local uuid = record.uuid
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
local function recoverAccountCharacter(accountIdentity, player)
    local candidates = PlayerCharacters.Registry.byAccount[accountIdentity]
        or {}
    local info = informationalFields(player)
    local selected
    local function matchesPlayer(record)
        if info and info.displayName and record.displayName
            and info.displayName ~= record.displayName
        then
            return false
        end
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
            and record.accountIdentity == accountIdentity
            and not PlayerCharacters.RuntimeByUUID[uuid]
            and matchesPlayer(record)
            and (not selected or newerThan(record, selected))
        then
            selected = record
        end
    end
    return selected
end

local function bind(player, uuid)
    PlayerCharacters.RuntimeByPlayer[player] = uuid
    PlayerCharacters.RuntimeByUUID[uuid] = player
end

local function unbindRuntime(player)
    local uuid = PlayerCharacters.RuntimeByPlayer[player]
    if not uuid then
        return nil
    end
    PlayerCharacters.RuntimeByPlayer[player] = nil
    if PlayerCharacters.RuntimeByUUID[uuid] == player then
        PlayerCharacters.RuntimeByUUID[uuid] = nil
    end
    return uuid
end

function PlayerCharacters.Load()
    local raw
    local normalized
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or {}
    normalized = Types.NormalizeRegistry(raw)
    PlayerCharacters.Registry = normalized
    PlayerCharacters.Loaded = true
    PlayerCharacters.Dirty = not deepEqual(raw, normalized)
    PlayerCharacters.ResetRuntimeBindings("registry_load")
    return true, PlayerCharacters.Dirty
end

function PlayerCharacters.EnsureLoaded()
    if not PlayerCharacters.Loaded then
        return PlayerCharacters.Load()
    end
    return true
end

function PlayerCharacters.Save()
    local target
    PlayerCharacters.EnsureLoaded()
    if not PlayerCharacters.Dirty then
        return false, "not_dirty"
    end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or nil
    if not target then
        return false, "moddata_unavailable"
    end
    assignTable(target, Types.NormalizeRegistry(
        PlayerCharacters.Registry
    ))
    PlayerCharacters.Dirty = false
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    return true
end

function PlayerCharacters.NormalizeRegistry(value)
    local normalized
    if value ~= nil then
        return Types.NormalizeRegistry(value)
    end
    PlayerCharacters.EnsureLoaded()
    normalized = Types.NormalizeRegistry(PlayerCharacters.Registry)
    if not deepEqual(PlayerCharacters.Registry, normalized) then
        PlayerCharacters.Registry = normalized
        PlayerCharacters.Dirty = true
    end
    return copy(PlayerCharacters.Registry)
end

function PlayerCharacters.GetRegistryRecord(characterUUID)
    local record
    PlayerCharacters.EnsureLoaded()
    characterUUID = Types.NormalizeUUID(characterUUID)
    record = characterUUID
        and PlayerCharacters.Registry.byUUID[characterUUID] or nil
    return record and copy(record) or nil
end

function PlayerCharacters.GetRegistrySnapshot()
    PlayerCharacters.EnsureLoaded()
    return copy(PlayerCharacters.Registry)
end

-- Internal server-side commit boundary used by the social-profile service.
-- It deliberately accepts only a normalized profile-shaped table and is not
-- exposed through any client command.
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
    local accountIdentity
    local record
    local boundPlayer
    PlayerCharacters.EnsureLoaded()
    if not player or not player.getModData then
        return false, "invalid_player"
    end
    accountIdentity = accountIdentityFor(player)
    if not accountIdentity then
        return false, "account_identity_unavailable"
    end
    claimedUUID = Types.NormalizeUUID(claimedUUID)
    if not claimedUUID then
        return false, "malformed_uuid"
    end
    record = PlayerCharacters.Registry.byUUID[claimedUUID]
    if not record then
        return false, "unknown_uuid"
    end
    if record.accountIdentity ~= accountIdentity then
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

local function createIdentity(player, accountIdentity, at)
    local uuid
    local reason
    local info
    local record
    uuid, reason = PlayerCharacters.GenerateUUID()
    if not uuid then
        return nil, reason
    end
    info = informationalFields(player)
    record = Types.NewCharacterRecord({
        uuid = uuid,
        accountIdentity = accountIdentity,
        status = Constants.STATUS_ACTIVE,
        createdAt = at,
        firstSeenAt = at,
        lastSeenAt = at,
        forename = info and info.forename,
        surname = info and info.surname,
        displayName = info and info.displayName,
        lastKnownX = info and info.lastKnownX,
        lastKnownY = info and info.lastKnownY,
        lastKnownZ = info and info.lastKnownZ,
        revision = 1,
    })
    PlayerCharacters.Registry.byUUID[uuid] = record
    indexRecord(record)
    incrementRegistryRevision()
    setMirror(player, uuid)
    bind(player, uuid)
    return uuid, "new_identity"
end

function PlayerCharacters.EnsureIdentity(player, context)
    local at = worldAgeHours(
        type(context) == "table" and context.worldAgeHours or nil
    )
    local callback = type(context) == "table"
        and context.callback or "ensure"
    local accountIdentity
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
    accountIdentity = accountIdentityFor(player)
    if not accountIdentity then
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
    runtimeUUID = PlayerCharacters.RuntimeByPlayer[player]
    record = runtimeUUID
        and PlayerCharacters.Registry.byUUID[runtimeUUID] or nil
    if record
        and record.status == Constants.STATUS_ACTIVE
        and record.accountIdentity == accountIdentity
        and PlayerCharacters.RuntimeByUUID[runtimeUUID] == player
    then
        setMirror(player, runtimeUUID)
        logIdentity({
            callback = callback,
            accountIdentity = accountIdentity,
            characterUUID = runtimeUUID,
            status = record.status,
            worldAgeHours = at,
            onlineID = onlineIDFor(player),
            result = "reused",
            reason = "runtime_binding",
        })
        return runtimeUUID, "reused"
    end
    if runtimeUUID then
        unbindRuntime(player)
    end
    claimedUUID = mirroredUUID(player)
    valid, reason, record =
        PlayerCharacters.ValidateClaim(player, claimedUUID)
    if valid then
        bind(player, record.uuid)
        setMirror(player, record.uuid)
        if updateInformation(record, player, at, true) then
            PlayerCharacters.Registry.byUUID[record.uuid] = record
            markRecordChanged(record)
        end
        logIdentity({
            callback = callback,
            accountIdentity = accountIdentity,
            characterUUID = record.uuid,
            status = record.status,
            worldAgeHours = at,
            onlineID = onlineIDFor(player),
            result = "reused",
            reason = "validated_claim",
        })
        return record.uuid, "reused"
    end
    if claimedUUID ~= nil then
        logIdentity({
            callback = callback,
            accountIdentity = accountIdentity,
            characterUUID = Types.NormalizeUUID(claimedUUID),
            worldAgeHours = at,
            onlineID = onlineIDFor(player),
            result = "rejected",
            reason = reason,
        })
    else
        record = recoverAccountCharacter(accountIdentity, player)
        if record then
            bind(player, record.uuid)
            setMirror(player, record.uuid)
            if updateInformation(record, player, at, true) then
                PlayerCharacters.Registry.byUUID[record.uuid] = record
                markRecordChanged(record)
            end
            logIdentity({
                callback = callback,
                accountIdentity = accountIdentity,
                characterUUID = record.uuid,
                status = record.status,
                worldAgeHours = at,
                onlineID = onlineIDFor(player),
                result = "reused",
                reason = "account_recovery",
            })
            return record.uuid, "reused"
        end
    end
    uuid, reason = createIdentity(player, accountIdentity, at)
    if not uuid then
        return nil, reason
    end
    logIdentity({
        callback = callback,
        accountIdentity = accountIdentity,
        characterUUID = uuid,
        status = Constants.STATUS_ACTIVE,
        worldAgeHours = at,
        onlineID = onlineIDFor(player),
        result = "assigned",
        reason = reason,
    })
    return uuid, reason
end

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
            and record.accountIdentity == accountIdentityFor(player)
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
    local accountIdentity
    uuid, reason = PlayerCharacters.EnsureIdentity(player, context)
    if not uuid then
        return nil, reason
    end
    accountIdentity = accountIdentityFor(player)
    if not accountIdentity then
        return nil, "account_identity_unavailable"
    end
    local key = EntityRef.ForPlayerIdentity(accountIdentity, uuid)
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
    record = PlayerCharacters.Registry.byUUID[
        parsed.characterUUID
    ]
    if not record
        or record.accountIdentity ~= parsed.accountIdentity
    then
        return nil, "player_character_not_found"
    end
    return copy(record), "resolved"
end

function PlayerCharacters.MarkDead(player, at, reason)
    local uuid
    local record
    local accountIdentity
    local claimedUUID
    local boundPlayer
    at = worldAgeHours(at)
    PlayerCharacters.EnsureLoaded()
    uuid = PlayerCharacters.RuntimeByPlayer[player]
    if not uuid then
        accountIdentity = accountIdentityFor(player)
        claimedUUID = Types.NormalizeUUID(mirroredUUID(player))
        record = claimedUUID
            and PlayerCharacters.Registry.byUUID[claimedUUID] or nil
        if record
            and record.accountIdentity == accountIdentity
            and record.status == Constants.STATUS_DEAD
        then
            return false, "already_dead", claimedUUID
        end
        boundPlayer = claimedUUID
            and PlayerCharacters.RuntimeByUUID[claimedUUID] or nil
        if record
            and record.accountIdentity == accountIdentity
            and record.status == Constants.STATUS_ACTIVE
            and (not boundPlayer or boundPlayer == player)
        then
            uuid = claimedUUID
            bind(player, uuid)
        else
            uuid = PlayerCharacters.EnsureIdentity(player, {
                callback = "death_fallback",
                worldAgeHours = at,
            })
        end
    end
    record = uuid and PlayerCharacters.Registry.byUUID[uuid] or nil
    accountIdentity = accountIdentity or accountIdentityFor(player)
    if not record
        or PlayerCharacters.RuntimeByPlayer[player] ~= uuid
        or record.accountIdentity ~= accountIdentity
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
        accountIdentity = accountIdentity,
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
end

return PlayerCharacters
