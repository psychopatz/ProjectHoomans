-- Context-reference and wellbeing follow-up question patterns.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog follow-up module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog follow-up module requires RegisterPattern")
end

function Internal.RegisterContextReferenceFollowUps()
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

end

return Internal
