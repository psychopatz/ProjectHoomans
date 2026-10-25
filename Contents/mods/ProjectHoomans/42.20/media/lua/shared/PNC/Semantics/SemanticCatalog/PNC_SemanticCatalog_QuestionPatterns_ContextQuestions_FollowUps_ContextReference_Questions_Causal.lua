-- Causal context-reference follow-up questions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic context-reference causal spoke requires Catalog.Internal")
end

if type(Internal.RegisterContextReferenceQuestion) ~= "function" then
    error("semantic context-reference causal spoke requires question core")
end

function Internal.RegisterContextReferenceCausalQuestions()
    -- These follow-ups must be answered from preceding authoritative facts;
    -- the resolver must not invent a cause when the fact is unknown.
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.why_is_it_so",
        {
            { kind = "literal", value = "why" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "so" },
        },
        0.98,
        129,
        "CAUSE"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.why_is_that",
        {
            { kind = "literal", value = "why" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "that", capture = "reference" },
        },
        0.98,
        129,
        "CAUSE"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.how_come",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "come" },
        },
        0.97,
        128,
        "CAUSE",
        false
    )
end

return Internal
