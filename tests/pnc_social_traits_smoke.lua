local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local CLIENT_ROOT =
    T.path("ProjectHoomans", "client", "PNC/")
local function validatePersistedValue(value, seen)
    local valueType = type(value)
    local key
    local item
    if valueType == "nil"
        or valueType == "string"
        or valueType == "number"
        or valueType == "boolean"
    then
        return
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        error("unsafe social trait profile value: " .. valueType)
    end
    seen = seen or {}
    if seen[value] then error("profile cycle") end
    seen[value] = true
    for key, item in pairs(value) do
        validatePersistedValue(key, seen)
        validatePersistedValue(item, seen)
    end
    seen[value] = nil
end

local engineTraits = {}
local engineDefinitions = {}
local gameBootCallbacks = {}

Events = {
    OnGameBoot = {
        Add = function(callback)
            gameBootCallbacks[#gameBootCallbacks + 1] = callback
        end,
    },
}

ResourceLocation = {
    of = function(value)
        return string.lower(tostring(value))
    end,
}

CharacterTrait = {
    get = function(location)
        return engineTraits[location]
    end,
    register = function(resource)
        resource = string.lower(tostring(resource))
        local trait = engineTraits[resource]
        if not trait then
            trait = {
                resource = resource,
                getName = function(self)
                    return string.match(self.resource, ":(.+)$")
                end,
                toString = function(self)
                    return self.resource
                end,
            }
            engineTraits[resource] = trait
        end
        return trait
    end,
}

CharacterTraitDefinition = {
    getCharacterTraitDefinition = function(trait)
        return engineDefinitions[trait]
    end,
    addCharacterTraitDefinition = function(
        trait,
        uiName,
        cost,
        uiDescription,
        isProfession,
        disabledInMP
    )
        local definition = {
            trait = trait,
            uiName = uiName,
            cost = cost,
            uiDescription = uiDescription,
            isProfession = isProfession,
            disabledInMP = disabledInMP,
            exclusions = {},
            getLabel = function(self)
                return self.uiName
            end,
            getDescription = function(self)
                return self.uiDescription
            end,
            getCost = function(self)
                return self.cost
            end,
            isFree = function(self)
                return self.isProfession
            end,
        }
        engineDefinitions[trait] = definition
        return definition
    end,
    setMutualExclusive = function(left, right)
        engineDefinitions[left].exclusions[right] = true
        engineDefinitions[right].exclusions[left] = true
    end,
}

T.load(T.path("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"))
PNC = {}
T.load(ROOT .. "Identity/PNC_Identity.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
T.load(ROOT .. "Relationships/PNC_SocialTraits.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileMath.lua")

local Constants = PNC.SocialProfileConstants
local Traits = PNC.SocialTraits
local Math = PNC.SocialProfileMath
local TraitIds = Constants.TRAIT_IDS

-- Registration, point values, and engine-level exclusions.
T.truthy(Traits.Registered, "traits registered")
T.equal(#gameBootCallbacks, 1, "game boot registration fallback")
T.equal(#Traits.GetDefinitions(), 10, "ten trait definitions")
for _, spec in ipairs(Constants.TRAIT_DEFINITIONS) do
    local trait = Traits.EngineTraits[spec.id]
    local definition = engineDefinitions[trait]
    T.truthy(trait ~= nil, spec.id .. " engine trait")
    T.truthy(definition ~= nil, spec.id .. " engine definition")
    T.equal(definition.cost, spec.cost, spec.id .. " cost")
    T.equal(definition.isProfession, false,
        spec.id .. " normal trait")
    T.equal(definition.disabledInMP, false,
        spec.id .. " multiplayer enabled")
end
T.equal(Traits.GetDefinition(TraitIds.FRIENDLY).cost, 2,
    "Friendly costs two points")
T.equal(Traits.GetDefinition(TraitIds.WITHDRAWN).cost, -2,
    "Withdrawn grants two points")
for _, group in ipairs(Constants.EXCLUSION_GROUPS) do
    local left = Traits.EngineTraits[group[1]]
    local right = Traits.EngineTraits[group[2]]
    T.truthy(engineDefinitions[left].exclusions[right],
        group[1] .. " excludes " .. group[2])
    T.truthy(engineDefinitions[right].exclusions[left],
        group[2] .. " excludes " .. group[1])
end
local definitionCount = 0
for _, _ in pairs(engineDefinitions) do
    definitionCount = definitionCount + 1
end
Traits.Register()
gameBootCallbacks[1]()
local repeatCount = 0
for _, _ in pairs(engineDefinitions) do repeatCount = repeatCount + 1 end
T.equal(repeatCount, definitionCount, "registration idempotent")

-- Starting relationships are independent two-point traits backed by the same
-- Core registry, allowing any combination of family, lover, and friend.
T.load(ROOT .. "Traits/PNC_StartingCompanionTraits.lua")
local StartingTraits = PNC.StartingCompanionTraits
T.equal(#StartingTraits.DEFINITIONS, 6, "six starting companion traits")
T.equal(#StartingTraits.EXCLUSIONS, 0,
    "starting companion traits are not mutually exclusive")
local englishCatalog = T.read(
    "ProjectHoomans", "common_lua", "Translate/EN/UI.json"
)
for _, spec in ipairs(StartingTraits.DEFINITIONS) do
    local trait = PsychopatzCore.Traits.EngineTraits[spec.id]
    T.equal(engineDefinitions[trait].cost, 2,
        spec.id .. " costs two points")
    T.equal(engineDefinitions[trait].disabledInMP, false,
        spec.id .. " multiplayer enabled")
    T.truthy(string.find(
        englishCatalog, '"' .. spec.uiName .. '"', 1, true
    ) ~= nil, spec.id .. " has translated name")
    T.truthy(string.find(
        englishCatalog, '"' .. spec.uiDescription .. '"', 1, true
    ) ~= nil, spec.id .. " has translated description")
end
local loverSpec = StartingTraits.GetDefinition(StartingTraits.IDS.LOVER)
T.truthy(StartingTraits.ResolveCompanionFemale(
    loverSpec, true, "gay", false
), "gay female survivor receives female lover")
T.equal(StartingTraits.ResolveCompanionFemale(
    loverSpec, false, "straight", false
), true, "straight male survivor receives female lover")
T.equal(StartingTraits.ResolveCompanionFemale(
    loverSpec, false, "bisexual", false
), false, "bisexual lover follows deterministic roll")

-- The vanilla trait lists exclude cost-zero definitions. The
-- client adapter keeps the standard screen and adds only PNC's eight
-- zero-point definitions to its normal positive-trait list.
local populateCalls = 0
local list = {
    items = {},
    addUniqueItem = function(self, label, item, description)
        local itemIndex
        for itemIndex = 1, #self.items do
            if self.items[itemIndex].item == item then
                return self.items[itemIndex]
            end
        end
        self.items[#self.items + 1] = {
            label = label,
            item = item,
            description = description,
        }
        return self.items[#self.items]
    end,
}
CharacterCreationProfession = {
    populateTraitList = function(_, target)
        populateCalls = populateCalls + 1
        target.items = {}
    end,
    isTraitEnabled = function()
        return true
    end,
    isTraitExcluded = function()
        return false
    end,
}
package.preload["OptionScreens/CharacterCreationProfession"] =
    function()
        return CharacterCreationProfession
    end
T.load(T.path("PsychopatzCore", "client", "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation.lua"))
T.load(
    CLIENT_ROOT
        .. "Patches/PNC_SocialTraitCharacterCreationPatch.lua"
)
local screen = setmetatable(
    {},
    { __index = CharacterCreationProfession }
)
screen:populateTraitList(list)
T.equal(populateCalls, 1, "vanilla population preserved")
T.equal(#list.items, 8, "all zero-point traits visible")
for _, entry in ipairs(list.items) do
    T.equal(entry.item:getCost(), 0,
        "UI adapter adds zero-cost traits only")
end
T.load(
    CLIENT_ROOT
        .. "Patches/PNC_SocialTraitCharacterCreationPatch.lua"
)
screen:populateTraitList(list)
T.equal(populateCalls, 2, "UI adapter idempotent")
T.equal(#list.items, 8, "UI adapter avoids duplicates")

-- Default and each individual trait resolve to canonical primitive profile.
local defaults = Traits.ResolveTraits({})
T.equal(defaults.orientation, "straight", "default orientation")
T.equal(defaults.foodPreference, "neutral", "default food")
T.equal(defaults.romanceStyle, "neutral", "default romance")
T.equal(defaults.jealousyStyle, "normal", "default jealousy")
T.equal(defaults.socialStyle, "neutral", "default social")

T.equal(Traits.ResolveTraits({ [TraitIds.GAY] = true }).orientation,
    "gay", "Gay resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.BISEXUAL] = true }).orientation,
    "bisexual", "Bisexual resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.BLAND_PALATE] = true })
    .foodPreference, "bland", "Bland Palate resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.SPICE_LOVER] = true })
    .foodPreference, "spicy", "Spice Lover resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.FLIRTY] = true })
    .romanceStyle, "flirty", "Flirty resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.RESERVED] = true })
    .romanceStyle, "reserved", "Reserved resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.JEALOUS] = true })
    .jealousyStyle, "jealous", "Jealous resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.UNPOSSESSIVE] = true })
    .jealousyStyle, "unpossessive", "Unpossessive resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.FRIENDLY] = true })
    .socialStyle, "friendly", "Friendly resolution")
T.equal(Traits.ResolveTraits({ [TraitIds.WITHDRAWN] = true })
    .socialStyle, "withdrawn", "Withdrawn resolution")

local conflictProfile, conflicts = Traits.ResolveTraits({
    [TraitIds.GAY] = true,
    [TraitIds.BISEXUAL] = true,
    [TraitIds.BLAND_PALATE] = true,
    [TraitIds.SPICE_LOVER] = true,
    [TraitIds.FLIRTY] = true,
    [TraitIds.RESERVED] = true,
    [TraitIds.JEALOUS] = true,
    [TraitIds.UNPOSSESSIVE] = true,
    [TraitIds.FRIENDLY] = true,
    [TraitIds.WITHDRAWN] = true,
})
T.equal(conflictProfile.orientation, "bisexual",
    "orientation precedence")
T.equal(conflictProfile.foodPreference, "spicy",
    "food precedence")
T.equal(conflictProfile.romanceStyle, "reserved",
    "romance precedence")
T.equal(conflictProfile.jealousyStyle, "jealous",
    "jealousy precedence")
T.equal(conflictProfile.socialStyle, "friendly",
    "social precedence")
T.equal(#conflicts, 5, "all conflicts reported")
T.equal(conflictProfile.sourceTraits[TraitIds.GAY], nil,
    "discarded contradiction not persisted")

local mixed = Traits.ResolveTraits({
    "pnc:pnc_gay",
    "pnc_spicelover",
    "PNC_Reserved",
    "PNC_Unpossessive",
    "PNC_Friendly",
})
T.equal(mixed.orientation, "gay", "resource alias accepted")
T.equal(mixed.foodPreference, "spicy",
    "separate groups coexist")
T.equal(mixed.romanceStyle, "reserved",
    "separate romance group")
T.equal(mixed.jealousyStyle, "unpossessive",
    "separate jealousy group")
T.equal(mixed.socialStyle, "friendly",
    "separate social group")
validatePersistedValue(mixed)

-- Orientation compatibility is pure and requires both sides for mutual use.
local straight = { orientation = "straight" }
local gay = { orientation = "gay" }
local bisexual = { orientation = "bisexual" }
T.truthy(Math.IsGenderCompatible(straight, "male", "female"),
    "straight other gender")
T.equal(Math.IsGenderCompatible(straight, "male", "male"),
    false, "straight same gender")
T.truthy(Math.IsGenderCompatible(gay, "female", "female"),
    "gay same gender")
T.equal(Math.IsGenderCompatible(gay, "female", "male"),
    false, "gay other gender")
T.truthy(Math.IsGenderCompatible(bisexual, "male", "male"),
    "bisexual same gender")
T.truthy(Math.IsGenderCompatible(bisexual, "male", "female"),
    "bisexual other gender")
T.equal(Math.AreMutuallyOrientationCompatible(
    straight, "male", gay, "female"
), false, "mutual compatibility requires both")
T.truthy(Math.AreMutuallyOrientationCompatible(
    bisexual, "male", bisexual, "female"
), "mutual bisexual compatibility")
T.equal(Math.IsGenderCompatible(straight, "unknown", "female"),
    false, "invalid gender safe")
T.finish("pnc_social_traits_smoke")

T.finish("pnc_social_traits_smoke")
