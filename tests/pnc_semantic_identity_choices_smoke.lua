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
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider.lua"
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
T.equal(#choices, 3, "pending identity exposes exactly three choices")
T.equal(choices[1].id, "identity.choice.real_name", "real name choice")
T.equal(choices[2].id, "identity.choice.refuse_name", "refusal choice")
T.equal(choices[3].id, "identity.choice.lie_name", "lie choice")
T.equal(choices[1].frame.socialContext.identityClaim, true,
    "real name uses the identity claim route")
T.equal(choices[1].frame.extensions.identityClaimMode, "canonical",
    "real name is server-resolved")
T.equal(choices[2].frame.intent, "REFUSE", "refusal remains an evasion")
T.equal(choices[2].frame.extensions.identityResponseStyle, "rude",
    "refusal carries the bounded rude presentation style")
T.equal(choices[3].frame.extensions.identityClaimMode, "generated",
    "lie uses a generated claim mode")
T.truthy(choices[3].frame.slots.identityClaim.name,
    "lie carries a generated alias")
T.truthy(string.find(choices[3].frame.slots.identityClaim.name,
    "Native", 1, true) ~= nil, "native SurvivorFactory pools are used")
T.equal(factoryCalls, 0, "alias generation never calls CreateSurvivor")

local second = Provider.collect(context)
T.equal(second[3].frame.slots.identityClaim.name,
    choices[3].frame.slots.identityClaim.name,
    "alias is stable for the same save and identity seed")

T.finish("pnc_semantic_identity_choices_smoke")
