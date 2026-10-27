-- Static semantic response template-key catalog for question_health_state.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.health_state.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateInjured",
        ["semantic.question.health_state.healthy"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateHealthy",
        ["semantic.question.health_state.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateUnknown",
}

return keys

