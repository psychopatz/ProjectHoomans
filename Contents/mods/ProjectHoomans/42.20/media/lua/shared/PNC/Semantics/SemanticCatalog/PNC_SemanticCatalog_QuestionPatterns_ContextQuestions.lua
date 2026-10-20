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

    local medicalBiteQuestion = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_BITE_STATUS",
        target = "SELF",
        slots = { attribute = "bite_status" },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            personalQuestion = true,
            target = "SELF",
        },
        extensions = { topic = "medical" },
    }

    registerPattern(
        "pnc.question.medical_bite.have_you_been",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "been" },
            { kind = "concept", id = "BITTEN" },
        },
        medicalBiteQuestion,
        0.99,
        122
    )

    registerPattern(
        "pnc.question.medical_bite.are_you",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "BITTEN" },
        },
        medicalBiteQuestion,
        0.98,
        121
    )

    registerPattern(
        "pnc.question.medical_bite.did_a_zombie",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "a" },
            { kind = "literal", value = "zombie" },
            { kind = "concept", id = "BITE" },
            { kind = "literal", value = "you" },
        },
        medicalBiteQuestion,
        0.99,
        123
    )

    registerPattern(
        "pnc.question.medical_bite.did_the_zombie",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "the" },
            { kind = "literal", value = "zombie" },
            { kind = "concept", id = "BITE" },
            { kind = "literal", value = "you" },
        },
        medicalBiteQuestion,
        0.99,
        123
    )

    registerPattern(
        "pnc.question.medical_bite.did_zombie",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "zombie" },
            { kind = "concept", id = "BITE" },
            { kind = "literal", value = "you" },
        },
        medicalBiteQuestion,
        0.98,
        122
    )

    registerPattern(
        "pnc.question.medical_bite.any",
        {
            { kind = "literal", value = "any" },
            { kind = "concept", id = "BITE" },
        },
        medicalBiteQuestion,
        0.98,
        120
    )

    registerPattern(
        "pnc.question.medical_bite.have_any",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "had" },
            { kind = "literal", value = "any" },
            { kind = "concept", id = "BITE" },
        },
        medicalBiteQuestion,
        0.98,
        121
    )

    local residenceQuestion = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_RESIDENCE",
        target = "SELF",
        slots = { attribute = "residence" },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            personalQuestion = true,
            target = "SELF",
        },
        extensions = { topic = "residence" },
    }

    registerPattern(
        "pnc.question.residence.where_do_you_live",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "live" },
            { kind = "literal", value = "exactly", optional = true },
        },
        residenceQuestion,
        0.99,
        124
    )

    registerPattern(
        "pnc.question.residence.where_is_home",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "your" },
            { kind = "literal", value = "home" },
        },
        residenceQuestion,
        0.98,
        123
    )

    registerPattern(
        "pnc.question.residence.where_do_you_stay",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "stay" },
        },
        residenceQuestion,
        0.98,
        123
    )

    registerPattern(
        "pnc.question.residence.where_is_house",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "your" },
            { kind = "literal", value = "house" },
        },
        residenceQuestion,
        0.98,
        123
    )

    registerPattern(
        "pnc.question.residence.what_settlement",
        {
            { kind = "literal", value = "what" },
            { kind = "concept", id = "RESIDENCE" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "from" },
        },
        residenceQuestion,
        0.97,
        122
    )

    local healthQuestion = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_HEALTH_STATE",
        target = "SELF",
        slots = { attribute = "health_state" },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            personalQuestion = true,
            target = "SELF",
        },
        extensions = { topic = "medical" },
    }

    registerPattern(
        "pnc.question.health.are_you_injured",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "injured" },
        },
        healthQuestion,
        0.99,
        124
    )

    registerPattern(
        "pnc.question.health.are_you_hurt",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "hurt" },
        },
        healthQuestion,
        0.99,
        124
    )

    registerPattern(
        "pnc.question.health.how_is_your_health",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "your" },
            { kind = "concept", id = "HEALTH_STATUS" },
        },
        healthQuestion,
        0.98,
        123
    )

    registerPattern(
        "pnc.question.health.how_are_your_wounds",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "your" },
            { kind = "literal", value = "wounds" },
        },
        healthQuestion,
        0.99,
        124
    )

    registerPattern(
        "pnc.question.health.what_about_your_health",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "your" },
            { kind = "concept", id = "HEALTH_STATUS" },
        },
        healthQuestion,
        0.98,
        125
    )

    local knowledgeQuestion = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_KNOWLEDGE",
        slots = {
            attribute = "knowledge",
            topic = "$capture.topic",
        },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            informationalQuestion = true,
        },
        extensions = { topic = "knowledge" },
    }

    registerPattern(
        "pnc.question.knowledge.do_you_know_about",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "KNOW" },
            { kind = "literal", value = "about" },
            {
                kind = "any_phrase",
                capture = "topic",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        knowledgeQuestion,
        0.96,
        119,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.question.knowledge.have_you_heard_of",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "heard" },
            { kind = "literal", value = "of" },
            {
                kind = "any_phrase",
                capture = "topic",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        knowledgeQuestion,
        0.96,
        119,
        { allowFuzzyCapture = true }
    )

    -- Bounded discourse-reference questions.  The literal pronoun is
    -- captured by PsychopatzCore so the existing dialogue reference resolver
    -- can bind it to the current topic/focus; these exact utterance shapes
    -- never become an open-ended fuzzy parser or a gameplay request.
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
