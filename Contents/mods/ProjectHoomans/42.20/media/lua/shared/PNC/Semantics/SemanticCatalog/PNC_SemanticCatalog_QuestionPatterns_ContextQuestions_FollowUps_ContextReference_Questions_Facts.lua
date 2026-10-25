-- Reference-based context fact follow-up questions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic context-reference fact spoke requires Catalog.Internal")
end

if type(Internal.RegisterContextReferenceQuestion) ~= "function" then
    error("semantic context-reference fact spoke requires question core")
end

function Internal.RegisterContextReferenceFactQuestions()
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.what_about_it",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "it", capture = "reference" },
        },
        0.98,
        128,
        "ABOUT"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.what_about_that",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "that", capture = "reference" },
        },
        0.98,
        128,
        "ABOUT"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.what_about_this",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "about" },
            { kind = "literal", value = "this", capture = "reference" },
        },
        0.98,
        128,
        "ABOUT"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.safe_there",
        {
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "safe" },
            { kind = "literal", value = "there" },
        },
        0.98,
        127,
        "SAFETY"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.like_there",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "like" },
            { kind = "literal", value = "there" },
        },
        0.98,
        127,
        "DESCRIPTION"
    )
    Internal.RegisterContextReferenceQuestion(
        "pnc.question.context_reference.still_hurt",
        {
            { kind = "literal", value = "does" },
            { kind = "literal", value = "it", capture = "reference" },
            { kind = "literal", value = "still" },
            { kind = "literal", value = "hurt" },
        },
        0.98,
        127,
        "MEDICAL_PAIN"
    )
end

return Internal
