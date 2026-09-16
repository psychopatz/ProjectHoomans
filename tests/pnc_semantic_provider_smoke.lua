local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)

local sourceDiagnostics = {}
local ir, reason = Semantic.Provider.Normalize({
    semantic_ir = {
        intent = "REQUEST",
        speech_act = "REQUEST",
        action = "FETCH",
        object = { category = "WATER", quantity = "SOME" },
        confidence = 0.91,
        diagnostics = sourceDiagnostics,
    },
}, {
    rawText = "Could you fetch water?",
    actor = { id = "player:one" },
    recipient = { id = "npc:alice" },
}, {
    provider = "llm",
})
T.truthy(ir, "provider payload becomes Semantic IR")
T.equal(reason, nil, "valid provider payload has no reason")
T.equal(ir.intent, "REQUEST", "provider intent is normalized")
T.equal(ir.speechAct, "REQUEST", "snake-case speech act is normalized")
T.equal(ir.object.category, "WATER", "provider object is preserved")
T.equal(ir.actor.id, "player:one", "context actor is attached")
T.equal(ir.recipient.id, "npc:alice", "context recipient is attached")
T.equal(ir.rawText, "Could you fetch water?",
    "context raw text fills the provider contract")
T.equal(ir.provenance.provider, "llm",
    "provider provenance is explicit")
T.equal(ir.diagnostics.providerNormalized, true,
    "normalization diagnostics are retained")
T.falsy(sourceDiagnostics.providerNormalized,
    "provider normalization does not mutate the wire payload")

local malformed, malformedReason = Semantic.Provider.Normalize({
    semantic_ir = {
        intent = 7,
        confidence = 0.90,
    },
})
T.falsy(malformed, "malformed provider IR is rejected")
T.equal(malformedReason, "invalid_intent",
    "provider validation returns the concrete reason")

T.finish("pnc_semantic_provider_smoke")
