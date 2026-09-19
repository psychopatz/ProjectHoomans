-- Relationship, faction, and community debug request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.RequestRelationshipDebug(
    observerNPCID,
    targetKind,
    targetNPCID
)
    local player = Internal.GetPlayer()
    local args = {
        observerNPCID = observerNPCID,
        targetKind = targetKind,
        targetNPCID = targetNPCID,
    }
    local snapshot
    local reason
    if not Client.CanUseDebug() then
        ClientState.relationshipDebugAuthorized = false
        ClientState.relationshipDebug = nil
        ClientState.relationshipDebugReason = "not_authorized"
        return false
    end
    ClientState.lastRelationshipDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_RELATIONSHIP_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.RelationshipDebug
        or not PNC.RelationshipDebug.BuildSnapshotForRequest
    then
        return false
    end
    snapshot, reason =
        PNC.RelationshipDebug.BuildSnapshotForRequest(player, args)
    ClientState.relationshipDebugAuthorized = true
    ClientState.relationshipDebug = snapshot
    ClientState.relationshipDebugReason = reason
    ClientState.lastRelationshipDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestConversationRelationship(npcID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    local player = Internal.GetPlayer()
    ClientState.lastConversationRelationshipRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_CONVERSATION_RELATIONSHIP_REQUEST,
                { npcID = npcID })
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.RelationshipPresentation
        or not PNC.RelationshipPresentation.BuildForConversation
    then
        return false, "presentation_unavailable"
    end
    local presentation = PNC.RelationshipPresentation
    local summary, reason = presentation.BuildForConversation(player, npcID)
    if summary then
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[npcID] = summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(summary)
        end
    end
    return summary ~= nil, reason
end

function Client.RequestFactionDebug(
    factionID,
    npcID,
    targetFactionID
)
    local player = Internal.GetPlayer()
    local args = {
        factionID = factionID,
        npcID = npcID,
        targetFactionID = targetFactionID,
    }
    local snapshot
    if not Client.CanUseDebug() then
        ClientState.factionDebugAuthorized = false
        ClientState.factionDebug = nil
        ClientState.factionDebugReason = "not_authorized"
        return false
    end
    ClientState.lastFactionDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_FACTION_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.FactionDebug
        or not PNC.FactionDebug.BuildSnapshot
    then
        return false
    end
    snapshot = PNC.FactionDebug.BuildSnapshot(
        factionID,
        npcID,
        nil,
        player,
        targetFactionID
    )
    ClientState.factionDebugAuthorized = true
    ClientState.factionDebug = snapshot
    ClientState.factionDebugReason = nil
    ClientState.lastFactionDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestFactionMembers()
    local player = Internal.GetPlayer()
    if not player then return false end
    ClientState.lastFactionMembersRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS_REQUEST,
            {}
        )
        return true
    end
    if not PNC.FactionMembership
        or not PNC.FactionMembership.BuildSnapshot
    then
        return false
    end
    local snapshot
    local reason
    snapshot, reason = PNC.FactionMembership.BuildSnapshot(player)
    ClientState.factionMembers = snapshot
    ClientState.factionMembersReason = reason
    ClientState.lastFactionMembersReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestCommunityDebug(
    communityID,
    factionID,
    npcID
)
    local player = Internal.GetPlayer()
    local args = {
        communityID = communityID,
        factionID = factionID,
        npcID = npcID,
    }
    local snapshot
    if not Client.CanUseDebug() then
        ClientState.communityDebugAuthorized = false
        ClientState.communityDebug = nil
        ClientState.communityDebugReason = "not_authorized"
        return false
    end
    ClientState.lastCommunityDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_COMMUNITY_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.CommunityDebug
        or not PNC.CommunityDebug.BuildSnapshot
    then
        return false
    end
    snapshot = PNC.CommunityDebug.BuildSnapshot(
        communityID,
        factionID,
        npcID,
        nil,
        player
    )
    ClientState.communityDebugAuthorized = true
    ClientState.communityDebug = snapshot
    ClientState.communityDebugReason = nil
    ClientState.lastCommunityDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

return Client
