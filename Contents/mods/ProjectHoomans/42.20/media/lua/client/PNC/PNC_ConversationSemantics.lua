-- Compose the conversation coordinator with the semantic dialogue services.
--
-- Conversation and Semantics own their modules independently. Client
-- composition roots pass the owning services through this adapter.
require "PNC/Semantics/PNC_SemanticDialogueInput"
require "PNC/Semantics/PNC_SemanticWorldContext"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantics = PNC.Semantics
local Input = Semantics.DialogueInput
local WorldContext = Semantics.WorldContext
local groupCoordinator

local Adapter = PNC.ConversationSemantics or {}
PNC.ConversationSemantics = Adapter

function Adapter.CreateSemanticDialogueInput(bounds, options)
    return Input.CreatePart(bounds, options)
end

function Adapter.RegisterConversation(conversation, group, time)
    if type(conversation) == "table" then
        conversation.CreateSemanticDialogueInput =
            Adapter.CreateSemanticDialogueInput
    end
    if type(group) == "table" and type(group.Create) == "function" then
        groupCoordinator = group
    end
    if WorldContext and type(WorldContext.SetTimeBandResolver) == "function"
        and type(time) == "table" and type(time.Resolve) == "function"
    then
        WorldContext.SetTimeBandResolver(time.Resolve)
    end
    return groupCoordinator ~= nil
end

local function copyOptions(options)
    local copy = {}
    if type(options) == "table" then
        for key, value in pairs(options) do copy[key] = value end
    end
    return copy
end

function Adapter.CreateGroup(primaryHost, hosts, entries, player, options)
    if not groupCoordinator then
        return nil, "group_coordinator_unavailable"
    end
    local groupOptions = copyOptions(options)
    groupOptions.dialogueInput = Input
    groupOptions.semanticDiagnostics = Semantics.SemanticDiagnostics
    groupOptions.entityResolver = Semantics.EntityResolver
    return groupCoordinator.Create(
        primaryHost, hosts, entries, player, groupOptions)
end

return Adapter
