-- Project Hoomans adapter for structured external semantic results.
-- The Core provider normalizes the wire payload; this module owns only the
-- PNC source identity and the router handoff contract.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Result = PNC.Semantics.LLMResult or {}
PNC.Semantics.LLMResult = Result

Result.VERSION = 1

function Result.DescribeContract()
    return {
        version = Result.VERSION,
        outputField = "semantic_ir",
        required = { "intent", "confidence" },
        fields = {
            intent = "string",
            speech_act = "string",
            action = "string",
            actor = "entity",
            recipient = "entity",
            target = "entity",
            object = "entity",
            source = "entity",
            destination = "entity",
            modifiers = "map",
            emotional_state = "map",
            social_context = "map",
            confidence = "number",
            diagnostics = "map",
        },
        rule = "Return semantic_ir for ambiguous meaning; keep gameplay effects out of the payload.",
    }
end

function Result.Normalize(payload, context, options)
    options = type(options) == "table" and options or {}
    local providerOptions = {}
    local key
    local value
    for key, value in pairs(options) do providerOptions[key] = value end
    providerOptions.provider = providerOptions.provider or "llm"
    providerOptions.parser = providerOptions.parser or "llm_semantic"
    return Semantic.Provider.Normalize(payload, context, providerOptions)
end

function Result.Process(router, payload, context, options)
    if not router or type(router.ProcessIR) ~= "function" then
        return nil, "semantic_router_unavailable"
    end
    local ir, reason = Result.Normalize(payload, context, options)
    if not ir then return nil, reason end
    return router:ProcessIR(ir, context, options), ir
end

return Result
