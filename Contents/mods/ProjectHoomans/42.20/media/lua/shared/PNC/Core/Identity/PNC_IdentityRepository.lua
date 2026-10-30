-- Public Identity repository: immutable profile, voice and appearance provenance.
PNC = PNC or {}
PNC.Identity = PNC.Identity or {}
local Identity = PNC.Identity
local Core = PNC.Core
local Const = PNC.Const
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local Internal = {
    normalizeString = Codec.normalizeString,
    normalizeNumber = Codec.normalizeNumber,
    hasTableEntries = Codec.hasTableEntries,
}

local VOICE_PROFILE_SCHEMA_VERSION = 1
local APPEARANCE_CONTRACT_SCHEMA_VERSION = 1
local APPEARANCE_POLICY_SCHEMA_VERSION = 2
local BACKSTORY_METADATA_SCHEMA_VERSION = 1
local BACKSTORY_SELECTION_LIMIT = 64
local BACKSTORY_CLASSES = {
    shared = true,
    colonist = true,
    neutral = true,
    hostile = true,
}
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

local function sanitizeStableIDMap(raw)
    local output = {}
    local count = 0
    local key
    local value
    if type(raw) ~= "table" then
        return output
    end
    for key, value in pairs(raw) do
        if count >= BACKSTORY_SELECTION_LIMIT then
            break
        end
        if key ~= nil and key ~= "" and value ~= nil and value ~= "" then
            key = tostring(key)
            value = tostring(value)
            if #key <= 160 and #value <= 160 then
                output[key] = value
                count = count + 1
            end
        end
    end
    return output
end

function Internal.sanitizeBackstoryMetadata(raw)
    local selections
    local overrides
    local selectionClass
    local catalogVersion
    if type(raw) ~= "table" then
        return nil
    end
    selections = sanitizeStableIDMap(raw.selections)
    overrides = sanitizeStableIDMap(raw.overrides)
    selectionClass = string.lower(tostring(raw.selectionClass or ""))
    if not BACKSTORY_CLASSES[selectionClass] then
        selectionClass = nil
    end
    catalogVersion = tonumber(raw.catalogVersion)
    if catalogVersion == nil or catalogVersion < 1 then
        catalogVersion = 1
    end
    if not Internal.hasTableEntries(selections)
        and not Internal.hasTableEntries(overrides)
    then
        return nil
    end
    return {
        schemaVersion = BACKSTORY_METADATA_SCHEMA_VERSION,
        catalogVersion = math.floor(catalogVersion),
        selectionClass = selectionClass,
        selections = selections,
        overrides = Internal.hasTableEntries(overrides)
            and overrides or nil,
    }
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
    local generatorVersion = tonumber(Const.GENERATOR_VERSION)
    local seed = Identity.NormalizeSeed(
        identity.seed or record and record.identitySeed,
        record and record.id
    )
    local archetypeID = Internal.normalizeString(
        identity.archetypeID or record and record.archetypeID
    )
    local authored = record and (record.appearanceAuthored == true
        or type(record.appearance) == "table") or false
    -- Do not persist a contract that cannot survive the validator. Older or
    -- hand-authored records may have appearance data without generator
    -- provenance; preserving that record is safer than writing a partial
    -- contract which makes the entire record fail closed on reload.
    if generatorVersion == nil or seed == nil or archetypeID == nil
        or archetypeID == ""
    then
        return nil
    end
    local contract = {
        schemaVersion = APPEARANCE_CONTRACT_SCHEMA_VERSION,
        mode = authored and "AUTHORED_POLICY" or "GENERATED_DEFAULT",
        authored = authored,
        generator = {
            generatorVersion = generatorVersion,
            seed = seed,
            archetypeID = archetypeID,
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
        backstory = Internal.sanitizeBackstoryMetadata(identity.backstory),
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


local Repository = Identity.Repository or {}
Identity.Repository = Repository
function Repository.Normalize(raw, record)
    return Internal.sanitizeIdentity(raw, record)
end

function Repository.RestoreVoiceProfile(raw)
    return Internal.RestoreVoiceProfile(raw)
end

function Repository.NormalizeBackstoryMetadata(raw)
    return Internal.sanitizeBackstoryMetadata(raw)
end

function Repository.BuildAppearanceContract(record)
    return Internal.BuildAppearanceContract(record)
end

function Repository.ValidateRecord(raw)
    return Internal.ValidateAppearancePersistence(raw)
end
return Repository
