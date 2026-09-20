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
        "pnc.question.activity_recent",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "been" },
            { kind = "literal", value = "doing" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.96,
        88
    )

    registerPattern(
        "pnc.question.activity_recent_up_to",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "been" },
            { kind = "literal", value = "up" },
            { kind = "literal", value = "to" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.95,
        87
    )

    registerPattern(
        "pnc.question.activity_now",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "doing" },
            { kind = "literal", value = "right" },
            { kind = "literal", value = "now" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.96,
        88
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

    registerPattern(
        "pnc.question.wellbeing_feeling",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "feeling" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        88
    )

    registerPattern(
        "pnc.question.wellbeing_how_have_you_been",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "been" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.95,
        87
    )

    registerPattern(
        "pnc.question.wellbeing_feeling_okay",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "feeling" },
            { kind = "literal", value = "okay" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        88
    )

    registerPattern(
        "pnc.question.wellbeing_everything_okay",
        {
            { kind = "literal", value = "is" },
            { kind = "literal", value = "everything" },
            { kind = "literal", value = "okay" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.94,
        86
    )

    registerPattern(
        "pnc.question.gift_preference_like",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "like" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "today", "tonight", "really" },
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "GIFT_PREFERENCE",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
            },
        },
        0.97,
        95,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.question.gift_preference_dislike",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "dislike" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "today", "tonight", "really" },
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "GIFT_PREFERENCE",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
            },
        },
        0.97,
        95,
        { allowFuzzyCapture = true }
    )

end

return Internal
