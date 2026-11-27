local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Identity = {}, Semantics = {} }
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_IdentityAlias.lua")

local factoryCalls = 0
SurvivorFactory = {
    FemaleForenames = { "NativeAda", "NativeBea" },
    MaleForenames = { "NativeCal", "NativeDan" },
    Surnames = { "NativeNorth", "NativeSouth" },
    CreateSurvivor = function()
        factoryCalls = factoryCalls + 1
        error("generated aliases must not create a native survivor")
    end,
}

local Provider = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/Suggestions/StaticProvider.lua"
)
local context = {
    characterUUID = "char_identity_choices",
    playerGender = "female",
    playerName = "Patrick Patz",
    saveSeed = "identity-save-a",
    semanticContextState = {
        pendingIdentityExchange = { kind = "PLAYER_NAME" },
    },
}
local choices = Provider.collect(context)
T.equal(#choices, 2, "pending identity exposes real name and refusal choices (lie button omitted)")
T.equal(choices[1].id, "identity.choice.real_name", "real name choice")
T.equal(choices[2].id, "identity.choice.refuse_name", "refusal choice")
T.equal(choices[1].frame.socialContext.identityClaim, true,
    "real name uses the identity claim route")
T.equal(choices[1].frame.extensions.identityClaimMode, "canonical",
    "real name is server-resolved")
T.equal(choices[2].frame.intent, "REFUSE", "refusal remains an evasion")
T.equal(choices[2].frame.extensions.identityResponseStyle, "rude",
    "refusal carries the bounded rude presentation style")
T.equal(factoryCalls, 0, "alias generation never calls CreateSurvivor")

T.finish("pnc_semantic_identity_choices_smoke")
