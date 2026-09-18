-- Local debug actions that mutate or present relationship state.
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

return {
    social_trigger_event = function(player, args)
        local snapshot
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.TriggerSocialEvent
        then
            return false
        end
        snapshot, reason =
            PNC.RelationshipDebug.TriggerSocialEvent(player, args)
        ClientState.relationshipDebugAuthorized = true
        ClientState.relationshipDebug = snapshot
        ClientState.relationshipDebugReason = reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(snapshot)
        end
        return snapshot ~= nil, reason
    end,

    conversation_relationship_standing = function(player, args)
        local summary
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.SetConversationStanding
        then
            return false
        end
        summary, reason = PNC.RelationshipDebug.SetConversationStanding(
            player,
            args
        )
        if summary then
            ClientState.conversationRelationships =
                ClientState.conversationRelationships or {}
            ClientState.conversationRelationships[
                tostring(summary.npcID)
            ] = summary
            ClientState.lastConversationRelationshipReceiveAt = Core.Now()
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceivePresentation then
                relationship.ReceivePresentation(summary)
            end
        end
        return summary ~= nil, reason
    end,

    relationship_debug_baseline = function(player, args)
        local snapshot
        local reason
        if not PNC.RelationshipDebug
            or not PNC.RelationshipDebug.ApplyDebugBaseline
        then
            return false
        end
        snapshot, reason = PNC.RelationshipDebug.ApplyDebugBaseline(
            player,
            args
        )
        ClientState.relationshipDebugAuthorized = true
        ClientState.relationshipDebug = snapshot
        ClientState.relationshipDebugReason = reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(snapshot)
        end
        return snapshot ~= nil, reason
    end,
}
