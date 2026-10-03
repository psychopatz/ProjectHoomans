local Internal = PNC.Client.Internal
local Const = PNC.Const
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_RelationshipResult"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_LLMSocialReactionResult"

Internal.RegisterServerCommand(Const.CMD_PLAYER_EMOTE_INTERACTION_RESULT,
    function(args)
        if PNC.CompanionCommandPresentation
            and PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult
        then
            PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult(
                args or {}
            )
        end
    end)

if Const.CMD_COMPANION_COMMAND_RESULT then
    require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_CompanionCommandResult"
    Internal.RegisterServerCommand(Const.CMD_COMPANION_COMMAND_RESULT,
        function(args)
            Internal.HandleCompanionCommandResult(args)
        end)
end

if Const.CMD_SOCIAL_GREETING then
    Internal.RegisterServerCommand(Const.CMD_SOCIAL_GREETING, function(args)
        if PNC.CompanionCommandPresentation
            and PNC.CompanionCommandPresentation.HandleSocialGreeting
        then
            PNC.CompanionCommandPresentation.HandleSocialGreeting(args or {})
        end
    end)
end

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

if Const.CMD_CONVERSATION_SETTLEMENT_ADMISSION_RESULT then
    Internal.RegisterServerCommand(
        Const.CMD_CONVERSATION_SETTLEMENT_ADMISSION_RESULT,
        function(args)
            if PNC.Conversation and PNC.Conversation.Composer
                and PNC.Conversation.Composer.ReceiveSettlementAdmissionOutcome
            then
                PNC.Conversation.Composer.ReceiveSettlementAdmissionOutcome(
                    args or {}
                )
            end
            if args and args.success == true
                and PNC.Client and PNC.Client.RequestColonyManagement
            then
                PNC.Client.RequestColonyManagement()
            end
        end
    )
end

if Const.CMD_CONVERSATION_AMBIENT_VISIT_RESULT then
    Internal.RegisterServerCommand(
        Const.CMD_CONVERSATION_AMBIENT_VISIT_RESULT,
        function(args)
            if PNC.Conversation and PNC.Conversation.Composer
                and PNC.Conversation.Composer.ReceiveAmbientVisitOutcome
            then
                PNC.Conversation.Composer.ReceiveAmbientVisitOutcome(
                    args or {}
                )
            end
        end
    )
end

if Const.CMD_CONVERSATION_DEPARTURE_RESULT then
    Internal.RegisterServerCommand(Const.CMD_CONVERSATION_DEPARTURE_RESULT,
        function(args)
            if PNC.Conversation and PNC.Conversation.Composer
                and PNC.Conversation.Composer.ReceiveDepartureOutcome
            then
                PNC.Conversation.Composer.ReceiveDepartureOutcome(args or {})
            end
        end)
end

return PNC.Client
