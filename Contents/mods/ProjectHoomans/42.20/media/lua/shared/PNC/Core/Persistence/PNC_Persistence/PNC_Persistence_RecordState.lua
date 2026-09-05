PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath
local FactionTypes = PNC.FactionTypes

function Internal.sanitizeCorpse(rawCorpse, record)
    if type(rawCorpse) ~= "table" then
        return nil
    end
    return {
        token = Internal.normalizeString(rawCorpse.token),
        x = Internal.normalizeNumber(rawCorpse.x, record and record.x or 0),
        y = Internal.normalizeNumber(rawCorpse.y, record and record.y or 0),
        z = Internal.normalizeNumber(rawCorpse.z, record and record.z or 0),
        createdWorldHour = Internal.normalizeNumber(rawCorpse.createdWorldHour, 0),
    }
end

-- A single pending follow-abandonment marker is persisted outside the social
-- relationship schema.  Social state is normalized as a closed shape, so
-- placing this transient presentation state there would silently discard it
-- during every relationship normalization.
function Internal.sanitizeFollowerAbandonment(raw)
    local source = type(raw) == "table" and raw or nil
    local eventID
    local hostileKind
    if not source then return nil end
    eventID = Internal.normalizeString(source.eventID)
    hostileKind = Internal.normalizeString(source.hostileKind)
    if not eventID or (hostileKind ~= "zombie" and hostileKind ~= "npc") then
        return nil
    end
    return {
        eventID = string.sub(eventID, 1, 256),
        ownerKey = Internal.normalizeString(source.ownerKey),
        ownerUsername = Internal.normalizeString(source.ownerUsername),
        ownerOnlineID = source.ownerOnlineID ~= nil
            and (tonumber(source.ownerOnlineID) or tostring(source.ownerOnlineID))
            or nil,
        hostileKind = hostileKind,
        hostileID = Internal.normalizeString(source.hostileID),
        capturedAt = math.max(0, Internal.normalizeNumber(source.capturedAt, 0)),
        relationshipApplied = source.relationshipApplied == true,
    }
end

function Internal.sanitizeStamina(rawStamina, record)
    local output
    if type(rawStamina) ~= "table" then
        return nil
    end
    output = {
        current = Internal.normalizeNumber(rawStamina.current, 0),
        max = rawStamina.max ~= nil
            and math.max(1, Internal.normalizeNumber(rawStamina.max, 1)) or nil,
    }
    if record then
        record.stamina = output
    end
    return output
end

function Internal.serializeStamina(rawStamina)
    local current
    local maximum
    if type(rawStamina) ~= "table" then return nil end
    current = tonumber(rawStamina.current)
    maximum = tonumber(rawStamina.max)
    if current == nil then return nil end
    if maximum and math.abs(current - maximum) < 0.01 then return nil end
    return { current = current }
end

function Internal.sanitizeProgression(rawProgression)
    local output = {
        recruited = false,
        skillLevelDeltas = {},
        legacySkillLevels = {},
        skillXP = {},
    }
    local key
    local value
    local source = type(rawProgression) == "table" and rawProgression or {}
    output.recruited = source.recruited == true
    if type(source.skillLevelDeltas) == "table" then
        for key, value in pairs(source.skillLevelDeltas) do
            value = math.max(-10, math.min(10,
                math.floor(Internal.normalizeNumber(value, 0))))
            if value ~= 0 then
                output.skillLevelDeltas[tostring(key)] = value
            end
        end
    end
    if type(source.skillLevels) == "table" then
        for key, value in pairs(source.skillLevels) do
            output.legacySkillLevels[tostring(key)] = math.max(0, math.min(10, math.floor(Internal.normalizeNumber(value, 0))))
        end
    end
    if type(source.skillXP) == "table" then
        for key, value in pairs(source.skillXP) do
            value = math.max(0, Internal.normalizeNumber(value, 0))
            if value ~= 0 then output.skillXP[tostring(key)] = value end
        end
    end
    return output
end

function Internal.sanitizeHostility(rawHostility, faction)
    if PNC.Types and PNC.Types.NormalizeHostility then
        return PNC.Types.NormalizeHostility(faction, rawHostility)
    end
    local source = type(rawHostility) == "table" and rawHostility or {}
    local hostile = tostring(faction or "") == "hostile"
    return { mode = tostring(source.mode or (hostile and "hostile_any_player" or "defend_owner")),
        attackPlayers = source.attackPlayers == nil and hostile or source.attackPlayers == true,
        attackNPCs = source.attackNPCs == nil and true or source.attackNPCs == true,
        attackZombies = source.attackZombies == nil and true or source.attackZombies == true }
end

function Internal.migrateLegacyIdentity(raw, definition)
    if type(raw.identity) == "table" then
        return Core.DeepCopy(raw.identity)
    end
    return {
        seed = raw.identitySeed,
        archetypeID = raw.archetypeID,
        archetypeLabel = raw.archetypeLabel,
        displayName = raw.displayName or raw.name,
        isFemale = raw.isFemale == true,
        survivor = {
            hairModel = raw.hairModel,
            beardModel = raw.beardModel,
            skinTexture = raw.skinTexture,
            skinColor = Internal.sanitizeColor(raw.skinColor),
            hairColor = Internal.sanitizeColor(raw.hairColor),
            voice = raw.voice,
            forename = raw.forename,
            surname = raw.surname,
        },
    }
end

function Internal.migrateLegacyInventory(raw)
    if type(raw.inventory) == "table" then
        return Core.DeepCopy(raw.inventory)
    end
    if type(raw.equipment) == "table" then
        return nil
    end
    return nil
end

function Internal.sanitizeSocial(raw, identitySeed, archetypeID)
    local social
    local targetKey
    local relationship
    if RelationshipTypes and RelationshipTypes.NormalizeSocialState then
        social = RelationshipTypes.NormalizeSocialState(
            raw,
            identitySeed,
            archetypeID
        )
        if RelationshipMath
            and RelationshipMath.RecalculateRelationship
        then
            for targetKey, relationship in pairs(
                social.relationships
            ) do
                social.relationships[targetKey] =
                    RelationshipMath.RecalculateRelationship(
                        relationship,
                        targetKey,
                        relationship.lastEvaluatedAt
                    )
            end
        end
        return social
    end
    return {
        schemaVersion = 3,
        revision = 0,
        morale = 0,
        moraleBaseline = 0,
        relationships = {},
        recentEventIDs = {},
        lastEvaluatedAt = 0,
        personality = nil,
        personalityOverrides = {},
        conduct = PNC.ConductTypes
            and PNC.ConductTypes.NewConductRecord() or nil,
    }
end
