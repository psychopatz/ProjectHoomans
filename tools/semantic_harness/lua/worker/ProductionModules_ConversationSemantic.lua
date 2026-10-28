-- Ordered conversation, semantic, and authority composition.

local function loadConversationSemantic(load, registerEntryPointModule)
    load(
        "ProjectHoomans", "shared",
        "PNC/Translation/PNC_TranslationBootstrap.lua",
        "translation"
    )
    load(
        "ProjectHoomans", "client", "PNC/UI/PNC_NPCTypePalette.lua",
        "conversation_target_projection"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/PNC_ConversationTalkStart.lua",
        "conversation_target_projection"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/PNC_ConversationTalkParity.lua",
        "conversation_target_projection"
    )
    -- The Semantic Lab must exercise the same authored category/block registry
    -- as the game composer. This is read-only for semantic suggestion builds;
    -- category clicks still enter through the existing authority path.
    load(
        "ProjectHoomans", "shared",
        "PNC/Conversation/Composition/PNC_ConversationSharedComposition.lua",
        "conversation_registry"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/API/PNC_API.lua",
        "integration_api"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticTopicCatalog.lua",
        "semantic_topic_catalog"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueRuleProvider.lua",
        "semantic_rule_contract"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticConversationMemoryProvider.lua",
        "semantic_memory_contract"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Semantics/PNC_SemanticConversationSpeechProvider.lua",
        "semantic_speech_contract"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticConversationCategoryOwnership.lua",
        "semantic_conversation_ownership"
    )
    -- Keep category clicks on the production authority/composer seam. The
    -- worker does not load the full native conversation window, but it does
    -- load the same registry, authority, composer and inbound block handler
    -- used by the game path.
    load(
        "ProjectHoomans", "server",
        "PNC/Conversation/PNC_ConversationAuthority.lua",
        "conversation_authority"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer.lua",
        "conversation_composer"
    )
    load("PsychopatzCore", "common_client", "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua", "conversation_text")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticMarketSenseAdapter.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Gifts/PNC_GiftMarketSenseAdapter.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationGifts.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticInventoryQuery.lua", "inventory")
    load("ProjectHoomans", "server", "PNC/Semantics/Inventory/PNC_SemanticItemSelector.lua", "inventory")
    load("ProjectHoomans", "server", "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticToolResultRealization.lua", "tool_result_realization")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua", "semantic")
    for _, spoke in ipairs({
        "PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment.lua",
        "PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Medical.lua",
        "PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Knowledge.lua",
        "PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/SemanticCatalog/" .. spoke,
            "semantic_catalog_question_spoke"
        )
    end

    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticEngineFacts.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticEngineEvents.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticAddressResolver.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticInteractionLifecycle.lua", "semantic_lifecycle")
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticInteractionLifecycle_Envelope.lua",
        "semantic_lifecycle_spoke"
    )
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticInteractionLifecycle_State.lua",
        "semantic_lifecycle_spoke"
    )
    for _, spoke in ipairs({
        "PNC_SemanticInteractionLifecycle_State_Storage.lua",
        "PNC_SemanticInteractionLifecycle_State_Transitions.lua",
        "PNC_SemanticInteractionLifecycle_State_Projections.lua",
        "PNC_SemanticInteractionLifecycle_State_Persistence.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/" .. spoke,
            "semantic_lifecycle_state_spoke"
        )
    end
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticDialoguePolicy.lua", "semantic")
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticValueBounds.lua",
        "semantic_shared_mechanism"
    )
    for _, spoke in ipairs({
        "PNC_SemanticDialogueFlowKernel_Storage.lua",
        "PNC_SemanticDialogueFlowKernel_Matching.lua",
        "PNC_SemanticDialogueFlowKernel_Preview.lua",
        "PNC_SemanticDialogueFlowKernel_Commit.lua",
        "PNC_SemanticDialogueFlowKernel_Results.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared", "PNC/Semantics/" .. spoke,
            "semantic_flow_kernel_spoke"
        )
    end
    for _, spoke in ipairs({
        "PNC_SemanticDialogueLocalResponse_Questions_Observations.lua",
        "PNC_SemanticDialogueLocalResponse_Questions_Facts.lua",
        "PNC_SemanticDialogueLocalResponse_Questions_Context.lua",
        "PNC_SemanticDialogueLocalResponse_Questions_Conversation.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared", "PNC/Semantics/" .. spoke,
            "semantic_response_questions_spoke"
        )
    end
    for _, spoke in ipairs({
        "PNC_SemanticDialogueResponseCatalog_Questions_IdentityActivity.lua",
        "PNC_SemanticDialogueResponseCatalog_Questions_WellbeingMedical.lua",
        "PNC_SemanticDialogueResponseCatalog_Questions_Needs.lua",
        "PNC_SemanticDialogueResponseCatalog_Questions_FollowUps.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/SemanticDialogueResponseCatalog/" .. spoke,
            "semantic_response_catalog_questions_spoke"
        )
    end
    for _, spoke in ipairs({
        "PNC_SemanticDialogueResponseCatalog_Social_Core.lua",
        "PNC_SemanticDialogueResponseCatalog_Social_Conflict.lua",
        "PNC_SemanticDialogueResponseCatalog_Social_Reactions.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/SemanticDialogueResponseCatalog/" .. spoke,
            "semantic_response_catalog_social_spoke"
        )
    end
    -- The game composition loads this semantic event resolver through the
    -- shared foundation. The headless worker needs the same production
    -- resolver explicitly so event lifecycle acceptance exercises the real
    -- SocialReactions -> ResponseCatalog boundary.
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticSocialReaction.lua",
        "semantic_event_resolver"
    )
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticCommandAdapter.lua", "semantic_adapter")
    for _, spoke in ipairs({
        "PNC_SemanticCommandAdapter_Registry.lua",
        "PNC_SemanticCommandAdapter_CompanionActions.lua",
        "PNC_SemanticCommandAdapter_QuestOperations.lua",
        "PNC_SemanticCommandAdapter_ContextualResponses.lua",
        "PNC_SemanticCommandAdapter_Dispatch.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "client",
            "PNC/Semantics/" .. spoke,
            "semantic_command_adapter_spoke"
        )
    end
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticTaskAdapter.lua", "semantic_adapter")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCapabilityCatalog.lua", "semantic")
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates.lua",
        "semantic_suggestion_policy"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions.lua",
        "semantic_suggestions"
    )
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities.lua",
        "semantic_suggestions_spoke"
    )
    for _, spoke in ipairs({
        "PNC_SemanticDialogueSuggestions_Capabilities_Core.lua",
        "PNC_SemanticDialogueSuggestions_Capabilities_Companion.lua",
        "PNC_SemanticDialogueSuggestions_Capabilities_Camp.lua",
        "PNC_SemanticDialogueSuggestions_Capabilities_Rows.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/" .. spoke,
            "semantic_suggestions_capability_spoke"
        )
    end
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions_Branches.lua",
        "semantic_suggestions_spoke"
    )
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions_Frames.lua",
        "semantic_suggestions_spoke"
    )
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection.lua",
        "semantic_suggestions_spoke"
    )
    for _, spoke in ipairs({
        "PNC_SemanticDialogueSuggestions_Projection_Offers.lua",
        "PNC_SemanticDialogueSuggestions_Projection_Root.lua",
        "PNC_SemanticDialogueSuggestions_Projection_Landing.lua",
        "PNC_SemanticDialogueSuggestions_Projection_Groups.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "shared",
            "PNC/Semantics/" .. spoke,
            "semantic_suggestions_projection_spoke"
        )
    end
    registerEntryPointModule(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueSuggestions_Build.lua",
        "semantic_suggestions_spoke"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticAutomaticFlowManifest.lua",
        "semantic_generation_manifest"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows.lua",
        "semantic_generated_flows"
    )
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Context.lua", "semantic")
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua", "semantic")
    for _, spoke in ipairs({
        "PNC_SemanticDialogueInput_Presentation_Responses_Translation.lua",
        "PNC_SemanticDialogueInput_Presentation_Responses_Payloads.lua",
        "PNC_SemanticDialogueInput_Presentation_Responses_Actions.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "client",
            "PNC/Semantics/" .. spoke,
            "semantic_presentation_response_spoke"
        )
    end
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticIdentityExchange.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticIdentityNetwork.lua", "semantic")
    load(
        "ProjectHoomans", "server",
        "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Context.lua",
        "authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Validation.lua",
        "authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PNC_NPCKnowledgeAPI.lua",
        "knowledge_authority"
    )
    PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
    PNC.PlayerKnowledgeCommands.Internal =
        PNC.PlayerKnowledgeCommands.Internal or {}
    PNC.PlayerKnowledgeCommands.Processed =
        PNC.PlayerKnowledgeCommands.Processed or {}
    PNC.PlayerKnowledgeCommands.Uncommitted =
        PNC.PlayerKnowledgeCommands.Uncommitted or {}
    PNC.PlayerKnowledgeCommands.Diagnostics =
        PNC.PlayerKnowledgeCommands.Diagnostics or {}
    PNC.PlayerKnowledgeCommands.Internal.BootstrapChunkSize = 32
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Core.lua",
        "authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Presentation.lua",
        "authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Bootstrap.lua",
        "authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Disclosure.lua",
        "authority"
    )
    load("ProjectHoomans", "server", "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Identity.lua", "authority")
    load("ProjectHoomans", "server", "PNC/Networking/Handlers/PNC_ServerSemanticInteractionLifecycleCommandHandler.lua", "semantic_lifecycle_authority")
end

return loadConversationSemantic
