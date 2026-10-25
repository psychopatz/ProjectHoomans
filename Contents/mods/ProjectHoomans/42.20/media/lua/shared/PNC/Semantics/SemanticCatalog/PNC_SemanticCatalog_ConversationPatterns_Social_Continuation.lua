-- Conversation-continuation follow-up pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

function Internal.RegisterContinuationSignals()
    local continuation = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "CONVERSATION",
        extensions = { dialogueFollowUp = "CONVERSATION_CONTINUATION" },
    }
    registerPattern(
        "pnc.social.continuation.tell_me_more",
        {
            { kind = "literal", value = "tell" },
            { kind = "literal", value = "me" },
            { kind = "concept", id = "MORE" },
        },
        continuation,
        0.99,
        145
    )
    registerPattern(
        "pnc.social.continuation.more",
        { "@MORE" },
        continuation,
        0.98,
        144
    )
    registerPattern(
        "pnc.social.continuation.say_more",
        {
            { kind = "literal", value = "can" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "say" },
            { kind = "concept", id = "MORE" },
        },
        continuation,
        0.98,
        144
    )
    registerPattern(
        "pnc.social.continuation.say_more_short",
        {
            { kind = "literal", value = "say" },
            { kind = "concept", id = "MORE" },
        },
        continuation,
        0.98,
        144
    )
    registerPattern(
        "pnc.social.continuation.tell_me_more_question",
        {
            { kind = "literal", value = "can" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "tell" },
            { kind = "literal", value = "me" },
            { kind = "concept", id = "MORE" },
        },
        continuation,
        0.98,
        144
    )
end

return Internal
