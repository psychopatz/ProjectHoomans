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

local VOICE_PROFILE_SCHEMA_VERSION = 1
local APPEARANCE_CONTRACT_SCHEMA_VERSION = 1
local APPEARANCE_POLICY_SCHEMA_VERSION = 2
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

function Internal.sanitizeVoiceProfile(rawSurvivor)
    local survivor = type(rawSurvivor) == "table" and rawSurvivor or {}
    local source = type(survivor.voiceProfile) == "table"
        and survivor.voiceProfile or nil
    local voice = source and source.voice or survivor.voice
    local voicePrefix = source
        and (source.voicePrefix or source.prefix)
        or survivor.voicePrefix
    local voiceType = source
        and (source.voiceType or source.type)
        or survivor.voiceType
    local voicePitch = source
        and (source.voicePitch or source.pitch)
        or survivor.voicePitch
    local normalizedVoice = Internal.normalizeString(voice)
    local normalizedPrefix = Internal.normalizeString(voicePrefix)
    local normalizedType = tonumber(voiceType)
    local normalizedPitch = tonumber(voicePitch)
    if normalizedVoice == nil and normalizedPrefix == nil
        and normalizedType == nil and normalizedPitch == nil
    then
        return nil
    end
    return {
        schemaVersion = VOICE_PROFILE_SCHEMA_VERSION,
        voice = normalizedVoice,
        voicePrefix = normalizedPrefix,
        voiceType = normalizedType,
        voicePitch = normalizedPitch,
        complete = normalizedVoice ~= nil
            and normalizedPrefix ~= nil
            and normalizedType ~= nil
            and normalizedPitch ~= nil,
    }
end

function Internal.RestoreVoiceProfile(rawIdentity)
    local identity = type(rawIdentity) == "table" and rawIdentity or {}
    local survivor = type(identity.survivor) == "table"
        and identity.survivor or nil
    local profile = survivor and survivor.voiceProfile
    if type(profile) ~= "table"
        or tonumber(profile.schemaVersion) ~= VOICE_PROFILE_SCHEMA_VERSION
    then
        return identity
    end
    if profile.voice ~= nil then
        survivor.voice = profile.voice
    end
    if profile.voicePrefix ~= nil then
        survivor.voicePrefix = profile.voicePrefix
    end
    if profile.voiceType ~= nil then
        survivor.voiceType = profile.voiceType
    end
    if profile.voicePitch ~= nil then
        survivor.voicePitch = profile.voicePitch
    end
    return identity
end

local function appearancePolicyHash(policy)
    local appearance = Identity and Identity.Appearance
    if type(policy) ~= "table" or not appearance
        or type(appearance.Signature) ~= "function"
        or not Identity or type(Identity.HashText) ~= "function"
    then
        return nil
    end
    return Identity.HashText(appearance.Signature(policy), 5381)
end

function Internal.BuildAppearanceContract(record)
    local identity = record and record.identity or {}
    local authored = record and (record.appearanceAuthored == true
        or type(record.appearance) == "table") or false
    local contract = {
        schemaVersion = APPEARANCE_CONTRACT_SCHEMA_VERSION,
        mode = authored and "AUTHORED_POLICY" or "GENERATED_DEFAULT",
        authored = authored,
        generator = {
            generatorVersion = tonumber(Const.GENERATOR_VERSION),
            seed = Identity.NormalizeSeed(
                identity.seed or record and record.identitySeed,
                record and record.id
            ),
            archetypeID = Internal.normalizeString(
                identity.archetypeID or record and record.archetypeID
            ),
            uniqueDefinitionId = Internal.normalizeString(
                record and record.uniqueDefinitionId
            ),
            uniqueDefinitionVersion = tonumber(
                record and record.uniqueDefinitionVersion
            ),
            equipmentPoolID = Internal.normalizeString(
                record and record.equipmentPoolID
            ),
            inventoryTemplateRef = Internal.normalizeString(
                record and record.inventoryTemplateRef
            ),
        },
    }
    if authored then
        contract.policySchemaVersion = tonumber(
            record.appearance and record.appearance.schemaVersion
        )
        contract.policyHash = appearancePolicyHash(record.appearance)
    end
    return contract
end

function Internal.ValidateAppearancePersistence(raw)
    local identity = type(raw) == "table"
        and type(raw.identity) == "table" and raw.identity or {}
    local survivor = type(identity.survivor) == "table"
        and identity.survivor or {}
    local voiceProfile = survivor.voiceProfile
    local appearance = raw and raw.appearance
    local contract = raw and raw.appearanceContract
    local authored
    local generator
    local expectedHash
    local valid
    if voiceProfile ~= nil then
        if type(voiceProfile) ~= "table"
            or tonumber(voiceProfile.schemaVersion)
                ~= VOICE_PROFILE_SCHEMA_VERSION
        then
            return "voice_profile_unsupported"
        end
        if voiceProfile.complete == true
            and (voiceProfile.voice == nil
                or voiceProfile.voicePrefix == nil
                or voiceProfile.voiceType == nil
                or voiceProfile.voicePitch == nil)
        then
            return "voice_profile_incomplete"
        end
    end
    if appearance ~= nil then
        if type(appearance) ~= "table"
            or tonumber(appearance.schemaVersion)
                ~= APPEARANCE_POLICY_SCHEMA_VERSION
        then
            return "appearance_schema_unsupported"
        end
        if Identity.Appearance and Identity.Appearance.Validate then
            valid = Identity.Appearance.Validate(appearance)
            if not valid then
                return "appearance_policy_invalid"
            end
        end
    end
    if contract == nil then
        return nil
    end
    if type(contract) ~= "table"
        or tonumber(contract.schemaVersion)
            ~= APPEARANCE_CONTRACT_SCHEMA_VERSION
    then
        return "appearance_contract_unsupported"
    end
    authored = contract.authored == true
    if (contract.mode == "AUTHORED_POLICY") ~= authored
        or (contract.mode == "GENERATED_DEFAULT") == authored
    then
        return "appearance_contract_invalid"
    end
    if authored ~= (appearance ~= nil) then
        return authored and "authored_appearance_policy_missing"
            or "appearance_contract_invalid"
    end
    generator = contract.generator
    if type(generator) ~= "table"
        or tonumber(generator.generatorVersion)
            ~= tonumber(Const.GENERATOR_VERSION)
        or generator.seed == nil
        or type(generator.archetypeID) ~= "string"
        or generator.archetypeID == ""
    then
        return "generator_provenance_incomplete"
    end
    if authored and contract.policyHash ~= nil then
        expectedHash = appearancePolicyHash(appearance)
        if expectedHash ~= nil
            and tostring(contract.policyHash) ~= tostring(expectedHash)
        then
            return "generator_provenance_mismatch"
        end
    end
    return nil
end

function Internal.sanitizeIdentity(rawIdentity, record)
    local identity = type(rawIdentity) == "table" and Core.DeepCopy(rawIdentity) or {}
    local survivor = type(identity.survivor) == "table"
        and identity.survivor or {}
    local voiceProfile = Internal.sanitizeVoiceProfile(survivor)
    local archetypeID = Internal.normalizeString(identity.archetypeID or record.archetypeID)
    return {
        seed = Identity.NormalizeSeed(identity.seed or record.identitySeed, record.id),
        birth = Identity and type(Identity.NormalizeBirthDate) == "function"
            and Identity.NormalizeBirthDate(identity.birth) or nil,
        archetypeID = archetypeID,
        displayName = Internal.normalizeString(identity.displayName or record.name),
        isFemale = identity.isFemale == true or record.isFemale == true,
        survivor = {
            forename = Internal.normalizeString(survivor.forename),
            surname = Internal.normalizeString(survivor.surname),
            hairModel = Internal.normalizeString(survivor.hairModel),
            beardModel = Internal.normalizeString(survivor.beardModel),
            skinColor = Internal.sanitizeColor(survivor.skinColor),
            hairColor = Internal.sanitizeColor(survivor.hairColor),
            skinTexture = Internal.normalizeString(survivor.skinTexture),
            voice = Internal.normalizeString(survivor.voice),
            voiceProfile = voiceProfile,
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

-- Camp resources are intentionally persisted as a small whitelist of scalar
-- descriptors. World objects, squares, Java userdata, and provider-specific
-- runtime values must be rediscovered or revalidated after load.
function Internal.sanitizeCampState(raw, record)
    if type(raw) ~= "table" then return nil end
    local rawResources = type(raw.resources) == "table"
        and raw.resources or {}
    local function optionalNumber(value)
        return tonumber(value)
    end
    local rawBounds = type(raw.roomBounds) == "table"
        and raw.roomBounds or nil
    local roomBounds = rawBounds and {
        minX = optionalNumber(rawBounds.minX),
        minY = optionalNumber(rawBounds.minY),
        maxX = optionalNumber(rawBounds.maxX),
        maxY = optionalNumber(rawBounds.maxY),
        z = optionalNumber(rawBounds.z),
    } or nil
    if roomBounds and (roomBounds.minX == nil or roomBounds.minY == nil
        or roomBounds.maxX == nil or roomBounds.maxY == nil)
    then
        roomBounds = nil
    end
    local output = {
        schemaVersion = math.max(1, math.floor(
            Internal.normalizeNumber(raw.schemaVersion, 1))),
        campId = Internal.normalizeString(raw.campId),
        anchorX = Internal.normalizeNumber(raw.anchorX,
            record and record.anchorX or 0),
        anchorY = Internal.normalizeNumber(raw.anchorY,
            record and record.anchorY or 0),
        anchorZ = Internal.normalizeNumber(raw.anchorZ,
            record and record.anchorZ or 0),
        campRadius = math.max(0.5, math.min(24, Internal.normalizeNumber(
            raw.campRadius, Const.CAMP_RADIUS or 3))),
        resourceRadius = math.max(1, math.min(24, Internal.normalizeNumber(
            raw.resourceRadius, Const.CAMP_RESOURCE_RADIUS or 12))),
        scope = Internal.normalizeString(raw.scope or raw.siteScope),
        siteScope = Internal.normalizeString(raw.siteScope or raw.scope),
        siteID = Internal.normalizeString(raw.siteID),
        roomID = Internal.normalizeString(raw.roomID),
        buildingID = Internal.normalizeString(raw.buildingID),
        roomType = Internal.normalizeString(raw.roomType),
        roomName = Internal.normalizeString(raw.roomName),
        roomBounds = roomBounds,
        campfireID = Internal.normalizeString(raw.campfireID),
        scanTruncated = raw.scanTruncated == true,
        capturedAtWorldHour = Internal.normalizeNumber(
            raw.capturedAtWorldHour, 0),
        resources = {},
    }
    local allowed = {
        "kind", "detectorId", "targetResolver", "resourceKind", "role",
        "capability", "resourceKey", "key", "x", "y", "z", "originX",
        "originY", "originZ", "axis", "facing", "surfaceOffset", "sprite",
        "sceneId", "sleepSurface", "exclusive", "available", "readOnly",
        "seatSpots",
    }
    local spotAllowed = {
        "x", "y", "z", "seatAnchorX", "seatAnchorY", "seatAnchorZ",
        "direction", "side", "approachKey", "valid", "approachValid",
        "validationState", "rejectionReason", "routeStatus",
    }
    local maximum = math.max(1, math.floor(
        tonumber(Const.CAMP_RESOURCE_MAX) or 32))
    local spotMaximum = math.max(1, math.floor(
        tonumber(Const.CAMP_RESOURCE_SPOT_MAX) or 8))
    for index = 1, math.min(maximum, #rawResources) do
        local source = rawResources[index]
        if type(source) == "table" then
            local resource = {}
            for keyIndex = 1, #allowed do
                local key = allowed[keyIndex]
                local value = source[key]
                local valueType = type(value)
                if valueType == "number" or valueType == "string"
                    or valueType == "boolean"
                then
                    resource[key] = value
                end
            end
            if type(source.seatSpots) == "table" then
                resource.seatSpots = {}
                for spotIndex = 1, math.min(spotMaximum, #source.seatSpots) do
                    local sourceSpot = source.seatSpots[spotIndex]
                    if type(sourceSpot) == "table" then
                        local spot = {}
                        local copiedValues = 0
                        for spotKeyIndex = 1, #spotAllowed do
                            local spotKey = spotAllowed[spotKeyIndex]
                            local value = sourceSpot[spotKey]
                            local valueType = type(value)
                            if valueType == "number"
                                or valueType == "string"
                                or valueType == "boolean"
                            then
                                spot[spotKey] = value
                                copiedValues = copiedValues + 1
                            end
                        end
                        if copiedValues > 0 then
                            resource.seatSpots[#resource.seatSpots + 1] = spot
                        end
                    end
                end
                if #resource.seatSpots == 0 then
                    resource.seatSpots = nil
                end
            end
            resource.resourceKey = Internal.normalizeString(
                resource.resourceKey or resource.key)
            if resource.resourceKey then
                output.resources[#output.resources + 1] = resource
            end
        end
    end
    return output
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
