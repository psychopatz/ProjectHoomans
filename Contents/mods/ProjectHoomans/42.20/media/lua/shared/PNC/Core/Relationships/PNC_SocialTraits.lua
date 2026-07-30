-- Build 42 social-trait catalog, registration, and pure profile resolution.

PNC = PNC or {}
PNC.SocialTraits = PNC.SocialTraits or {}

local SocialTraits = PNC.SocialTraits
local Constants = PNC.SocialProfileConstants
local ProfileTypes = PNC.SocialProfileTypes

SocialTraits.EngineTraits = SocialTraits.EngineTraits or {}
SocialTraits.Registered = SocialTraits.Registered == true

local aliasToID = {}
local definitionByID = {}
local index
local definition

local function alias(value, id)
    aliasToID[string.lower(tostring(value))] = id
end

for index = 1, #Constants.TRAIT_DEFINITIONS do
    definition = Constants.TRAIT_DEFINITIONS[index]
    definitionByID[definition.id] = definition
    alias(definition.id, definition.id)
    alias(definition.resource, definition.id)
    alias(string.match(definition.resource, ":(.+)$"), definition.id)
end

function SocialTraits.NormalizeTraitID(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    return aliasToID[string.lower(value)]
end

function SocialTraits.GetDefinitions()
    local output = {}
    local key
    local item
    for index = 1, #Constants.TRAIT_DEFINITIONS do
        item = Constants.TRAIT_DEFINITIONS[index]
        output[index] = {}
        for key, value in pairs(item) do
            output[index][key] = value
        end
    end
    return output
end

function SocialTraits.GetDefinition(traitID)
    traitID = SocialTraits.NormalizeTraitID(traitID)
    local source = traitID and definitionByID[traitID] or nil
    local output = {}
    local key
    if not source then
        return nil
    end
    for key, value in pairs(source) do
        output[key] = value
    end
    return output
end

local function normalizedTraitSet(traitSet)
    local output = {}
    local key
    local value
    local canonical
    if type(traitSet) ~= "table" then
        return output
    end
    for key, value in pairs(traitSet) do
        if type(key) == "number" then
            canonical = SocialTraits.NormalizeTraitID(value)
        elseif value == true then
            canonical = SocialTraits.NormalizeTraitID(key)
        else
            canonical = nil
        end
        if canonical then
            output[canonical] = true
        end
    end
    return output
end

function SocialTraits.Fingerprint(traitSet)
    local normalized = normalizedTraitSet(traitSet)
    local ids = {}
    local id
    for id, _ in pairs(normalized) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return table.concat(ids, "|")
end

function SocialTraits.ResolveTraits(traitSet)
    local selected = normalizedTraitSet(traitSet)
    local conflicts = {}
    local pair
    local sourceTraits = {}
    local id
    local profile
    for index = 1, #Constants.TRAIT_PRECEDENCE do
        pair = Constants.TRAIT_PRECEDENCE[index]
        if selected[pair.preferred] and selected[pair.discarded] then
            selected[pair.discarded] = nil
            conflicts[#conflicts + 1] = {
                preferred = pair.preferred,
                discarded = pair.discarded,
            }
        end
    end
    for id, enabled in pairs(selected) do
        if enabled == true then
            sourceTraits[id] = true
        end
    end
    profile = ProfileTypes.NewPlayerSocialProfile({
        orientation = selected[Constants.TRAIT_IDS.BISEXUAL]
                and Constants.ORIENTATION_BISEXUAL
            or selected[Constants.TRAIT_IDS.GAY]
                and Constants.ORIENTATION_GAY
            or Constants.ORIENTATION_STRAIGHT,
        foodPreference = selected[Constants.TRAIT_IDS.SPICE_LOVER]
                and Constants.FOOD_SPICY
            or selected[Constants.TRAIT_IDS.BLAND_PALATE]
                and Constants.FOOD_BLAND
            or Constants.FOOD_NEUTRAL,
        romanceStyle = selected[Constants.TRAIT_IDS.RESERVED]
                and Constants.ROMANCE_RESERVED
            or selected[Constants.TRAIT_IDS.FLIRTY]
                and Constants.ROMANCE_FLIRTY
            or Constants.ROMANCE_NEUTRAL,
        jealousyStyle = selected[Constants.TRAIT_IDS.JEALOUS]
                and Constants.JEALOUSY_JEALOUS
            or selected[Constants.TRAIT_IDS.UNPOSSESSIVE]
                and Constants.JEALOUSY_UNPOSSESSIVE
            or Constants.JEALOUSY_NORMAL,
        socialStyle = selected[Constants.TRAIT_IDS.FRIENDLY]
                and Constants.SOCIAL_FRIENDLY
            or selected[Constants.TRAIT_IDS.WITHDRAWN]
                and Constants.SOCIAL_WITHDRAWN
            or Constants.SOCIAL_NEUTRAL,
        sourceTraits = sourceTraits,
    })
    return profile, conflicts, SocialTraits.Fingerprint(sourceTraits)
end

local function engineTraitFor(resource)
    local location
    local ok
    local trait
    if not CharacterTrait or not ResourceLocation
        or not ResourceLocation.of
    then
        return nil, "api_unavailable"
    end
    ok, location = pcall(ResourceLocation.of, resource)
    if not ok or not location then
        return nil, "invalid_resource"
    end
    if CharacterTrait.get then
        ok, trait = pcall(CharacterTrait.get, location)
        if not ok then
            trait = nil
        end
    end
    if not trait and CharacterTrait.register then
        ok, trait = pcall(CharacterTrait.register, resource)
        if not ok then
            return nil, tostring(trait)
        end
    end
    return trait
end

function SocialTraits.Register()
    local traits = {}
    local trait
    local existing
    local ok
    local left
    local right
    if not CharacterTrait
        or not CharacterTraitDefinition
        or not CharacterTraitDefinition.addCharacterTraitDefinition
    then
        return false, "api_unavailable"
    end
    for index = 1, #Constants.TRAIT_DEFINITIONS do
        definition = Constants.TRAIT_DEFINITIONS[index]
        trait = SocialTraits.EngineTraits[definition.id]
        if not trait then
            trait = engineTraitFor(definition.resource)
        end
        if not trait then
            return false, "trait_registration_failed:" .. definition.id
        end
        SocialTraits.EngineTraits[definition.id] = trait
        traits[definition.id] = trait
        existing = CharacterTraitDefinition.getCharacterTraitDefinition
            and CharacterTraitDefinition.getCharacterTraitDefinition(trait)
            or nil
        if not existing then
            ok, existing = pcall(
                CharacterTraitDefinition.addCharacterTraitDefinition,
                trait,
                definition.uiName,
                definition.cost,
                definition.uiDescription,
                false,
                false
            )
            if not ok or not existing then
                return false, "definition_registration_failed:"
                    .. definition.id
            end
        end
    end
    for index = 1, #Constants.EXCLUSION_GROUPS do
        left = traits[Constants.EXCLUSION_GROUPS[index][1]]
        right = traits[Constants.EXCLUSION_GROUPS[index][2]]
        if left and right
            and CharacterTraitDefinition.setMutualExclusive
        then
            CharacterTraitDefinition.setMutualExclusive(left, right)
        end
    end
    SocialTraits.Registered = true
    if PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialProfiles == true
        and PNC.Core
        and PNC.Core.LogDebug
    then
        PNC.Core.LogDebug(
            "[PNC SocialProfile] kind=trait_registration"
            .. " result=registered count="
            .. tostring(#Constants.TRAIT_DEFINITIONS)
        )
    end
    return true, "registered"
end

-- Shared bootstrap runs before the character-creation screen is built. The
-- guarded call is also safe in developer Lua tests without engine classes.
SocialTraits.Register()
if Events
    and Events.OnGameBoot
    and not SocialTraits.GameBootHookRegistered
then
    Events.OnGameBoot.Add(SocialTraits.Register)
    SocialTraits.GameBootHookRegistered = true
end

return SocialTraits
