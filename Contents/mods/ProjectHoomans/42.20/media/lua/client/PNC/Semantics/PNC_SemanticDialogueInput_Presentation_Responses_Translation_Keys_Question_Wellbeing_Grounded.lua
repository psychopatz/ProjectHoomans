-- Static semantic response template-key catalog for question_wellbeing_grounded.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.wellbeing.grounded.friendly.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyFact",
        ["semantic.question.wellbeing.grounded.friendly.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyTone",
        ["semantic.question.wellbeing.grounded.withdrawn.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnFact",
        ["semantic.question.wellbeing.grounded.withdrawn.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnTone",
}

return keys

