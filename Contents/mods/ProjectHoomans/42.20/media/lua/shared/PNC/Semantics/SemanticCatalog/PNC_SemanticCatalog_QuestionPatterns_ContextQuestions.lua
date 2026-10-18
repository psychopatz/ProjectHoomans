-- Context question patterns whose answers are supplied by downstream providers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog context-question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog context-question module requires RegisterPattern")
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
        "pnc.question.wellbeing_follow_up_whats_wrong",
        {
            { kind = "literal", value = "what's" },
            { kind = "literal", value = "wrong" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
            extensions = { dialogueFollowUp = "WELLBEING" },
        },
        0.97,
        90
    )

    registerPattern(
        "pnc.question.wellbeing_follow_up_whats_plain",
        {
            -- Conversation text entry commonly arrives without the
            -- apostrophe in "what's". Keep this exact alias local to the
            -- authored wellbeing follow-up instead of changing the global
            -- normalizer's contraction behavior.
            { kind = "literal", value = "whats" },
            { kind = "literal", value = "wrong" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
            extensions = { dialogueFollowUp = "WELLBEING" },
        },
        0.97,
        90
    )

    registerPattern(
        "pnc.question.wellbeing_follow_up_what_is_wrong",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "wrong" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
            extensions = { dialogueFollowUp = "WELLBEING" },
        },
        0.97,
        90
    )

    registerPattern(
        "pnc.question.needs_offer",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "WANT" },
            { kind = "concept", id = "ANY_ITEM" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "NEEDS",
            extensions = {
                topic = "needs",
                dialogueFollowUp = "NEEDS_QUANTITY",
            },
        },
        0.98,
        96
    )

    registerPattern(
        "pnc.question.needs_offer_plain",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "need" },
            { kind = "literal", value = "anything" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "NEEDS",
            extensions = {
                topic = "needs",
                dialogueFollowUp = "NEEDS_QUANTITY",
            },
        },
        0.99,
        97
    )

    registerPattern(
        "pnc.question.quantity_follow_up",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "many" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "QUANTITY",
            extensions = {
                topic = "needs",
                dialogueFollowUp = "NEEDS_QUANTITY",
            },
        },
        0.99,
        98
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
