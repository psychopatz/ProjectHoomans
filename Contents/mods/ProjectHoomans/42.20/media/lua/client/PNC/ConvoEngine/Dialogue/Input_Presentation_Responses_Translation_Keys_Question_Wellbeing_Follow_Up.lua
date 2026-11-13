-- Static semantic response template-key catalog for question_wellbeing_follow_up.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.wellbeing.follow_up.panic"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpPanic",
        ["semantic.question.wellbeing.follow_up.stress"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpStress",
        ["semantic.question.wellbeing.follow_up.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpThirst",
        ["semantic.question.wellbeing.follow_up.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpHunger",
        ["semantic.question.wellbeing.follow_up.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpFatigue",
        ["semantic.question.wellbeing.follow_up.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpInjured",
        ["semantic.question.wellbeing.follow_up.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpUnknown",
        ["semantic.question.wellbeing.follow_up.default"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpDefault",
}

return keys

