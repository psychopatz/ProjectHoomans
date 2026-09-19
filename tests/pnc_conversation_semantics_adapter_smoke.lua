local T = require "tests/support/test"
T.addPackagePaths()

local previousPNC = PNC
local previousRequire = require
local receivedTimeResolver
local receivedGroupOptions
local expectedGroup = { created = true }
local expectedInputPart = { created = true }
local bounds = { x = 1, y = 2, width = 3, height = 4 }
local options = { mode = "nearby" }
local input = {
    Internal = {},
    CreatePart = function(actualBounds, actualOptions)
        T.equal(actualBounds, bounds, "input factory preserves its bounds")
        T.equal(actualOptions, options, "input factory preserves its options")
        return expectedInputPart
    end,
}
local diagnostics = { enabled = true }
local entityResolver = { NormalizeName = function(value) return value end }
local time = { Resolve = function() return "sunset" end }
local worldContext = {
    SetTimeBandResolver = function(resolver)
        receivedTimeResolver = resolver
    end,
}

PNC = {
    Semantics = {
        DialogueInput = input,
        SemanticDiagnostics = diagnostics,
        EntityResolver = entityResolver,
        WorldContext = worldContext,
    },
}

require = function(moduleName)
    if moduleName == "PNC/Semantics/PNC_SemanticDialogueInput"
        or moduleName == "PNC/Semantics/PNC_SemanticWorldContext"
    then
        return true
    end
    return previousRequire(moduleName)
end

local Adapter = T.load(
    "ProjectHoomans", "client", "PNC/PNC_ConversationSemantics.lua")
require = previousRequire

local conversation = {}
local group = {
    Create = function(primaryHost, hosts, entries, player, groupOptions)
        receivedGroupOptions = groupOptions
        return expectedGroup
    end,
}
local registered = Adapter.RegisterConversation(conversation, group, time)
T.equal(registered, true, "adapter registers the conversation coordinator")
T.equal(conversation.CreateSemanticDialogueInput,
    Adapter.CreateSemanticDialogueInput,
    "adapter exposes the semantic input factory on Conversation")
T.equal(receivedTimeResolver, time.Resolve,
    "adapter registers the conversation time resolver")
T.equal(Adapter.CreateSemanticDialogueInput(bounds, options), expectedInputPart,
    "semantic input factory delegates to the input module")

local created = Adapter.CreateGroup({}, {}, {}, {}, options)
T.equal(created, expectedGroup, "adapter creates the group coordinator")
T.equal(receivedGroupOptions.mode, "nearby",
    "adapter preserves the caller's group mode")
T.equal(receivedGroupOptions.dialogueInput, input,
    "adapter injects the dialogue input contract")
T.equal(receivedGroupOptions.semanticDiagnostics, diagnostics,
    "adapter injects semantic diagnostics")
T.equal(receivedGroupOptions.entityResolver, entityResolver,
    "adapter injects the entity resolver")
T.equal(options.dialogueInput, nil,
    "adapter does not mutate the caller's group options")

PNC = previousPNC
T.finish("pnc_conversation_semantics_adapter_smoke")
