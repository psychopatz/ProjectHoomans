local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Router = Semantic.DialogueRouter

local router = Router.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    policy = Policy,
    context = {
        llmEnabled = false,
        identityState = "known",
        npcName = "Mara Hale",
        npcFullName = "Mara Hale",
    },
})

local request = router:Process(
    "Can you bring me some water?",
    nil,
    { timestamp = 100 }
)
T.equal(request.decision.branch, "REQUEST_ACKNOWLEDGED",
    "request keeps its deterministic semantic branch")

local accepted = router:Preview("Sure", nil, { timestamp = 200 })
T.equal(accepted.decision.branch, "SOCIAL_ACKNOWLEDGED",
    "acceptance is evaluated as a social act")
T.equal(accepted.decision.response.fallback,
    "All right, I'll take care of it.",
    "acceptance responds to the pending request")
T.equal(router:Snapshot().sequence, 1,
    "previewing a response does not record a second event")

local acceptedResult = router:Process("Sure", nil, { timestamp = 250 })
T.equal(acceptedResult.decision.response.fallback,
    "All right, I'll take care of it.",
    "recorded acceptance composes before completing the request")
T.equal(router:Snapshot().pendingRequest, nil,
    "recorded acceptance completes the pending request")

local repeatedAccept = router:Preview("Sure", nil, { timestamp = 275 })
T.equal(repeatedAccept.decision.response.fallback, "All right.",
    "a completed request does not leak into the next turn")

local thanks = router:Process("Thanks", nil, { timestamp = 300 })
T.equal(thanks.decision.response.fallback, "You're welcome.",
    "thanks receives a local social response")

local identity = router:Preview(
    "Who are you?",
    nil,
    { timestamp = 400 }
)
T.equal(identity.ir.subject, "IDENTITY",
    "identity question is represented semantically")
T.equal(identity.decision.response.fallback,
    "I'm Mara Hale. What's your name?",
    "identity response uses authorized conversation context")

T.finish("pnc_semantic_state_response_smoke")
