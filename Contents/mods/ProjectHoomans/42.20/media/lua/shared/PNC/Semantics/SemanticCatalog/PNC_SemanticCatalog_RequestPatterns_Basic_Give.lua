-- Give request pattern registrations.
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

function Internal.RegisterGiveRequests()
    registerPattern(
        "pnc.request.give",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "could", optional = true },
            { kind = "literal", value = "would", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "GIVE" },
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
                stopWords = { "to", "from", "please", "now" },
            },
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GIVE",
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
        110,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.request.give_to_me",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "could", optional = true },
            { kind = "literal", value = "would", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "GIVE" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "to", "from", "please", "now" },
            },
            { kind = "literal", value = "to" },
            { kind = "literal", value = "me" },
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GIVE",
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
        0.96,
        112,
        { allowFuzzyCapture = true }
    )
end

return Internal

