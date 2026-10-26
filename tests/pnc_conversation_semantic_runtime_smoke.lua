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
        T.equal(actualBounds, bounds,
            "input factory preserves its bounds")
        T.equal(actualOptions, options,
            "input factory preserves its options")
        return expectedInputPart
    end,
}
local diagnostics = { enabled = true }
local entityResolver = { NormalizeName = function(value) return value end }
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

local Runtime = T.load(
    "ProjectHoomans", "client",
    "PNC/Conversation/Semantic/PNC_ConversationSemanticRuntime.lua")
require = previousRequire

T.equal(Runtime, PNC.Conversation.Semantic,
    "Conversation owns the semantic runtime façade")
T.falsy(PNC.ConversationSemantics,
    "legacy semantic namespace is not recreated")
T.truthy(Runtime.HasDialogueInput(),
    "Conversation façade exposes semantic input availability")
T.equal(Runtime.CreateInput(bounds, options), expectedInputPart,
    "Conversation façade delegates input creation")

local conversation = {}
local group = {
    Create = function(primaryHost, hosts, entries, player, groupOptions)
        receivedGroupOptions = groupOptions
        return expectedGroup
    end,
}
local time = { Resolve = function() return "sunset" end }
T.truthy(Runtime.Register(conversation, group, time),
    "Conversation façade registers the runtime")
T.equal(conversation.CreateSemanticDialogueInput, Runtime.CreateInput,
    "Conversation receives the canonical input factory")
T.equal(receivedTimeResolver, time.Resolve,
    "Conversation registers the time resolver")
local created = Runtime.CreateGroup({}, {}, {}, {}, options)
T.equal(created, expectedGroup, "Conversation creates the group coordinator")
T.equal(receivedGroupOptions.mode, "nearby",
    "Conversation preserves the caller's group mode")
T.equal(receivedGroupOptions.dialogueInput, input,
    "Conversation injects the dialogue input contract")
T.equal(receivedGroupOptions.semanticDiagnostics, diagnostics,
    "Conversation injects semantic diagnostics")
T.equal(receivedGroupOptions.entityResolver, entityResolver,
    "Conversation injects the entity resolver")
T.equal(options.dialogueInput, nil,
    "Conversation does not mutate the caller's group options")

PNC = previousPNC
T.finish("pnc_conversation_semantic_runtime_smoke")
