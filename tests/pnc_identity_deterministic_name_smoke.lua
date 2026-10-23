local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Identity = {}, Semantics = {} }
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Names.lua")

local descriptor = {
    isFemale = function() return false end,
    setFemale = function(self, value) self.female = value end,
    getForename = function() return "FactoryRandom" end,
    getSurname = function() return "FactorySurname" end,
}
SurvivorFactory = {
    FemaleForenames = { "CoreNativeAda", "CoreNativeBea" },
    MaleForenames = { "CoreNativeCal", "CoreNativeDan" },
    Surnames = { "CoreNativeNorth", "CoreNativeSouth" },
    CreateSurvivor = function() return descriptor end,
}

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Factory.lua")

local source = {
    id = "npc_deterministic_name",
    identitySeed = "identity-seed-a",
    saveSeed = "save-seed-a",
    isFemale = false,
    archetypeID = "General",
}
local first = PNC.Identity.GenerateResolvedIdentity(source)
local second = PNC.Identity.GenerateResolvedIdentity(source)
T.equal(first.displayName, second.displayName,
    "NPC generated name is stable for save and identity seeds")
T.truthy(string.find(first.displayName, "CoreNative", 1, true) ~= nil,
    "NPC generated name uses the Core native catalog")
T.falsy(string.find(first.displayName, "Factory", 1, true) ~= nil,
    "NPC name does not inherit SurvivorFactory global random name")

local sharedSurname = PNC.Identity.GenerateResolvedIdentity({
    id = "npc_shared_surname",
    identitySeed = "identity-seed-shared",
    saveSeed = "save-seed-a",
    isFemale = false,
    surname = "RelativeFamily",
})
T.truthy(string.find(sharedSurname.displayName, "RelativeFamily", 1, true)
    ~= nil, "explicit surname override is retained")
T.falsy(string.find(sharedSurname.displayName, "FactorySurname", 1, true)
    ~= nil, "missing first name still comes from deterministic Core")

local sharedForename = PNC.Identity.GenerateResolvedIdentity({
    id = "npc_shared_forename",
    identitySeed = "identity-seed-shared",
    saveSeed = "save-seed-a",
    isFemale = false,
    firstName = "RelativeFirst",
})
T.truthy(string.find(sharedForename.displayName, "RelativeFirst", 1, true)
    ~= nil, "explicit first-name override is retained")
T.falsy(string.find(sharedForename.displayName, "FactorySurname", 1, true)
    ~= nil, "missing surname still comes from deterministic Core")

T.finish("pnc_identity_deterministic_name_smoke")
