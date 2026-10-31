if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Delivers an authoritative LLM reaction result and relationship snapshot.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local Network = H.Network
local sendResult = H.sendResult

function H.DeliverReactionResult(player, result)
    sendResult(player, result)
    if Network and Network.SendConversationRelationship then
        Network.SendConversationRelationship(
            player,
            result.relationship,
            "llm_social_reaction",
            {
                source = "llm_tool",
                eventID = result.eventID,
                relationshipBefore = result.relationshipBefore,
                relationshipAfter = result.relationshipAfter,
                relationshipDelta = result.relationshipDelta,
            }
        )
    end
end

return Authority
