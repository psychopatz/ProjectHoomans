-- Questions whose answers are supplied by downstream context providers.
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
end

function Internal.RegisterWorldFactQuestions()
    registerPattern(
        "pnc.question.time",
        { "@TIME" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "TIME",
        },
        0.96,
        85
    )

    registerPattern(
        "pnc.question.day",
        { "@DAY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "DATE",
        },
        0.96,
        90
    )

    registerPattern(
        "pnc.question.weather",
        { "@WEATHER" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WEATHER",
        },
        0.96,
        85
    )

    registerPattern(
        "pnc.question.identity",
        { "@IDENTITY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY",
        },
        0.96,
        85
    )

    registerPattern(
        "pnc.question.activity",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "doing" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.96,
        86
    )

    registerPattern(
        "pnc.question.activity_up_to",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "up" },
            { kind = "literal", value = "to" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.94,
        85
    )

    registerPattern(
        "pnc.question.activity_busy",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "busy" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.94,
        85
    )

    registerPattern(
        "pnc.question.wellbeing_okay",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "okay" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        87
    )

    registerPattern(
        "pnc.question.wellbeing_alright",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "alright" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        87
    )

    registerPattern(
        "pnc.question.wellbeing_how",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.92,
        84
    )
end

return Internal
