-- health-state question registrations.
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

function Internal.RegisterHealthQuestions()
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

