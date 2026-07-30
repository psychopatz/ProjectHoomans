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

function Types.NewRegistry()
    return {
        schemaVersion = Constants.REGISTRY_SCHEMA_VERSION,
        revision = 0,
        byUUID = {},
        byAccount = {},
    }
end

function Types.NewCharacterRecord(spec)
    local uuid
    local accountIdentity
    local status
    local createdAt
    spec = type(spec) == "table" and spec or {}
    uuid = Types.NormalizeUUID(spec.uuid)
    accountIdentity = Types.NormalizeAccountIdentity(
        spec.accountIdentity
    )
    if not uuid or not accountIdentity then
        return nil
    end
    status = Constants.VALID_STATUSES[spec.status]
        and spec.status or Constants.STATUS_ACTIVE
    createdAt = timestamp(spec.createdAt, 0)
    return {
        uuid = uuid,
        accountIdentity = accountIdentity,
        status = status,
        createdAt = createdAt,
        firstSeenAt = timestamp(spec.firstSeenAt, createdAt),
        lastSeenAt = timestamp(spec.lastSeenAt, createdAt),
        diedAt = status == Constants.STATUS_DEAD
            and timestamp(spec.diedAt, 0) or 0,
        retiredAt = status == Constants.STATUS_RETIRED
            and timestamp(spec.retiredAt, 0) or 0,
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
        accountIdentity = value.accountIdentity,
        status = status,
        createdAt = value.createdAt,
        firstSeenAt = value.firstSeenAt,
        lastSeenAt = value.lastSeenAt,
        diedAt = value.diedAt,
        retiredAt = value.retiredAt,
        forename = value.forename,
        surname = value.surname,
        displayName = value.displayName,
        lastKnownX = value.lastKnownX,
        lastKnownY = value.lastKnownY,
        lastKnownZ = value.lastKnownZ,
        socialProfile = value.socialProfile,
        conduct = value.conduct,
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
    for uuid, record in pairs(
        type(source.byUUID) == "table" and source.byUUID or {}
    ) do
        uuid = Types.NormalizeUUID(uuid)
        record = uuid
            and Types.NormalizeCharacterRecord(record, uuid) or nil
        if record then
            output.byUUID[uuid] = record
            output.byAccount[record.accountIdentity] =
                output.byAccount[record.accountIdentity] or {}
            output.byAccount[record.accountIdentity][uuid] = true
        end
    end
    return output
end

return Types
