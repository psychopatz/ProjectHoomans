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
local registered, response = Policy.RegisterResponse("TEST_BRANCH", {
    templateID = "semantic.test",
    fallback = "Test response.",
})
T.equal(registered, true, "response templates are data-driven")
T.equal(response.templateID, "semantic.test", "response template registration")

local state = Semantic.DialogueState.New({
    participants = { "player:one", "npc:alice" },
    maxEvents = 2,
})
local water = Semantic.Parser.Parse("Can you bring me some water?")
local recorded, event = state:Record(water, { timestamp = 100 })
T.equal(recorded, true, "water IR enters dialogue state")
T.equal(event.action, "FETCH", "state stores semantic action")
T.equal(event.object.category, "WATER", "state stores compact object")
T.equal(event.object.quantity, "SOME", "state stores object quantity")
T.equal(state.currentTopic, "FETCH", "state derives current topic")
T.equal(state.pendingRequest.object.category, "WATER",
    "request remains available for downstream cognition")

local follow = Semantic.Parser.Parse("Follow me.")
state:Record(follow, { timestamp = 200 })
T.equal(#state:Recent(nil, false), 2, "state history is bounded")
T.equal(state:Recent(nil, false)[1].action, "FETCH",
    "oldest bounded event remains ordered")
T.equal(state:Recent(1)[1].action, "FOLLOW",
    "newest event is available without full history")

local command = Policy.Decide(follow, state, { llmEnabled = false })
T.equal(command.route, "deterministic",
    "high-confidence command does not need LLM")
T.equal(command.branch, "COMMAND_ACCEPTED",
    "command selects a semantic branch")
T.equal(command.actionIntent.action, "FOLLOW",
    "policy returns an action intent only")
T.falsy(command.executed, "policy never executes gameplay")

local unknown = Semantic.Parser.Parse("Can you do something about this?")
local noLLM = Policy.Decide(unknown, state, { llmEnabled = false })
T.equal(noLLM.route, "deterministic",
    "game remains usable with LLM disabled")
T.equal(noLLM.branch, "ASK_CLARIFICATION",
    "unknown input gets a deterministic safe response")
T.equal(noLLM.response.templateID, "semantic.ask_clarification",
    "clarification is represented as a response template")

local llmFallback = Policy.Decide(unknown, state, { llmEnabled = true })
T.equal(llmFallback.route, "llm_fallback",
    "LLM is only selected for low-confidence input")
T.equal(llmFallback.actionIntent, nil,
    "ambiguous input cannot create a gameplay action")

local question = Semantic.Parser.Parse("Where is John?")
local questionDecision = Policy.Decide(question, state, {
    llmEnabled = true,
})
T.equal(questionDecision.route, "deterministic",
    "unresolved references can clarify without forcing an LLM call")
T.equal(questionDecision.branch, "QUESTION_RECEIVED",
    "read-only location questions reach the local fact responder")
T.equal(questionDecision.response.templateID,
    "semantic.question.location_unknown",
    "unknown locations receive an explicit uncertainty response")
T.equal(questionDecision.actionIntent, nil,
    "a local fact question never creates a gameplay action")

local referenceIR = Semantic.IR.New({
    rawText = "Take this",
    normalizedText = "take this",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "TAKE",
    object = { reference = "THIS", unresolved = true },
    confidence = 0.90,
})
state:Record(referenceIR, { timestamp = 300 })
local resolved, resolveReason = state:ResolveReference({ reference = "THIS" })
T.equal(resolved.reference, "THIS", "state preserves pronoun reference")
T.equal(resolveReason, "last_object", "state exposes local reference reason")

local processedIR, processedDecision = Policy.Process(
    "Stop.",
    state,
    { llmEnabled = false },
    { timestamp = 400 }
)
T.equal(processedIR.action, "STOP", "policy process parses input")
T.equal(processedDecision.branch, "COMMAND_ACCEPTED",
    "policy process returns deterministic decision")

local routed = Router.New({
    policy = Policy,
    context = { llmEnabled = false },
    stateSpec = { maxEvents = 2 },
})
local preview = routed:Preview("Follow me.", nil, { timestamp = 450 })
T.equal(preview.accepted, true, "router previews parsed utterances")
T.equal(preview.decision.actionIntent.action, "FOLLOW",
    "preview exposes the deterministic action")
T.equal(routed:Snapshot().sequence, 0,
    "preview does not mutate dialogue state")
local routedResult = routed:Process("Follow me.", nil, { timestamp = 500 })
T.equal(routedResult.accepted, true, "router accepts parsed utterances")
T.equal(routedResult.decision.route, "deterministic",
    "router keeps high-confidence input in Lua")
T.equal(routedResult.decision.actionIntent.action, "FOLLOW",
    "router exposes the same semantic action intent")
T.equal(routedResult.sequence, 1, "router records a bounded state event")

local malformed = routed:ProcessIR({
    schemaVersion = 1,
    kind = "utterance",
    rawText = "bad",
    normalizedText = "bad",
    intent = 7,
    confidence = 0.90,
})
T.falsy(malformed.accepted, "malformed provider IR is rejected")
T.equal(malformed.reason, "invalid_intent",
    "IR validation explains malformed provider data")

local routedUnknown = routed:Process(
    "Can you do something about this?",
    nil,
    { timestamp = 600 }
)
T.equal(routedUnknown.decision.branch, "ASK_CLARIFICATION",
    "router provides a safe no-LLM branch")
T.equal(#routed:Snapshot().recentSemanticEvents, 2,
    "router state remains bounded")

T.finish("pnc_semantic_dialogue_smoke")
