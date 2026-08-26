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
Internal.HEALTH_PART_IDS = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R",
    "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R",
    "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

function Internal.normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

function Internal.normalizeNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        numeric = tonumber(fallback)
    end
    if numeric == nil then
        numeric = 0
    end
    return numeric
end

function Internal.hasTableEntries(source)
    local _
    if type(source) ~= "table" then
        return false
    end
    for _, _ in pairs(source) do
        return true
    end
    return false
end

function Internal.copyStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = Internal.normalizeString(key)
        value = Internal.normalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end

function Internal.copyPoints(points, fallbackX, fallbackY, fallbackZ)
    local output = {}
    local i
    local entry
    if type(points) == "table" then
        for i = 1, #points do
            entry = points[i]
            if type(entry) == "table" and entry.x ~= nil and entry.y ~= nil then
                output[#output + 1] = {
                    x = Internal.normalizeNumber(entry.x, fallbackX),
                    y = Internal.normalizeNumber(entry.y, fallbackY),
                    z = Internal.normalizeNumber(entry.z, fallbackZ),
                }
            end
        end
    end
    if #output <= 0 then
        output[1] = {
            x = Internal.normalizeNumber(fallbackX, 0),
            y = Internal.normalizeNumber(fallbackY, 0),
            z = Internal.normalizeNumber(fallbackZ, 0),
        }
    end
    return output
end

function Internal.sanitizeColor(raw)
    if type(raw) ~= "table" then
        return nil
    end
    return {
        r = Internal.normalizeNumber(raw.r, 0.2),
        g = Internal.normalizeNumber(raw.g, 0.1),
        b = Internal.normalizeNumber(raw.b, 0.1),
    }
end

function Internal.sanitizeIdentity(rawIdentity, record)
    local identity = type(rawIdentity) == "table" and Core.DeepCopy(rawIdentity) or {}
    local archetypeID = Internal.normalizeString(identity.archetypeID or record.archetypeID)
    local archetypeLabel = Internal.normalizeString(identity.archetypeLabel or record.archetypeLabel)
    return {
        seed = Identity.NormalizeSeed(identity.seed or record.identitySeed, record.id),
        archetypeID = archetypeID,
        archetypeLabel = archetypeLabel,
        displayName = Internal.normalizeString(identity.displayName or record.name),
        isFemale = identity.isFemale == true or record.isFemale == true,
        survivor = {
            forename = Internal.normalizeString(identity.survivor and identity.survivor.forename),
            surname = Internal.normalizeString(identity.survivor and identity.survivor.surname),
            hairModel = Internal.normalizeString(identity.survivor and identity.survivor.hairModel),
            beardModel = Internal.normalizeString(identity.survivor and identity.survivor.beardModel),
            skinColor = Internal.sanitizeColor(identity.survivor and identity.survivor.skinColor),
            hairColor = Internal.sanitizeColor(identity.survivor and identity.survivor.hairColor),
            skinTexture = Internal.normalizeString(identity.survivor and identity.survivor.skinTexture),
            voice = Internal.normalizeString(identity.survivor and identity.survivor.voice),
        },
    }
end

function Internal.sanitizeOrderSpec(orderSpec, record)
    local spec = type(orderSpec) == "table" and Core.DeepCopy(orderSpec) or nil
    if not spec then
        return nil
    end
    if spec.points then
        spec.points = Internal.copyPoints(spec.points, record.anchorX, record.anchorY, record.anchorZ)
    end
    if spec.x ~= nil then
        spec.x = Internal.normalizeNumber(spec.x, record.anchorX)
    end
    if spec.y ~= nil then
        spec.y = Internal.normalizeNumber(spec.y, record.anchorY)
    end
    if spec.z ~= nil then
        spec.z = Internal.normalizeNumber(spec.z, record.anchorZ)
    end
    if spec.radius ~= nil then
        spec.radius = math.max(0.5, Internal.normalizeNumber(spec.radius, Const.ROAM_DEFAULT_RADIUS))
    end
    if spec.targetRadius ~= nil then
        spec.targetRadius = math.max(1, Internal.normalizeNumber(spec.targetRadius, Const.ROAM_TARGET_RADIUS))
    end
    if spec.reachedDistance ~= nil then
        spec.reachedDistance = math.max(0.1, Internal.normalizeNumber(spec.reachedDistance, Const.ROAM_REACHED_DISTANCE))
    end
    if spec.pauseMinMs ~= nil then
        spec.pauseMinMs = math.max(0, Internal.normalizeNumber(spec.pauseMinMs, Const.ROAM_PAUSE_MIN_MS))
    end
    if spec.pauseMaxMs ~= nil then
        local minimum = tonumber(spec.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS
        spec.pauseMaxMs = math.max(minimum, Internal.normalizeNumber(spec.pauseMaxMs, Const.ROAM_PAUSE_MAX_MS))
    end
    spec.roamMode = Internal.normalizeString(spec.roamMode)
    spec.moveMode = Internal.normalizeString(spec.moveMode)
    spec.ownerUsername = Internal.normalizeString(spec.ownerUsername)
    spec.ownerOnlineID = nil
    spec.journeyId = Internal.normalizeString(spec.journeyId)
    return spec
end

function Internal.serializePatrolPoints(record)
    local points = record and record.patrolPoints or nil
    local orderKind = record and record.orderSpec
        and tostring(record.orderSpec.kind or "") or ""
    if orderKind ~= tostring(Const.ORDER_PATROL or "patrol")
        and (type(points) ~= "table" or #points <= 1)
    then
        return nil
    end
    return Internal.copyPoints(points, record.anchorX, record.anchorY, record.anchorZ)
end
