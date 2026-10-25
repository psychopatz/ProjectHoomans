-- residence question registrations.
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

function Internal.RegisterResidenceQuestions()
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
end

return Internal

