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

function Internal.RegisterWorldFactQuestions_Knowledge()
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
end

return Internal
