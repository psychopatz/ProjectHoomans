-- Recruitment and conversation-topic pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Catalog = PNC.Semantics.Catalog
local Internal = Catalog.Internal
local registerPattern = Internal.RegisterPattern

local function registerWhatsUpConceptPattern()
    registerPattern(
        "pnc.question.whats_up.concept",
        { { kind = "concept", id = "WHATS_UP" } },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
        subject = "CONVERSATION_TOPIC",
        extensions = {
            topic = "whats_up",
            hubID = "whats_up",
            route = "semantic_hub",
            },
        },
        0.94,
        154,
        {
            metadata = {
                owner = "ProjectHoomans",
                fuzzySafe = true,
                canonicalConcept = "WHATS_UP",
                mapping = {
                    canonicalConcept = "WHATS_UP",
                dialogueState = "WHATS_UP_HUB",
                    sourceRefs = { "DailyDialog", "EmpatheticDialogues" },
                },
            },
        }
    )
end

local function registerRecruitmentRequestPatterns()
    local patterns = {
        {
            id = "pnc.request.conversation_recruit.would_you_like_join_us",
            match = {
                { kind = "literal", value = "would" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "like" },
                { kind = "literal", value = "to" },
                { kind = "literal", value = "join" },
                { kind = "literal", value = "us" },
            },
        },
        {
            id = "pnc.request.conversation_recruit.do_you_want_join_us",
            match = {
                { kind = "literal", value = "do" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "want" },
                { kind = "literal", value = "to" },
                { kind = "literal", value = "join" },
                { kind = "literal", value = "us" },
            },
        },
        {
            id = "pnc.request.conversation_recruit.would_you_like_join_me",
            match = {
                { kind = "literal", value = "would" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "like" },
                { kind = "literal", value = "to" },
                { kind = "literal", value = "join" },
                { kind = "literal", value = "me" },
            },
        },
        {
            id = "pnc.request.conversation_recruit.do_you_want_join_me",
            match = {
                { kind = "literal", value = "do" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "want" },
                { kind = "literal", value = "to" },
                { kind = "literal", value = "join" },
                { kind = "literal", value = "me" },
            },
        },
        {
            id = "pnc.request.conversation_recruit.join_us",
            match = {
                { kind = "literal", value = "join" },
                { kind = "literal", value = "us" },
            },
        },
        {
            id = "pnc.request.conversation_recruit.come_with_us",
            match = {
                { kind = "literal", value = "come" },
                { kind = "literal", value = "with" },
                { kind = "literal", value = "us" },
            },
        },
    }
    local emit = {
        intent = "REQUEST",
        speechAct = "REQUEST",
        subject = "CONVERSATION_ACTION",
        action = "RECRUIT",
        extensions = {
            route = "conversation_action",
            actionID = "recruit",
            topic = "recruitment",
        },
    }
    for index = 1, #patterns do
        local pattern = patterns[index]
        registerPattern(pattern.id, pattern.match, emit, 0.99, 220)
    end
end

Internal.RegisterWhatsUpConceptPattern = registerWhatsUpConceptPattern
Internal.RegisterRecruitmentRequestPatterns = registerRecruitmentRequestPatterns

return Internal

