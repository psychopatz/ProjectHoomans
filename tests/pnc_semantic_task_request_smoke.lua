local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Contract = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)

local ir = Semantic.IR.New({
    rawText = "Can you bring me some water?",
    normalizedText = "can you bring me some water",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "FETCH",
    object = { category = "WATER", quantity = "SOME" },
    confidence = 0.94,
    provenance = { provider = "lua", parser = "deterministic" },
})
local request, reason = Contract.FromIR(ir, {
    requestID = "dialogue:1",
    rawText = ir.rawText,
    recipient = { id = "player:1" },
})

T.truthy(request, "semantic request is built from the common IR")
T.equal(reason, nil, "valid semantic request has no reason")
T.equal(request.kind, "semantic_task_request", "request kind is stable")
T.equal(request.requestID, "dialogue:1", "request identity is preserved")
T.equal(request.action, "FETCH", "task action is normalized")
T.equal(request.object.category, "WATER", "task object is preserved")
T.equal(request.recipient.id, "player:1", "context recipient is attached")
T.equal(request.rawText, ir.rawText, "raw text remains bounded and inspectable")

local valid, validationReason = Contract.Validate(request)
T.equal(valid, true, "normalized semantic request validates")
T.equal(validationReason, request, "validation returns the request")

local notRequest, notRequestReason = Contract.FromIR(
    Semantic.IR.New({
        rawText = "Thanks.", normalizedText = "thanks",
        intent = "THANK", speechAct = "THANK", confidence = 0.96,
    }),
    { requestID = "dialogue:2" }
)
T.falsy(notRequest, "social acts cannot become task requests")
T.equal(notRequestReason, "task_request_requires_request_intent",
    "non-request rejection is explicit")

local invalid, invalidReason = Contract.Normalize({
    kind = "semantic_task_request",
    schemaVersion = Contract.VERSION,
    intent = "REQUEST",
    action = "FETCH",
    rawText = "x",
    normalizedText = "x",
    confidence = 3,
})
T.truthy(invalid, "confidence is clamped before validation")
T.equal(invalid.confidence, 1, "confidence clamp is bounded")
T.equal(invalidReason, nil, "clamped confidence remains valid")

T.finish("pnc_semantic_task_request_smoke")
