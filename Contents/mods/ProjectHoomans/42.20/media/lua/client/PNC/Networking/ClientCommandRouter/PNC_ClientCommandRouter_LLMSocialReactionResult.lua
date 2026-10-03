-- Client application of optional LLM social reaction results.

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

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

return Internal
