-- Static semantic response template-key catalog for action.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.action.follow.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionFollowUnavailable",
        ["semantic.action.stay.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStayUnavailable",
        ["semantic.action.stop.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStopUnavailable",
}

return keys

