PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog context-question spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog context-question spoke requires RegisterPattern")
end

function Internal.RegisterWorldFactQuestions_FollowUps()
    local function contextReferenceQuestion(questionKind, hasReference)
        local output = {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "CONTEXT_REFERENCE",
            modifiers = { directed = true },
            socialContext = {
                directed = true,
                informationalQuestion = true,
                contextReference = true,
            },
            extensions = {
                dialogueFollowUp = "CONTEXT_REFERENCE",
                topic = "conversation",
                contextQuestion = questionKind,
            },
        }
        if hasReference ~= false then
            output.target = "$capture.reference"
        end
        return output
    end

    local function referencePattern(id, match, priority, questionKind)
        registerPattern(
            id,
            match,
            contextReferenceQuestion(questionKind),
            0.98,
            priority
        )
    end

    referencePattern(
        "pnc.question.context_reference.what_about_it",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "it", capture = "reference" },
        },
        128,
        "ABOUT"
    )
    referencePattern(
        "pnc.question.context_reference.what_about_that",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "that", capture = "reference" },
        },
        128,
        "ABOUT"
    )
    referencePattern(
        "pnc.question.context_reference.what_about_this",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "this", capture = "reference" },
        },
        128,
        "ABOUT"
    )
    referencePattern(
        "pnc.question.context_reference.safe_there",
        {
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "safe" },
            { kind = "literal", value = "there" },
        },
        127,
        "SAFETY"
    )
    referencePattern(
        "pnc.question.context_reference.like_there",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "like" },
            { kind = "literal", value = "there" },
        },
        127,
        "DESCRIPTION"
    )
    referencePattern(
        "pnc.question.context_reference.still_hurt",
        {
            { kind = "literal", value = "does" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "still" },
            { kind = "literal", value = "hurt" },
        },
        127,
        "MEDICAL_PAIN"
    )

    -- Causal follow-ups use the same bounded discourse-reference mechanism
    -- as the existing ABOUT/SAFETY/DESCRIPTION questions. The resolver must
    -- answer from the preceding authoritative fact, or state that it cannot
    -- establish a cause; it must not invent one.
    registerPattern(
        "pnc.question.context_reference.why_is_it_so",
        {
            { kind = "literal", value = "why" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "so" },
        },
        contextReferenceQuestion("CAUSE"),
        0.98,
        129
    )
    registerPattern(
        "pnc.question.context_reference.why_is_that",
        {
            { kind = "literal", value = "why" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "that", capture = "reference" },
        },
        contextReferenceQuestion("CAUSE"),
        0.98,
        129
    )
    registerPattern(
        "pnc.question.context_reference.how_come",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "come" },
        },
        contextReferenceQuestion("CAUSE", false),
        0.97,
        128
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

    -- Keep a conversational supply promise separate from FETCH.  This is a
    -- proposal about the active needs exchange, not a gameplay command.
    registerPattern(
        "pnc.promise.needs_get_some",
        {
            { kind = "literal", value = "i'll" },
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "some" },
        },
        {
            intent = "PROMISE",
            speechAct = "PROMISE",
            subject = "NEEDS",
            extensions = {
                topic = "needs",
                dialogueFollowUp = "NEEDS_PROPOSAL",
            },
        },
        0.99,
        99
    )

    registerPattern(
        "pnc.promise.needs_get_some_plain",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "will" },
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "some" },
        },
        {
            intent = "PROMISE",
            speechAct = "PROMISE",
            subject = "NEEDS",
            extensions = {
                topic = "needs",
                dialogueFollowUp = "NEEDS_PROPOSAL",
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
