local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_RELATIONSHIP,
    function(args)
        args = type(args) == "table" and args or {}
        local summary = args.summary
        local npcID
        local delta
        local before
        local after
        local source
        local hasChangeMetadata
        if type(summary) ~= "table" or not summary.npcID then return end
        npcID = tostring(summary.npcID)
        delta = args.relationshipDelta or args.delta
        before = args.relationshipBefore or args.before
        after = args.relationshipAfter or args.after or summary
        hasChangeMetadata = delta ~= nil
            or before ~= nil
            or args.source ~= nil
            or args.eventID ~= nil
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[npcID] = summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        source = args.source or "relationship_network"
        local relationship = PNC.Conversation and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(
                summary,
                delta,
                {
                    source = source,
                    eventID = args.eventID,
                    revision = args.revision or summary.revision,
                }
            )
        end
        if hasChangeMetadata then
            ClientState.lastConversationDelta = {
                npcID = npcID,
                source = source,
                delta = delta,
                before = before,
                after = after,
                effects = {
                    eventID = args.eventID,
                },
                at = Core.Now(),
            }
            ClientState.lastConversationDeltas =
                ClientState.lastConversationDeltas or {}
            ClientState.lastConversationDeltas[npcID] =
                ClientState.lastConversationDelta
        end
    end)

    Internal.RegisterServerCommand(Const.CMD_LLM_SOCIAL_REACTION_RESULT,
    function(args)
        args = type(args) == "table" and args or {}
        local delta = args.relationshipDelta or {
            approval = args.approvalDelta,
            respect = args.respectDelta,
            familiarity = args.familiarityDelta,
        }
        ClientState.llmToolResults = ClientState.llmToolResults or {}
        ClientState.llmToolResultOrder = ClientState.llmToolResultOrder or {}
        local key = tostring(args.requestID or "") .. ":"
            .. tostring(args.callID or "")
        if key == ":" then return end
        local duplicate = ClientState.llmToolResults[key] ~= nil
        ClientState.llmToolResults[key] = args
        if not duplicate then
            ClientState.llmToolResultOrder[#ClientState.llmToolResultOrder + 1] = key
        end
        while #ClientState.llmToolResultOrder > 32 do
            local oldest = table.remove(ClientState.llmToolResultOrder, 1)
            ClientState.llmToolResults[oldest] = nil
        end
        if args.npcID and type(args.capabilities) == "table" then
            ClientState.llmReactionCapabilities =
                ClientState.llmReactionCapabilities or {}
            ClientState.llmReactionCapabilities[tostring(args.npcID)] =
                args.capabilities
        end
        if args.relationship then
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceivePresentation then
                relationship.ReceivePresentation(
                    args.relationship,
                    args.accepted == true and delta or nil,
                    {
                        source = "llm_tool",
                        eventID = args.eventID,
                        revision = args.relationshipRevision
                            or args.relationship.revision,
                    }
                )
            end
        end
        if args.accepted == true then
            local clientState = ClientState
            clientState.lastConversationDelta = {
                npcID = args.npcID,
                source = "llm_tool",
                tool = args.tool,
                reaction = args.reaction,
                intensity = args.intensity,
                delta = delta,
                before = args.relationshipBefore,
                after = args.relationshipAfter or args.relationship,
                effects = {
                    memoryID = args.memoryID,
                    memoryType = args.memoryType,
                    interactionType = args.interactionType,
                    eventID = args.eventID,
                },
                at = Core.Now(),
            }
            if not duplicate then
                local diary = PNC.Conversation
                    and PNC.Conversation.Diary
                if not diary then
                    diary = require "PNC/Conversation/PNC_ConversationDiary"
                end
                if diary and diary.Append then
                    diary.Append(args.npcID, {
                        kind = "llm_social_reaction",
                        choiceID = args.reaction,
                        delta = delta,
                        before = args.relationshipBefore,
                        after = args.relationshipAfter or args.relationship,
                        memoryID = args.memoryID,
                        memoryType = args.memoryType,
                        interactionType = args.interactionType,
                        eventID = args.eventID,
                        at = Core.Now(),
                    })
                end
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

return PNC.Client
