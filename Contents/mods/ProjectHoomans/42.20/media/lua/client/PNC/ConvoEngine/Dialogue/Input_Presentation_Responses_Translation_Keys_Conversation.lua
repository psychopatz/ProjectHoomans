-- Static semantic response template-key catalog for conversation.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.conversation.acknowledged.default"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledged",
        ["semantic.conversation.acknowledged.friendly"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledgedFriendly",
        ["semantic.conversation.acknowledged.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledgedWithdrawn",
        ["semantic.conversation.continuation.gossip_memory"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationGossipMemory",
        ["semantic.conversation.continuation.gossip_unknown"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationGossipUnknown",
        ["semantic.conversation.continuation.residence"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
        ["semantic.conversation.continuation.medical"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedical",
        ["semantic.conversation.continuation.medical_known"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalKnown",
        ["semantic.conversation.continuation.medical_unknown"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalUnknown",
        ["semantic.conversation.continuation.knowledge"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationKnowledge",
        ["semantic.conversation.continuation.default"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationDefault",
        ["semantic.conversation.context_reference.unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceUnknown",

        ["semantic.conversation.context_reference.cause_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceCauseUnknown",

        ["semantic.conversation.context_reference.location_safety_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceLocationSafetyUnknown",

        ["semantic.conversation.context_reference.description_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceDescriptionUnknown",

        ["semantic.conversation.context_reference.medical_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceMedicalUnknown",

}

return keys

