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
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticDialoguePolicy.lua", "semantic")
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
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Core.lua",
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
    require = originalRequire

    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Registry.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentity.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_Internal.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientRequests/PNC_ClientRequests_Identity.lua", "network")

    PsychopatzConversationLLMInput = originalInputClass
    context.Translations.installInstrumentation(context)
    if type(Semantic) ~= "table" then error("semantic core failed to load") end
end

return ProductionModules
