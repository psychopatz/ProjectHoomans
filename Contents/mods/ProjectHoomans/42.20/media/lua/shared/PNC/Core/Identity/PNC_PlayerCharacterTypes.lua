-- Serialization-safe constructors and normalizers for player identities.
-- This module is pure: it does not inspect players, clocks, or engine state.

PNC = PNC or {}
PNC.PlayerCharacterTypes = PNC.PlayerCharacterTypes or {}

local Types = PNC.PlayerCharacterTypes
local Constants = PNC.PlayerCharacterConstants
local ProfileTypes = PNC.SocialProfileTypes
local ConductTypes = PNC.ConductTypes

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = tonumber(fallback)
    end
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = 0
    end
    return value
end

local function timestamp(value, fallback)
    return math.max(0, finite(value, fallback))
end

local function revision(value)
    return math.max(0, math.floor(finite(value, 0)))
end

local function optionalString(value)
    if type(value) ~= "string"
        or value == ""
        or #value > Constants.MAX_COMPONENT_LENGTH
        or string.find(value, "%c")
    then
        return nil
    end
    return value
end

function Types.NormalizeAccountIdentity(value)
    value = optionalString(value)
    if not value or string.find(value, ":", 1, true) then
        return nil
    end
    return value
end

function Types.NormalizeUUID(value)
    value = optionalString(value)
    if not value
        or string.find(value, ":", 1, true)
        or not string.match(value, "^char_[%w_%-]+$")
    then
        return nil
    end
    return value
end

function Types.IsValidUUID(value)
    return Types.NormalizeUUID(value) ~= nil
end

function Types.NormalizeStartingCompanionGrant(value)
    if type(value) ~= "table" then return nil end
    local status = tostring(value.status or "")
    if status ~= "pending" and status ~= "granted" and status ~= "none" then
        return nil
    end
    return {
        status = status,
        traitID = optionalString(value.traitID),
        relationshipKind = optionalString(value.relationshipKind),
        npcID = optionalString(value.npcID),
        selectedAt = timestamp(value.selectedAt, 0),
        grantedAt = timestamp(value.grantedAt, 0),
        enrichmentVersion = revision(value.enrichmentVersion),
    }
end

function Types.NormalizeStartingCompanionState(value)
    local output = { resolved = false, grants = {} }
    if type(value) ~= "table" then return output end
    output.resolved = value.resolved == true
    local source = type(value.grants) == "table" and value.grants or {}
    local traitID
    local grant
    for key, item in pairs(source) do
        grant = Types.NormalizeStartingCompanionGrant(item)
        traitID = optionalString(grant and (grant.traitID or key))
        if grant and traitID and grant.status ~= "none" then
            grant.traitID = traitID
            output.grants[traitID] = grant
        end
    end
    -- Version 5 stored one grant directly. Promote it without spawning a
    -- duplicate when the registry is normalized after this update.
    grant = Types.NormalizeStartingCompanionGrant(value)
    traitID = optionalString(grant and grant.traitID)
    if grant and grant.status == "none" then
        output.resolved = true
    elseif grant and traitID then
        output.resolved = true
        output.grants[traitID] = grant
    end
    return output
end

function Types.NewRegistry()
    return {
        schemaVersion = Constants.REGISTRY_SCHEMA_VERSION,
        revision = 0,
        byUUID = {},
        byAccountKey = {},
        -- Compatibility index for older readers. New code must use
        -- byAccountKey; both indexes are rebuilt from records on load.
        byAccount = {},
        uuidAliases = {},
        legacyAccountIdentities = {},
        migration = {
            revision = 0,
            status = "pending",
            completedAt = 0,
            canonicalUUID = nil,
            diagnostic = nil,
        },
    }
end

function Types.NewCharacterRecord(spec)
    local uuid
    local accountIdentity
    local status
    local createdAt
    spec = type(spec) == "table" and spec or {}
    uuid = Types.NormalizeUUID(spec.uuid)
    accountIdentity = Types.NormalizeAccountIdentity(spec.accountIdentity)
    local accountKey = Types.NormalizeAccountIdentity(
        spec.accountKey or accountIdentity
    )
    if not uuid or not accountKey then
        return nil
    end
    accountIdentity = accountIdentity or accountKey
    status = Constants.VALID_STATUSES[spec.status]
        and spec.status or Constants.STATUS_ACTIVE
    createdAt = timestamp(spec.createdAt, 0)
    local legacyAccountIdentities = {}
    for identity, enabled in pairs(
        type(spec.legacyAccountIdentities) == "table"
            and spec.legacyAccountIdentities or {}
    ) do
        identity = Types.NormalizeAccountIdentity(identity)
        if identity and enabled == true then
            legacyAccountIdentities[identity] = true
        end
    end
    return {
        uuid = uuid,
        accountKey = accountKey,
        accountIdentity = accountIdentity,
        status = status,
        createdAt = createdAt,
        firstSeenAt = timestamp(spec.firstSeenAt, createdAt),
        lastSeenAt = timestamp(spec.lastSeenAt, createdAt),
        diedAt = status == Constants.STATUS_DEAD
            and timestamp(spec.diedAt, 0) or 0,
        retiredAt = status == Constants.STATUS_RETIRED
            and timestamp(spec.retiredAt, 0) or 0,
        supersededBy = Types.NormalizeUUID(spec.supersededBy),
        legacyAccountIdentities = legacyAccountIdentities,
        forename = optionalString(spec.forename),
        surname = optionalString(spec.surname),
        displayName = optionalString(spec.displayName),
        lastKnownX = spec.lastKnownX ~= nil
            and finite(spec.lastKnownX, 0) or nil,
        lastKnownY = spec.lastKnownY ~= nil
            and finite(spec.lastKnownY, 0) or nil,
        lastKnownZ = spec.lastKnownZ ~= nil
            and finite(spec.lastKnownZ, 0) or nil,
        socialProfile = ProfileTypes
            and ProfileTypes.NormalizePlayerSocialProfile(
                spec.socialProfile
            ) or nil,
        conduct = ConductTypes
            and ConductTypes.NormalizeConductRecord(spec.conduct)
            or nil,
        startingCompanions = Types.NormalizeStartingCompanionState(
            spec.startingCompanions or spec.startingCompanion
        ),
        revision = revision(spec.revision),
    }
end

function Types.NormalizeCharacterRecord(value, registryUUID)
    local spec
    local status
    if type(value) ~= "table" then
        return nil
    end
    registryUUID = Types.NormalizeUUID(registryUUID)
    if not registryUUID then
        return nil
    end
    status = Constants.VALID_STATUSES[value.status]
        and value.status or Constants.STATUS_RETIRED
    spec = {
        uuid = registryUUID,
        accountKey = value.accountKey or value.accountIdentity,
        accountIdentity = value.accountIdentity,
        status = status,
        createdAt = value.createdAt,
        firstSeenAt = value.firstSeenAt,
        lastSeenAt = value.lastSeenAt,
        diedAt = value.diedAt,
        retiredAt = value.retiredAt,
        supersededBy = value.supersededBy,
        legacyAccountIdentities = value.legacyAccountIdentities,
        forename = value.forename,
        surname = value.surname,
        displayName = value.displayName,
        lastKnownX = value.lastKnownX,
        lastKnownY = value.lastKnownY,
        lastKnownZ = value.lastKnownZ,
        socialProfile = value.socialProfile,
        conduct = value.conduct,
        startingCompanions = value.startingCompanions
            or value.startingCompanion,
        revision = value.revision,
    }
    return Types.NewCharacterRecord(spec)
end

function Types.NormalizeRegistry(value)
    local output = Types.NewRegistry()
    local source = type(value) == "table" and value or {}
    local uuid
    local record
    output.revision = revision(source.revision)
    output.migration = {
        revision = revision(type(source.migration) == "table"
            and source.migration.revision or 0),
        status = optionalString(type(source.migration) == "table"
            and source.migration.status) or "pending",
        completedAt = timestamp(type(source.migration) == "table"
            and source.migration.completedAt or 0),
        canonicalUUID = Types.NormalizeUUID(type(source.migration) == "table"
            and source.migration.canonicalUUID),
        diagnostic = optionalString(type(source.migration) == "table"
            and source.migration.diagnostic),
    }
    for uuid, record in pairs(
        type(source.byUUID) == "table" and source.byUUID or {}
    ) do
        uuid = Types.NormalizeUUID(uuid)
        record = uuid
            and Types.NormalizeCharacterRecord(record, uuid) or nil
        if record then
            output.byUUID[uuid] = record
            output.byAccountKey[record.accountKey] =
                output.byAccountKey[record.accountKey] or {}
            output.byAccountKey[record.accountKey][uuid] = true
            output.byAccount[record.accountIdentity] =
                output.byAccount[record.accountIdentity] or {}
            output.byAccount[record.accountIdentity][uuid] = true
            for legacyIdentity, enabled in pairs(
                type(record.legacyAccountIdentities) == "table"
                    and record.legacyAccountIdentities or {}
            ) do
                legacyIdentity = Types.NormalizeAccountIdentity(legacyIdentity)
                if legacyIdentity and enabled == true then
                    output.legacyAccountIdentities[legacyIdentity] =
                        output.legacyAccountIdentities[legacyIdentity] or {}
                    output.legacyAccountIdentities[legacyIdentity][uuid] = true
                end
            end
        end
    end
    for oldUUID, canonicalUUID in pairs(
        type(source.uuidAliases) == "table" and source.uuidAliases or {}
    ) do
        oldUUID = Types.NormalizeUUID(oldUUID)
        canonicalUUID = Types.NormalizeUUID(canonicalUUID)
        if oldUUID and canonicalUUID and oldUUID ~= canonicalUUID
            and output.byUUID[oldUUID] and output.byUUID[canonicalUUID]
        then
            output.uuidAliases[oldUUID] = canonicalUUID
        end
    end
    return output
end

function Types.ResolveUUID(registry, value)
    local uuid = Types.NormalizeUUID(value)
    local seen = {}
    while uuid and type(registry) == "table"
        and type(registry.uuidAliases) == "table"
        and registry.uuidAliases[uuid]
        and not seen[uuid]
    do
        seen[uuid] = true
        uuid = Types.NormalizeUUID(registry.uuidAliases[uuid])
    end
    return uuid
end

return Types
