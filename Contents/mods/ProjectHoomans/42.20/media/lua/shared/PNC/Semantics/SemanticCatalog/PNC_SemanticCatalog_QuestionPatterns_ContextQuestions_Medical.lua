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

function Internal.RegisterWorldFactQuestions_Medical()
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

end

return Internal
