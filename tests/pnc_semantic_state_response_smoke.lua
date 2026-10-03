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
T.truthy(string.find(accepted.decision.response.fallback or "", "started", 1, true)
    or string.find(accepted.decision.response.fallback or "", "take care", 1, true),
    "acceptance responds to the pending request")
T.equal(router:Snapshot().sequence, 1,
    "previewing a response does not record a second event")

local acceptedResult = router:Process("Sure", nil, { timestamp = 250 })
T.truthy(string.find(acceptedResult.decision.response.fallback or "", "started", 1, true)
    or string.find(acceptedResult.decision.response.fallback or "", "take care", 1, true),
    "recorded acceptance composes before completing the request")
T.equal(router:Snapshot().pendingRequest, nil,
    "recorded acceptance completes the pending request")

local repeatedAccept = router:Preview("Sure", nil, { timestamp = 275 })
T.equal(repeatedAccept.decision.response.fallback, "All right.",
    "a completed request does not leak into the next turn")

local thanks = router:Process("Thanks", nil, { timestamp = 300 })
T.truthy(thanks.decision.response.templateID
    and (string.find(thanks.decision.response.templateID, "semantic.thanks", 1, true)
        or thanks.decision.response.templateID == "semantic.social.thanks_response"),
    "thanks receives a generated local social response")
T.truthy(thanks.decision.response.fallback ~= nil
    and thanks.decision.response.fallback ~= "",
    "thanks response keeps readable fallback text")

local identity = router:Preview(
    "Who are you?",
    nil,
    { timestamp = 400 }
)
T.equal(identity.ir.subject, "IDENTITY",
    "identity question is represented semantically")
T.truthy(string.find(string.lower(identity.decision.response.fallback or ""),
    "your name", 1, true),
    "identity response uses authorized conversation context")

T.finish("pnc_semantic_state_response_smoke")
