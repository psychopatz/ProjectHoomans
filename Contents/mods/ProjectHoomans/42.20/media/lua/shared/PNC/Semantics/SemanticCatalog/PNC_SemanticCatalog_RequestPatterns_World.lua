-- World-directed fetch and help request patterns.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog pattern module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

function Internal.RegisterWorldRequests()
    registerPattern(
        "pnc.request.fetch_to",
        {
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "to" },
            },
            { kind = "literal", value = "to" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = "$capture.object",
            target = "$capture.target",
        },
        0.91,
        105
    )

    registerPattern(
        "pnc.request.fetch_from",
        {
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
                stopWords = { "from", "to", "please", "now" },
            },
            { kind = "literal", value = "from" },
            {
                kind = "any_phrase",
                capture = "source",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = "$capture.object",
            source = "$capture.source",
        },
        0.92,
        106
    )

    registerPattern(
        "pnc.request.help",
        {
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "concept", id = "HELP" },
            { kind = "literal", value = "me", optional = true },
            {
                kind = "any_phrase",
                capture = "target",
                optional = true,
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "HELP",
            target = "$capture.target",
        },
        0.90,
        90
    )

    -- Quest operations use explicit utterances so a bare social "yes" or a
    -- generic question cannot mutate quest state. The action-aware policy
    -- routes these frames through the same generated flow/dispatcher seam.
end

return Internal
