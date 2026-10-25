-- Wellbeing follow-up question registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog follow-up spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog follow-up spoke requires RegisterPattern")
end

function Internal.RegisterWellbeingFollowUps()
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
