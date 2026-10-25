-- Static semantic response template-key catalog for question_needs.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.needs.offer.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferHunger",
        ["semantic.question.needs.offer.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferThirst",
        ["semantic.question.needs.offer.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferFatigue",
        ["semantic.question.needs.offer.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferUnknown",
        ["semantic.question.needs.quantity.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityHunger",
        ["semantic.question.needs.quantity.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityThirst",
        ["semantic.question.needs.quantity.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityUnknown",
        ["semantic.question.needs.proposal.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalHunger",
        ["semantic.question.needs.proposal.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalThirst",
        ["semantic.question.needs.proposal.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalUnknown",
}

return keys

