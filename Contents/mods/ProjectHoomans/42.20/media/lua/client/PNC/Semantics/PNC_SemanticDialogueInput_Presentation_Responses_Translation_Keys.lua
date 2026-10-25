-- Static semantic response template-key catalog.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

    local keys = {
        ["semantic.identity.exchange"] =
            "UI_PNC_Conversation_Semantic_IdentityExchange",
        ["semantic.identity.exchange.unavailable"] =
            "UI_PNC_Conversation_Semantic_IdentityExchangeUnavailable",
        ["semantic.action.follow.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionFollowUnavailable",
        ["semantic.action.stay.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStayUnavailable",
        ["semantic.action.stop.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStopUnavailable",
        ["semantic.social.interaction.unavailable"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionUnavailable",
        ["semantic.social.interaction.rejected"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionRejected",
        ["semantic.question.identity.stranger_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt1",
        ["semantic.question.identity.stranger_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt2",
        ["semantic.question.identity.wary_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt1",
        ["semantic.question.identity.wary_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt2",
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
        ["semantic.identity.evasion.untrustworthy"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionUntrustworthy",
        ["semantic.identity.evasion.friendly"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionFriendly",
        ["semantic.identity.evasion.withdrawn"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionWithdrawn",
        ["semantic.identity.evasion.default"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionDefault",
        ["semantic.flow.greeting.opening.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
        ["semantic.flow.greeting.opening.rain"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningRain",
        ["semantic.flow.greeting.opening.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
        ["semantic.flow.greeting.opening.question.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
        ["semantic.flow.greeting.opening.question.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
        ["semantic.flow.greeting.followup.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
        ["semantic.flow.greeting.followup.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
        ["semantic.flow.weather.raining.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherRaining",
        ["semantic.flow.weather.clear.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherClear",
        ["semantic.flow.weather.unknown.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherUnknown",
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
        ["semantic.question.wellbeing.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown",
        ["semantic.question.wellbeing.panic"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingPanic",
        ["semantic.question.wellbeing.stress"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingStress",
        ["semantic.question.wellbeing.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirst",
        ["semantic.question.wellbeing.thirst_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirstAlt",
        ["semantic.question.wellbeing.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHunger",
        ["semantic.question.wellbeing.hunger_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHungerAlt",
        ["semantic.question.wellbeing.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigue",
        ["semantic.question.wellbeing.fatigue_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigueAlt",
        ["semantic.question.wellbeing.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingInjured",
        ["semantic.question.wellbeing.grounded.friendly.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyFact",
        ["semantic.question.wellbeing.grounded.friendly.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyTone",
        ["semantic.question.wellbeing.grounded.withdrawn.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnFact",
        ["semantic.question.wellbeing.grounded.withdrawn.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnTone",
        ["semantic.question.wellbeing.default"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDefault",
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
        ["semantic.question.medical_bite.positive"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBitePositive",
        ["semantic.question.medical_bite.negative"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteNegative",
        ["semantic.question.medical_bite.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteUnknown",
        ["semantic.question.residence.known"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceKnown",
        ["semantic.question.residence.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceUnknown",
        ["semantic.question.health_state.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateInjured",
        ["semantic.question.health_state.healthy"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateHealthy",
        ["semantic.question.health_state.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateUnknown",
        ["semantic.question.knowledge.known"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeKnown",
        ["semantic.question.knowledge.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeUnknown",
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

Internal.SemanticTranslationKeys = keys

return keys

