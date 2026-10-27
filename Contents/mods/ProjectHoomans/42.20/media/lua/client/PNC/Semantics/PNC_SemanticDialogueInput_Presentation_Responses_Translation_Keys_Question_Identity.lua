-- Static semantic response template-key catalog for question_identity.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.identity.stranger_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt1",
        ["semantic.question.identity.stranger_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt2",
        ["semantic.question.identity.wary_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt1",
        ["semantic.question.identity.wary_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt2",
}

return keys

