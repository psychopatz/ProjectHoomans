local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = { Semantics = {} }

local Result = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticLLMResult.lua"
)
local contract = Result.DescribeContract()
T.equal(contract.outputField, "semantic_ir",
    "LLM contract names the structured output field")
T.equal(contract.fields.confidence, "number",
    "LLM contract exposes confidence explicitly")

local ir, reason = Result.Normalize({
    semantic_ir = {
        intent = "QUESTION",
        speech_act = "QUESTION",
        subject = "LOCATION",
        target = { text = "john", unresolved = true },
        confidence = 0.72,
    },
}, {
    rawText = "Where did John go?",
})
T.truthy(ir, "LLM result uses the common Semantic IR")
T.equal(reason, nil, "valid LLM result has no reason")
T.equal(ir.provenance.provider, "llm", "LLM provenance is stable")
T.equal(ir.provenance.parser, "llm_semantic",
    "LLM parser provenance is stable")
T.equal(ir.target.unresolved, true,
    "LLM entity uncertainty remains in the IR")

local malformed, malformedReason = Result.Normalize({
    semantic_ir = { intent = 7, confidence = 0.72 },
})
T.falsy(malformed, "invalid LLM results are rejected")
T.equal(malformedReason, "invalid_intent",
    "invalid LLM results expose the validation reason")

T.finish("pnc_semantic_llm_result_smoke")
