local T = require "tests/support/test"

PNC = {
    IdentityNames = {
        Generate = function() return "Test Survivor" end,
    },
}

local visual = {
    getSkinColor = function()
        return { getRedFloat = function() return 0.41 end,
            getGreenFloat = function() return 0.29 end,
            getBlueFloat = function() return 0.18 end }
    end,
    getHairColor = function()
        return { getRedFloat = function() return 0.11 end,
            getGreenFloat = function() return 0.06 end,
            getBlueFloat = function() return 0.02 end }
    end,
    getHairModel = function() return "Short" end,
    getBeardModel = function() return nil end,
    getSkinTexture = function() return "MaleBody02" end,
}

local descriptor = {
    getHumanVisual = function() return visual end,
    isFemale = function() return false end,
    setFemale = function() end,
    getForename = function() return "Test" end,
    getSurname = function() return "Survivor" end,
    getVoicePrefix = function() return "Male" end,
}

SurvivorType = { Neutral = 1 }
SurvivorFactory = {
    CreateSurvivor = function() return descriptor end,
}

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Factory.lua")

local playerAppearance = T.truthy(
    PNC.Identity.GetCharacterAppearance({
        getHumanVisual = function() return visual end,
    }),
    "player appearance is read from HumanVisual"
)
T.equal(playerAppearance.skinColor.r, 0.41,
    "player skin color is captured")
T.equal(playerAppearance.hairColor.b, 0.02,
    "player hair color is captured")
T.equal(playerAppearance.skinTexture, "MaleBody02",
    "player skin texture is captured")

local identity = T.truthy(PNC.Identity.GenerateResolvedIdentity({
    id = "npc_family_test",
    isFemale = false,
    identitySeed = 7,
}), "resolved identity is generated")
T.equal(identity.survivor.skinColor.g, 0.29,
    "generated identity stores skin color")
T.equal(identity.survivor.hairColor.r, 0.11,
    "generated identity stores hair color")
T.equal(identity.survivor.skinTexture, "MaleBody02",
    "generated identity stores skin texture")

T.finish("pnc_family_appearance_smoke")
