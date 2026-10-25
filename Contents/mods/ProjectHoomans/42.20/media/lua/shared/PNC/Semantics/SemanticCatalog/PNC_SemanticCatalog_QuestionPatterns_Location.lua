-- Location and seen-target question pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog question module requires RegisterPattern")
end

function Internal.RegisterLocationQuestions()
    registerPattern(
        "pnc.question.where",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.90,
        80
    )

    registerPattern(
        "pnc.question.where_can_find",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "can" },
            { kind = "literal", value = "i" },
            { kind = "literal", value = "find" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.91,
        82
    )

    registerPattern(
        "pnc.question.where_do_you_know",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "know" },
            { kind = "literal", value = "where" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "is" },
            },
            { kind = "literal", value = "is" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.90,
        81
    )

    registerPattern(
        "pnc.question.seen",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "see" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.88,
        80
    )

    registerPattern(
        "pnc.question.seen_have_you_seen",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "seen" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.90,
        82
    )

    registerPattern(
        "pnc.question.seen_happen_to",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "happen" },
            { kind = "literal", value = "to" },
            { kind = "literal", value = "see" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.89,
        81
    )
end

return Internal
