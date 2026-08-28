local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_RELATIONSHIP,
    function(args)
        local summary = args.summary
        if type(summary) ~= "table" or not summary.npcID then return end
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[tostring(summary.npcID)] = summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        local relationship = PNC.Conversation and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(summary)
        end
    end)

Internal.RegisterServerCommand(Const.CMD_LLM_SOCIAL_REACTION_RESULT,
    function(args)
        args = type(args) == "table" and args or {}
        ClientState.llmToolResults = ClientState.llmToolResults or {}
        ClientState.llmToolResultOrder = ClientState.llmToolResultOrder or {}
        local key = tostring(args.requestID or "") .. ":"
            .. tostring(args.callID or "")
        if key == ":" then return end
        ClientState.llmToolResults[key] = args
        ClientState.llmToolResultOrder[#ClientState.llmToolResultOrder + 1] = key
        while #ClientState.llmToolResultOrder > 32 do
            local oldest = table.remove(ClientState.llmToolResultOrder, 1)
            ClientState.llmToolResults[oldest] = nil
        end
        if args.relationship then
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceivePresentation then
                relationship.ReceivePresentation(args.relationship)
            end
        end
        local trace = PsychopatzCore and PsychopatzCore.DebugTrace
        if trace and trace.IsEnabled and trace.IsEnabled() and trace.Record then
            trace.Record({
                source = "ProjectHoomans",
                event = "llm.social_reaction_result",
                requestID = args.requestID,
                data = args,
            })
        end
    end)

Internal.RegisterServerCommand(Const.CMD_MAP_COMMAND_RESULT, function(args)
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_FACTION_TOLL, function(args)
    if not PNC.FactionTollUI then
        require "PNC/UI/Factions/PNC_FactionTollWindow"
    end
    if PNC.FactionTollUI and PNC.FactionTollUI.HandleServerMessage then
        PNC.FactionTollUI.HandleServerMessage(args or {})
    end
end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_CEASEFIRE_RESULT,
    function(args)
        if PNC.Conversation and PNC.Conversation.HandleCeasefireResult then
            PNC.Conversation.HandleCeasefireResult(args or {})
        end
    end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_BLOCK, function(args)
    if PNC.Conversation and PNC.Conversation.Composer then
        PNC.Conversation.Composer.ReceiveBlock(args or {})
    end
end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_OUTCOME, function(args)
    if PNC.Conversation and PNC.Conversation.Composer then
        PNC.Conversation.Composer.ReceiveOutcome(args or {})
    end
end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_RECRUIT_RESULT,
    function(args)
        if PNC.Conversation and PNC.Conversation.Composer then
            PNC.Conversation.Composer.ReceiveRecruitOutcome(args or {})
        end
        if args and args.success == true
            and PNC.Client and PNC.Client.RequestColonyManagement
        then
            PNC.Client.RequestColonyManagement()
        end
    end)

return PNC.Client
