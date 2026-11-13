-- Static semantic response template-key catalog for question_wellbeing_dataset.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.wellbeing.dataset.hanging_in"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHangingIn",
        ["semantic.question.wellbeing.dataset.all_things_considered"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetAllThingsConsidered",
        ["semantic.question.wellbeing.dataset.getting_by"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetGettingBy",
        ["semantic.question.wellbeing.dataset.hungry"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHungry",
        ["semantic.question.wellbeing.dataset.thirsty"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetThirsty",
        ["semantic.question.wellbeing.dataset.tired"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetTired",
}

return keys

