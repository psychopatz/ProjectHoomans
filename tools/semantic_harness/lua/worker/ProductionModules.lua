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
