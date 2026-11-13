-- Static semantic response template-key catalog for question_relationship_status.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.relationship_status.committed"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusCommitted",
        ["semantic.question.relationship_status.uncertain"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertain",
        ["semantic.question.relationship_status.uncertain_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertainAlt",
        ["semantic.question.relationship_status.withdrawn"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusWithdrawn",
        ["semantic.question.relationship_status.after_compliment.committed"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentCommitted",
        ["semantic.question.relationship_status.after_compliment.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterCompliment",
        ["semantic.question.relationship_status.after_compliment.unknown_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentAlt",
        ["semantic.question.relationship_status.after_compliment.withdrawn"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentWithdrawn",
        ["semantic.question.relationship_status.acknowledged.default"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledged",
        ["semantic.question.relationship_status.acknowledged.alternate"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedAlt",
        ["semantic.question.relationship_status.acknowledged.withdrawn"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedWithdrawn",
}

return keys

