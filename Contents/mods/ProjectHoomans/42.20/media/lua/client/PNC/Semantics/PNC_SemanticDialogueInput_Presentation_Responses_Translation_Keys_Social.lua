-- Static semantic response template-key catalog for social.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.social.interaction.unavailable"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionUnavailable",
        ["semantic.social.interaction.rejected"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionRejected",
        ["semantic.social.self_reflection.friendly"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionFriendly",
        ["semantic.social.self_reflection.trusted"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionTrusted",
        ["semantic.social.self_reflection.withdrawn"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionWithdrawn",
        ["semantic.social.self_reflection.stressed"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionStressed",
        ["semantic.social.self_reflection.default"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionDefault",
        ["semantic.social.compliment.default"] =
            "UI_PNC_Conversation_Semantic_ComplimentDefault",
        ["semantic.social.compliment.alternate"] =
            "UI_PNC_Conversation_Semantic_ComplimentAlternate",
        ["semantic.social.compliment.friendly"] =
            "UI_PNC_Conversation_Semantic_ComplimentFriendly",
        ["semantic.social.compliment.trusted"] =
            "UI_PNC_Conversation_Semantic_ComplimentTrusted",
        ["semantic.social.compliment.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ComplimentWithdrawn",
        ["semantic.social.apology.friendly"] =
            "UI_PNC_Conversation_Semantic_ApologyFriendly",
        ["semantic.social.apology.trusted"] =
            "UI_PNC_Conversation_Semantic_ApologyTrusted",
        ["semantic.social.apology.stressed"] =
            "UI_PNC_Conversation_Semantic_ApologyStressed",
        ["semantic.social.apology.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ApologyWithdrawn",
        ["semantic.social.apology.default"] =
            "UI_PNC_Conversation_Semantic_ApologyDefault",
        ["semantic.social.threat_stressed"] =
            "UI_PNC_Conversation_Semantic_ThreatStressed",
        ["semantic.social.threat_withdrawn"] =
            "UI_PNC_Conversation_Semantic_ThreatWithdrawn",
        ["semantic.social.threat_trusted"] =
            "UI_PNC_Conversation_Semantic_ThreatTrusted",
        ["semantic.social.offer_stressed"] =
            "UI_PNC_Conversation_Semantic_OfferStressed",
        ["semantic.social.offer_friendly"] =
            "UI_PNC_Conversation_Semantic_OfferFriendly",
        ["semantic.social.offer_trusted"] =
            "UI_PNC_Conversation_Semantic_OfferTrusted",
        ["semantic.social.offer_withdrawn"] =
            "UI_PNC_Conversation_Semantic_OfferWithdrawn",
        ["semantic.social.dispute_stressed"] =
            "UI_PNC_Conversation_Semantic_DisputeStressed",
        ["semantic.social.dispute_friendly"] =
            "UI_PNC_Conversation_Semantic_DisputeFriendly",
        ["semantic.social.dispute_trusted"] =
            "UI_PNC_Conversation_Semantic_DisputeTrusted",
        ["semantic.social.dispute_withdrawn"] =
            "UI_PNC_Conversation_Semantic_DisputeWithdrawn",
        ["semantic.social.refuse_request"] =
            "UI_PNC_Conversation_Semantic_RefuseRequest",
}

return keys

