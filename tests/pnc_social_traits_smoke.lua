local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local CLIENT_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

local function assertSaveSafe(value, seen)
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
        assertSaveSafe(key, seen)
        assertSaveSafe(item, seen)
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

PNC = {}
dofile(ROOT .. "Identity/PNC_Identity.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
dofile(ROOT .. "Relationships/PNC_SocialTraits.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileMath.lua")

local Constants = PNC.SocialProfileConstants
local Traits = PNC.SocialTraits
local Math = PNC.SocialProfileMath
local T = Constants.TRAIT_IDS

-- Build 42 registration, point values, and engine-level exclusions.
assertTrue(Traits.Registered, "traits registered")
assertEqual(#gameBootCallbacks, 1, "game boot registration fallback")
assertEqual(#Traits.GetDefinitions(), 10, "ten trait definitions")
for _, spec in ipairs(Constants.TRAIT_DEFINITIONS) do
    local trait = Traits.EngineTraits[spec.id]
    local definition = engineDefinitions[trait]
    assertTrue(trait ~= nil, spec.id .. " engine trait")
    assertTrue(definition ~= nil, spec.id .. " engine definition")
    assertEqual(definition.cost, spec.cost, spec.id .. " cost")
    assertEqual(definition.isProfession, false,
        spec.id .. " normal trait")
    assertEqual(definition.disabledInMP, false,
        spec.id .. " multiplayer enabled")
end
assertEqual(Traits.GetDefinition(T.FRIENDLY).cost, 2,
    "Friendly costs two points")
assertEqual(Traits.GetDefinition(T.WITHDRAWN).cost, -2,
    "Withdrawn grants two points")
for _, group in ipairs(Constants.EXCLUSION_GROUPS) do
    local left = Traits.EngineTraits[group[1]]
    local right = Traits.EngineTraits[group[2]]
    assertTrue(engineDefinitions[left].exclusions[right],
        group[1] .. " excludes " .. group[2])
    assertTrue(engineDefinitions[right].exclusions[left],
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
assertEqual(repeatCount, definitionCount, "registration idempotent")

-- Build 42.20's vanilla trait lists exclude cost-zero definitions. The
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
dofile(
    CLIENT_ROOT
        .. "Patches/PNC_SocialTraitCharacterCreationPatch.lua"
)
local screen = setmetatable(
    {},
    { __index = CharacterCreationProfession }
)
screen:populateTraitList(list)
assertEqual(populateCalls, 1, "vanilla population preserved")
assertEqual(#list.items, 8, "all zero-point traits visible")
for _, entry in ipairs(list.items) do
    assertEqual(entry.item:getCost(), 0,
        "UI adapter adds zero-cost traits only")
end
dofile(
    CLIENT_ROOT
        .. "Patches/PNC_SocialTraitCharacterCreationPatch.lua"
)
screen:populateTraitList(list)
assertEqual(populateCalls, 2, "UI adapter idempotent")
assertEqual(#list.items, 8, "UI adapter avoids duplicates")

-- Default and each individual trait resolve to canonical primitive profile.
local defaults = Traits.ResolveTraits({})
assertEqual(defaults.orientation, "straight", "default orientation")
assertEqual(defaults.foodPreference, "neutral", "default food")
assertEqual(defaults.romanceStyle, "neutral", "default romance")
assertEqual(defaults.jealousyStyle, "normal", "default jealousy")
assertEqual(defaults.socialStyle, "neutral", "default social")

assertEqual(Traits.ResolveTraits({ [T.GAY] = true }).orientation,
    "gay", "Gay resolution")
assertEqual(Traits.ResolveTraits({ [T.BISEXUAL] = true }).orientation,
    "bisexual", "Bisexual resolution")
assertEqual(Traits.ResolveTraits({ [T.BLAND_PALATE] = true })
    .foodPreference, "bland", "Bland Palate resolution")
assertEqual(Traits.ResolveTraits({ [T.SPICE_LOVER] = true })
    .foodPreference, "spicy", "Spice Lover resolution")
assertEqual(Traits.ResolveTraits({ [T.FLIRTY] = true })
    .romanceStyle, "flirty", "Flirty resolution")
assertEqual(Traits.ResolveTraits({ [T.RESERVED] = true })
    .romanceStyle, "reserved", "Reserved resolution")
assertEqual(Traits.ResolveTraits({ [T.JEALOUS] = true })
    .jealousyStyle, "jealous", "Jealous resolution")
assertEqual(Traits.ResolveTraits({ [T.UNPOSSESSIVE] = true })
    .jealousyStyle, "unpossessive", "Unpossessive resolution")
assertEqual(Traits.ResolveTraits({ [T.FRIENDLY] = true })
    .socialStyle, "friendly", "Friendly resolution")
assertEqual(Traits.ResolveTraits({ [T.WITHDRAWN] = true })
    .socialStyle, "withdrawn", "Withdrawn resolution")

local conflictProfile, conflicts = Traits.ResolveTraits({
    [T.GAY] = true,
    [T.BISEXUAL] = true,
    [T.BLAND_PALATE] = true,
    [T.SPICE_LOVER] = true,
    [T.FLIRTY] = true,
    [T.RESERVED] = true,
    [T.JEALOUS] = true,
    [T.UNPOSSESSIVE] = true,
    [T.FRIENDLY] = true,
    [T.WITHDRAWN] = true,
})
assertEqual(conflictProfile.orientation, "bisexual",
    "orientation precedence")
assertEqual(conflictProfile.foodPreference, "spicy",
    "food precedence")
assertEqual(conflictProfile.romanceStyle, "reserved",
    "romance precedence")
assertEqual(conflictProfile.jealousyStyle, "jealous",
    "jealousy precedence")
assertEqual(conflictProfile.socialStyle, "friendly",
    "social precedence")
assertEqual(#conflicts, 5, "all conflicts reported")
assertEqual(conflictProfile.sourceTraits[T.GAY], nil,
    "discarded contradiction not persisted")

local mixed = Traits.ResolveTraits({
    "pnc:pnc_gay",
    "pnc_spicelover",
    "PNC_Reserved",
    "PNC_Unpossessive",
    "PNC_Friendly",
})
assertEqual(mixed.orientation, "gay", "resource alias accepted")
assertEqual(mixed.foodPreference, "spicy",
    "separate groups coexist")
assertEqual(mixed.romanceStyle, "reserved",
    "separate romance group")
assertEqual(mixed.jealousyStyle, "unpossessive",
    "separate jealousy group")
assertEqual(mixed.socialStyle, "friendly",
    "separate social group")
assertSaveSafe(mixed)

-- Orientation compatibility is pure and requires both sides for mutual use.
local straight = { orientation = "straight" }
local gay = { orientation = "gay" }
local bisexual = { orientation = "bisexual" }
assertTrue(Math.IsGenderCompatible(straight, "male", "female"),
    "straight other gender")
assertEqual(Math.IsGenderCompatible(straight, "male", "male"),
    false, "straight same gender")
assertTrue(Math.IsGenderCompatible(gay, "female", "female"),
    "gay same gender")
assertEqual(Math.IsGenderCompatible(gay, "female", "male"),
    false, "gay other gender")
assertTrue(Math.IsGenderCompatible(bisexual, "male", "male"),
    "bisexual same gender")
assertTrue(Math.IsGenderCompatible(bisexual, "male", "female"),
    "bisexual other gender")
assertEqual(Math.AreMutuallyOrientationCompatible(
    straight, "male", gay, "female"
), false, "mutual compatibility requires both")
assertTrue(Math.AreMutuallyOrientationCompatible(
    bisexual, "male", bisexual, "female"
), "mutual bisexual compatibility")
assertEqual(Math.IsGenderCompatible(straight, "unknown", "female"),
    false, "invalid gender safe")

print("pnc_social_traits_smoke: ok")
