-- Ordered loader for the production semantic path exercised by the harness.

local ProductionModules = {}

function ProductionModules.load(context)
    local Runtime = context.Runtime
    local repository = context.repository
    local testSource = repository .. "/tests/support/test.lua"
    local Test = dofile(testSource)
    Test.addPackagePaths()

    local originalRequire = require
    local originalInputClass = PsychopatzConversationLLMInput
    local headlessModules = {
        ["ISUI/ISButton"] = "native_ui",
        ["ISUI/ISPanel"] = "native_ui",
        ["PsychopatzCore/UI/PsychopatzUI"] = "native_ui",
        ["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] = "native_ui",
        ["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"] = "native_ui",
    }
    local headlessStubs = {
        ["PNC/Semantics/PNC_SemanticTelemetryPrompt"] = {
            Offer = function() return false end,
        },
    }

    Runtime.moduleManifest = {}
    Runtime.loadedModules = {}
    local function load(mod, layer, relative, role)
        local value = Test.load(mod, layer, relative)
        Runtime.moduleManifest[#Runtime.moduleManifest + 1] = {
            path = mod .. ":" .. layer .. ":" .. relative,
            role = role or "production",
            status = "loaded",
        }
        Runtime.loadedModules[#Runtime.loadedModules + 1] = relative
        return value
    end

    -- Semantic entry points require these spokes in order. They are loaded by
    -- their public entry point rather than by separate Test.load
    -- calls, so record the real ownership in the worker manifest without
    -- executing each file a second time.
    local function registerEntryPointModule(mod, layer, relative, role)
        Runtime.moduleManifest[#Runtime.moduleManifest + 1] = {
            path = mod .. ":" .. layer .. ":" .. relative,
            role = role or "entrypoint_dependency",
            status = "loaded_by_entrypoint",
        }
        Runtime.loadedModules[#Runtime.loadedModules + 1] = relative
    end

    PsychopatzConversationLLMInput = {
        new = function(_, x, y, width, height, options)
            return { x = x, y = y, width = width, height = height, options = options }
        end,
    }

    local Semantic = load(
        "PsychopatzCore", "common",
        "PsychopatzCore/Semantics/PsychopatzSemantic.lua", "semantic"
    )
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua", "translation")
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCoreTranslation.lua", "translation")
    load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants.lua", "network")
    load("ProjectHoomans", "shared", "PNC/Core/Networking/PNC_Network.lua", "network")
    -- Persistence captures these owner tables when its submodules are
    -- loaded. Keep the worker composition order aligned with the native
    -- shared composition instead of allowing nil load-order seams.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Core.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Types.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_Archetypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity_Profile.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionConstants.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionArchetypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionEmblems.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionDiplomacyMath.lua", "persistence"
    )
    -- FactionTypes captures EntityRef at module load time; load the real
    -- player/NPC key owner before its normalization functions are defined.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileConstants.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileTypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductConstants.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Persistence/PNC_Persistence.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Quests/PNC_QuestDefinitions.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/PNC_ServerCommandRouter.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Quests/PNC_QuestRepository.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Quests/PNC_QuestService.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/Handlers/PNC_ServerSemanticQuestCommandHandler.lua",
        "quest_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Core.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitRegistry.lua",
        "persona_catalog"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua",
        "persona_catalog"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitEffects.lua",
        "persona_catalog"
    )
    -- SAVE rehydration uses the production inventory persistence facade and
    -- its deterministic baseline generator. Load the same narrow production
    -- dependencies before the worker's adapter installs any inventory seam.
    -- Archetype bootstrap is production-owned, but its native INFO logger
    -- writes stdout. The worker stdout is a JSON-lines transport, so contain
    -- that diagnostic only for this bootstrap window and restore the owner.
    local productionLogInfo = PNC.Core and PNC.Core.LogInfo
    if PNC.Core then PNC.Core.LogInfo = function() end end
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_Archetypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_ArchetypeLoader.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment_Items.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment_Slots.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Inventory/PNC_Inventory.lua",
        "persistence"
    )
    if PNC.Core and type(productionLogInfo) == "function" then
        PNC.Core.LogInfo = productionLogInfo
    end
    -- Keep the production NPC Knowledge service on the worker boundary.
    -- The adapter later fills these same tables with scenario-owned identity
    -- and registry methods; the service never receives a second store.
    PNC = PNC or {}
    PNC.Registry = PNC.Registry or {}
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerContext = PNC.PlayerContext or {}
    -- World Knowledge is loaded through the same production module loader so
    -- worker scenarios exercise the portable Core ledger and Hoomans owner
    -- adapter, rather than a JSON-only substitute.
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldFactLedger.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzActorWorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/WorldKnowledge/PNC_WorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ.lua",
        "world_knowledge"
    )
    PNC.Relationships = PNC.Relationships or {}
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Compatibility/PNC_Compatibility_API.lua",
        "compatibility"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Knowledge/PNC_KnowledgeRegistry.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Knowledge/PNC_KnowledgeBuiltins.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PNC_NPCKnowledgeService.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileConstants.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileTypes.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialTraits.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_RelationshipConstants.lua",
    "social_authority"
)
load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_RelationshipProposalPolicy.lua",
    "social_authority"
)
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipKindRegistry.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipStates.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipTypes.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductConstants.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductTypes.lua",
        "social_authority"
    )
    -- SAVE-backed identity rehydration uses the production player registry.
    -- Load its complete owner before the social services capture their
    -- PlayerCharacters reference; the worker supplies only isolated ModData.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_PlayerCharacterConstants.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_PlayerCharacterTypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Player/PNC_PlayerCharacterService.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductDefinitions.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_ConductService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_SocialProfileService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_RelationshipService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_SocialEventService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler.lua",
        "social_authority"
    )
    -- Recruitment is a server-owned conversation effect. Keep the worker's
    -- dual-role authority composition aligned with the native server root so a
    -- recruit choice receives the same evaluation, persistence, and result path.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipGraph.lua",
        "recruitment_authority"
    )
load(
    "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_RelationshipPresentation.lua",
    "social_authority"
)
-- Reuse the production relationship-debug snapshot owner for the headless
-- inspector. It projects persisted memories, saturation, cooldowns, and the
-- directed relationship state without creating a harness social model.
load(
    "ProjectHoomans", "server",
    "PNC/Social/PNC_RelationshipDebug.lua",
    "diagnostics"
)
load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionConstants.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionBalance.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionArchetypes.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionNameGenerator.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionEmblems.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionDiplomacyMath.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionIncidentDefinitions.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionIntent.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionTypes.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Factions/PNC_FactionCore.lua",
        "recruitment_authority"
    )
    -- The native conversation departure authority delegates its gameplay
    -- mutation to this existing server service. Keep the worker on that same
    -- executor so Leave Group acceptance can prove the warning/confirm path
    -- and the real ownership/faction mutation rather than a mock response.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_ColonistDeparturePolicy.lua",
        "departure_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Colonists/PNC_ColonistDepartureService.lua",
        "departure_authority"
    )
    -- CommunityService is a native server dependency of recruitment.  Load
    -- the same shared value objects that the native shared composition loads
    -- before entering the service, so the worker does not create a weaker
    -- recruitment path just because it is headless.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityConstants.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityProfiles.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityMath.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityTypes.lua",
        "recruitment_authority"
    )
    -- Recruitment assignment is a production faction/community transaction.
    -- Keep the worker composition aligned with the native server root so a
    -- successful high-relationship proposal can complete the same ownership
    -- path instead of stopping at communities_unavailable.
    load(
        "ProjectHoomans", "server",
        "PNC/Communities/PNC_CommunityService.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Companions/PNC_DebugCompanionRecruit.lua",
        "recruitment_authority"
    )
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
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationToolReplyCatalog.lua", "tool_catalog")
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationToolReplies.lua", "tool_replies")
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

    -- Only the named native UI edges are replaced in this headless worker.
    -- Unexpected production require failures still fail startup.
    require = function(name)
        local headlessStub = headlessStubs[name]
        if headlessStub then
            Runtime.headlessRequires[name] = {
                role = "headless_presentation",
                reason = "telemetry prompt UI is omitted in the headless worker",
            }
            return headlessStub
        end

        local ok, value = pcall(originalRequire, name)
        if ok then return value end
        local reason = tostring(value or "require_failed")
        local role = headlessModules[name]
        if role then
            Runtime.headlessRequires[name] = {
                role = role,
                reason = reason,
            }
            return true
        end
        error("unexpected production require failure for " .. tostring(name)
            .. ": " .. reason)
    end
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput.lua", "semantic_entry")
    for _, spoke in ipairs({
        "PNC_SemanticDialogueInput_FrameSupport.lua",
        "PNC_SemanticDialogueInput_NavigationFrames.lua",
        "PNC_SemanticDialogueInput_SubmissionFrames.lua",
        "PNC_SemanticDialogueInput_State.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "client",
            "PNC/Semantics/" .. spoke,
            "semantic_input_spoke"
        )
    end
    registerEntryPointModule(
        "ProjectHoomans", "client",
        "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation.lua",
        "semantic_lifecycle_spoke"
    )
    registerEntryPointModule(
        "ProjectHoomans", "client",
        "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Navigation.lua",
        "semantic_lifecycle_spoke"
    )
    registerEntryPointModule(
        "ProjectHoomans", "client",
        "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission.lua",
        "semantic_lifecycle_spoke"
    )
    for _, spoke in ipairs({
        "PNC_SemanticDialogueInput_Lifecycle_Submission_Receipts.lua",
        "PNC_SemanticDialogueInput_Lifecycle_Submission_Compound.lua",
        "PNC_SemanticDialogueInput_Lifecycle_Submission_Single.lua",
        "PNC_SemanticDialogueInput_Lifecycle_Submission_Gossip.lua",
    }) do
        registerEntryPointModule(
            "ProjectHoomans", "client",
            "PNC/Semantics/" .. spoke,
            "semantic_lifecycle_submission_spoke"
        )
    end
    load(
        "ProjectHoomans", "client",
        "PNC/Semantics/PNC_SemanticCognitionClient.lua",
        "semantic_cognition"
    )
    load(
        "ProjectHoomans", "common_lua",
        "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions.lua",
        "conversation_memory"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Semantics/PNC_SemanticDialogueBackstoryFactSource.lua",
        "conversation_memory"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/Definition/PNC_ConversationDefinition_Builder.lua",
        "conversation_definition"
    )
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle.lua",
        "conversation_lifecycle"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Cognition.lua",
        "network"
    )
    require = originalRequire

    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Registry.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_InteractionResults.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Semantics.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentity.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Knowledge.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_Internal.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_SemanticCognition.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_Knowledge.lua", "network")
    local productionKnowledgeRequest = PNC.Client
        and PNC.Client.RequestNPCKnowledgeTopic or nil
    if type(productionKnowledgeRequest) == "function" then
        -- Keep the worker's transport trace while delegating admission,
        -- request IDs, pending state and server delivery to the production
        -- client request and server command contracts.
        PNC.Client.RequestNPCKnowledgeTopic = function(npcID, topicID, options)
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = (Runtime.scenario and Runtime.scenario.runtime or {}).mode,
                command = "KnowledgeDisclosureRequest",
                payload = {
                    npcID = npcID,
                    topicID = topicID,
                    options = context.Values.copy(options),
                },
            }
            return productionKnowledgeRequest(npcID, topicID, options)
        end
        Runtime.productionKnowledgeRequest = productionKnowledgeRequest
    end
    local semanticClient = load(
        "ProjectHoomans", "client",
        "PNC/Networking/ClientRequests/PNC_ClientRequests_Semantic.lua",
        "network"
    )
    Runtime.productionQuestRequest = semanticClient
        and semanticClient.RequestSemanticQuest or nil
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_Identity.lua", "network")

    PsychopatzConversationLLMInput = originalInputClass
    context.Translations.installInstrumentation(context)
    -- Production Core logging is intentionally kept inside the worker
    -- record; raw print output would corrupt the JSON-lines protocol.
    Runtime.productionLogs = {}
    if PNC.Core then
        PNC.Core.LogInfo = function(message)
            Runtime.productionLogs[#Runtime.productionLogs + 1] = {
                level = "INFO", message = tostring(message or ""),
            }
        end
        PNC.Core.LogWarn = function(message)
            Runtime.productionLogs[#Runtime.productionLogs + 1] = {
                level = "WARN", message = tostring(message or ""),
            }
        end
    end
    if type(Semantic) ~= "table" then error("semantic core failed to load") end
end

function ProductionModules.loadOptional(context)
    local Runtime = context.Runtime
    local runtime = Runtime.scenario and Runtime.scenario.runtime or {}
    local mods = runtime.availableMods or {}
    local repository = context.dynamicTradingRepository
    local sharedRoot = repository
        .. "/Contents/mods/DTCommon/42.20/media/lua/shared"
    local hoomansRoot = repository
        .. "/Contents/mods/DTHoomans/42.20/media/lua/shared"
    local files = {
        sharedRoot .. "/DTCommon/00_DTCommon_Init.lua",
        hoomansRoot .. "/DTHoomans/00_DTHoomans_Init.lua",
    }
    local index
    local handle
    local ok
    local reason
    local previousPrint
    local npc
    local traderService
    local traderID

    if mods.DTHoomans ~= true then
        return false, "disabled"
    end
    if Runtime.dynamicTradingLoaded then
        return true, "already_loaded"
    end
    for index = 1, #files do
        handle = io.open(files[index], "rb")
        if not handle then
            return false, "missing_dependency_file"
        end
        handle:close()
    end

    previousPrint = print
    print = function(...)
        Runtime.productionLogs = Runtime.productionLogs or {}
        Runtime.productionLogs[#Runtime.productionLogs + 1] = {
            level = "INFO",
            message = table.concat({ ... }, " "),
        }
    end
    ok, reason = pcall(function()
        dofile(files[1])
        dofile(files[2])
    end)
    print = previousPrint
    if not ok then
        error("optional Dynamic Trading load failed: " .. tostring(reason))
    end
    -- The worker scenario describes the external actor fixture; materialize
    -- that fixture through Dynamic Trading's own registry so role lookup,
    -- category revalidation, and later trade ownership use the dependency's
    -- storage rather than a Hoomans shadow table.
    npc = Runtime.scenario and Runtime.scenario.npc or {}
    traderService = DTCommon and DTCommon.TraderService or nil
    if npc.role == "trader"
        and traderService
        and type(traderService.Create) == "function"
        and type(traderService.BindPhysical) == "function"
    then
        traderID = "harness-trader-" .. tostring(npc.npcID or "npc")
        traderService.Create({
            traderID = traderID,
            displayName = npc.displayName or npc.forename or "Trader",
            traderRole = "merchant",
        })
        traderService.BindPhysical(traderID, npc.npcID)
    end
    Runtime.dynamicTradingLoaded = true
    return true, "loaded"
end

return ProductionModules
