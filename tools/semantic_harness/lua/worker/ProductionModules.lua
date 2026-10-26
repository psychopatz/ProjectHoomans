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


    local loadCorePersistence = require "worker/ProductionModules_CorePersistence"
    local loadWorldAuthority = require "worker/ProductionModules_WorldAuthority"
    local loadConversationSemantic = require "worker/ProductionModules_ConversationSemantic"

    local Semantic = loadCorePersistence(load)
    loadWorldAuthority(load)
    loadConversationSemantic(load, registerEntryPointModule)

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
    -- The Conversation semantic façade is loaded after the input entry point
    -- so its lazy dependency seam observes the same worker-owned input table
    -- without executing the entry point a second time through require.
    load(
        "ProjectHoomans", "client",
        "PNC/Conversation/Semantic/PNC_ConversationSemanticRuntime.lua",
        "conversation_semantic_runtime"
    )
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
