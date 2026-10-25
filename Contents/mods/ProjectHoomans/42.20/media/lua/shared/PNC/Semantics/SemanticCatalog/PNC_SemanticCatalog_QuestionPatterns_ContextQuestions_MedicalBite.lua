-- medical bite-status question registrations.
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

function Internal.RegisterMedicalBiteQuestions()
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
end

return Internal

