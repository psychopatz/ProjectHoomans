-- Quest-supply status, acceptance, and turn-in request patterns.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog pattern module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

function Internal.RegisterQuestRequests()
    registerPattern(
        "pnc.quest.accept.supplies",
        {
            { kind = "literal", value = "yes" },
            { kind = "literal", value = "i", optional = true },
            { kind = "literal", value = "will", optional = true },
            { kind = "literal", value = "help" },
            { kind = "literal", value = "with", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies" },
        },
        { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        0.97,
        180
    )

    registerPattern(
        "pnc.quest.accept.supplies.sure",
        {
            { kind = "literal", value = "sure" },
            { kind = "literal", value = "i", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "help" },
            { kind = "literal", value = "with", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies" },
        },
        { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        0.97,
        181
    )

    registerPattern(
        "pnc.quest.status.supplies",
        {
            { kind = "literal", value = "is" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "clinic", optional = true },
            { kind = "literal", value = "supplies", optional = true },
            { kind = "literal", value = "quest", optional = true },
            { kind = "literal", value = "done" },
        },
        { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        0.97,
        182
    )

    registerPattern(
        "pnc.quest.status.supplies.finished",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "we" },
            { kind = "literal", value = "finish" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        0.97,
        183
    )

    registerPattern(
        "pnc.quest.turn_in.supplies",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "want" },
            { kind = "literal", value = "to" },
            { kind = "literal", value = "turn" },
            { kind = "literal", value = "in" },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "supplies", optional = true },
        },
        { intent = "REQUEST", speechAct = "REQUEST", action = "QUEST_TURN_IN" },
        0.97,
        184
    )
end

return Internal
