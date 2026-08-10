-- Build 42 social-trait catalog, registration, and pure profile resolution.

if not PsychopatzCore or not PsychopatzCore.Traits then
    require "PsychopatzCore/Traits/PsychopatzTraitRegistry"
end

PNC = PNC or {}
PNC.SocialTraits = PNC.SocialTraits or {}

local SocialTraits = PNC.SocialTraits
local Constants = PNC.SocialProfileConstants
local ProfileTypes = PNC.SocialProfileTypes
local CoreTraits = PsychopatzCore.Traits

SocialTraits.EngineTraits = CoreTraits.EngineTraits
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

function SocialTraits.Register()
    local registered, reason = CoreTraits.RegisterCatalog(
        "ProjectHoomans.Social",
        Constants.TRAIT_DEFINITIONS,
        Constants.EXCLUSION_GROUPS
    )
    SocialTraits.Registered = registered == true
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
    return registered, reason
end

-- Shared bootstrap runs before the character-creation screen is built. The
-- guarded call is also safe in developer Lua tests without engine classes.
SocialTraits.Register()

return SocialTraits
