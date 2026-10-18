-- Explicit item and assistance requests routed through task adapters.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

function Internal.RegisterRequests()
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
    registerPattern(
        "pnc.quest.accept.supplies",
        {
            { kind = "literal", value = "yes" },
            { kind = "literal", value = "i", optional = true },
            { kind = "literal", value = "will", optional = true },
            { kind = "literal", value = "help", optional = true },
            { kind = "literal", value = "with", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        0.97,
        180
    )

    registerPattern(
        "pnc.quest.accept.supplies.sure",
        {
            { kind = "literal", value = "sure" },
            { kind = "literal", value = "i", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "help", optional = true },
            { kind = "literal", value = "with", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        0.97,
        181
    )

    registerPattern(
        "pnc.quest.status.supplies",
        {
            { kind = "literal", value = "is" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "clinic", optional = true },
            { kind = "literal", value = "supplies", optional = true },
            { kind = "literal", value = "quest", optional = true },
            { kind = "literal", value = "done" },
        },
        { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        0.97,
        182
    )

    registerPattern(
        "pnc.quest.status.supplies.finished",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "we" },
            { kind = "literal", value = "finish" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        0.97,
        183
    )

    registerPattern(
        "pnc.quest.turn_in.supplies",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "want" },
            { kind = "literal", value = "to" },
            { kind = "literal", value = "turn" },
            { kind = "literal", value = "in" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "REQUEST", speechAct = "REQUEST", action = "QUEST_TURN_IN" },
        0.97,
        184
    )
end

return Internal
