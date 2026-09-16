local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Context = Semantic.Context
Context.ClearResolvers()

local ir = Semantic.IR.New({
    rawText = "Take this",
    normalizedText = "take this",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "TAKE",
    object = { reference = "THIS", unresolved = true },
    confidence = 0.90,
})

local registered = Context.RegisterResolver("resolve_this", function(value)
    return Semantic.IR.New({
        rawText = value.rawText,
        normalizedText = value.normalizedText,
        intent = value.intent,
        speechAct = value.speechAct,
        action = value.action,
        object = { id = "item:water" },
        confidence = value.confidence,
        diagnostics = value.diagnostics,
        provenance = value.provenance,
    })
end)
T.equal(registered, true, "context resolver registers")

local resolved, reason = Context.Resolve(ir, {})
T.truthy(resolved, "valid IR reaches context resolution")
T.equal(reason, nil, "valid context resolution has no reason")
T.equal(resolved.object.id, "item:water",
    "resolver may replace an unresolved reference")
T.equal(resolved.diagnostics.contextResolvers, 1,
    "resolver diagnostics remain attached")

local malformed, malformedReason = Context.Resolve({
    schemaVersion = 1,
    kind = "utterance",
    rawText = "bad",
    normalizedText = "bad",
    intent = 7,
    confidence = 0.90,
}, {})
T.falsy(malformed, "malformed context input is rejected")
T.equal(malformedReason, "invalid_intent",
    "context validation returns the concrete reason")

Context.ClearResolvers()
T.finish("pnc_semantic_context_smoke")
