local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsSharedCode = function() return true end },
}
PNC = { Semantics = {} }

local Predicates = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates.lua"
)
local Provider = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_CapabilityProvider.lua"
)

local function context(baseEstablished)
    return {
        baseEstablished = baseEstablished,
        actorAuthority = {
            owned = true,
            companion = true,
        },
        npcState = {
            activeBehavior = "idle",
            healthState = "healthy",
        },
    }
end

local unavailable = Predicates.Evaluate(
    Provider.Definitions.GO.constraints,
    context(false)
)
T.equal(unavailable.status, "rejected",
    "Go Home is rejected when no base has been established")
T.falsy(unavailable.allowed,
    "Go Home is not executable without a base")
T.truthy(Provider.Definitions.GO.showWhenUnavailable,
    "Go Home remains visible for an explanatory disabled state")
T.equal(Provider.Definitions.GO.unavailableReasonCode, "base_required",
    "Go Home exposes a stable availability reason code")

local available = Predicates.Evaluate(
    Provider.Definitions.GO.constraints,
    context(true)
)
T.equal(available.status, "allowed",
    "Go Home becomes eligible after a base is established")
T.truthy(available.allowed,
    "Go Home is executable when its base gate passes")

T.finish("pnc_semantic_suggestion_availability_smoke")
