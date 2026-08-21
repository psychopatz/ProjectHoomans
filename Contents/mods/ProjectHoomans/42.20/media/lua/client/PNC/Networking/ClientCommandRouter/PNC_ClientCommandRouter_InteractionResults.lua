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
