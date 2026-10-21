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
    -- Keep the production NPC Knowledge service on the worker boundary.
    -- The adapter later fills these same tables with scenario-owned identity
    -- and registry methods; the service never receives a second store.
    PNC = PNC or {}
    PNC.Registry = PNC.Registry or {}
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerContext = PNC.PlayerContext or {}
    PNC.Relationships = PNC.Relationships or {}
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
    load("ProjectHoomans", "shared", "PNC/Translation/PNC_TranslationBootstrap.lua", "translation")
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
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticEngineFacts.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticEngineEvents.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticDialoguePolicy.lua", "semantic")
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticCommandAdapter.lua", "semantic_adapter")
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
    if type(Semantic) ~= "table" then error("semantic core failed to load") end
end

return ProductionModules
