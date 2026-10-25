-- Shared context-reference follow-up question construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic context-reference question core requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic context-reference question core requires RegisterPattern")
end

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

function Internal.RegisterContextReferenceQuestion(
    patternID,
    match,
    confidence,
    priority,
    questionKind,
    hasReference
)
    registerPattern(
        patternID,
        match,
        contextReferenceQuestion(questionKind, hasReference),
        confidence,
        priority
    )
end

return Internal
