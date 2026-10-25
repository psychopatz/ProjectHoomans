-- Needs, quantity, and proposal follow-up question patterns.
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

function Internal.RegisterNeedsFollowUps()
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

end

return Internal
