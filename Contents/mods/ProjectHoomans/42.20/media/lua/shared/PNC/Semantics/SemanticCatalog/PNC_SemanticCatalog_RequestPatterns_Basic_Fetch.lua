-- Fetch request pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog request spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog request spoke requires RegisterPattern")
end

function Internal.RegisterFetchRequests()
    registerPattern(
        "pnc.request.fetch",
        {
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "could", optional = true },
            { kind = "literal", value = "would", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                -- Keep prepositions available to compositional patterns such
                -- as FETCH ... TO ... instead of letting the generic object
                -- slot greedily consume the destination.
                stopWords = { "to", "from", "please", "now" },
            },
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
                quantity = "SOME",
            },
        },
        0.94,
        100,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.request.want_you_fetch",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "want" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "to" },
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = {
                    "to", "from", "please", "now", "not", "if",
                    "because", "when", "unless", "but",
                },
            },
            { kind = "literal", value = "please", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
                quantity = "SOME",
            },
        },
        0.95,
        101,
        { allowFuzzyCapture = true }
    )
end

return Internal

