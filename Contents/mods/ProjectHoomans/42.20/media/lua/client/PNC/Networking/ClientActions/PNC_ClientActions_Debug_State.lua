-- Local debug actions for knowledge, factions, communities, needs, and
-- abstract-director state.
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

return {
    knowledge_debug_action = function(player, args)
        if not PNC.NPCKnowledge
            or not PNC.NPCKnowledge.ExecuteDebugForPlayer
        then
            return false
        end
        local snapshot, reason =
            PNC.NPCKnowledge.ExecuteDebugForPlayer(player, args)
        ClientState.knowledgeDebugAuthorized = true
        ClientState.knowledgeDebug, ClientState.knowledgeDebugReason =
            snapshot, reason
        if PNC.KnowledgeDebugUI
            and PNC.KnowledgeDebugUI.ReceiveSnapshot
        then
            PNC.KnowledgeDebugUI.ReceiveSnapshot(snapshot)
        end
        if PNC.NPCDossierUI
            and PNC.NPCDossierUI.ReceiveDebugSnapshot
        then
            PNC.NPCDossierUI.ReceiveDebugSnapshot(snapshot)
        end
        return snapshot ~= nil, reason
    end,

    faction_debug_action = function(player, args)
        local snapshot
        if not PNC.FactionDebug
            or not PNC.FactionDebug.PerformAction
        then
            return false
        end
        snapshot = PNC.FactionDebug.PerformAction(player, args)
        ClientState.factionDebugAuthorized = true
        ClientState.factionDebug = snapshot
        ClientState.factionDebugReason = nil
        ClientState.lastFactionDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end,

    community_debug_action = function(player, args)
        local snapshot
        if not PNC.CommunityDebug
            or not PNC.CommunityDebug.PerformAction
        then
            return false
        end
        snapshot = PNC.CommunityDebug.PerformAction(player, args)
        ClientState.communityDebugAuthorized = true
        ClientState.communityDebug = snapshot
        ClientState.communityDebugReason = nil
        ClientState.lastCommunityDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end,

    needs_debug_action = function(_, args)
        if not PNC.NeedsDebug or not PNC.NeedsDebug.PerformAction then
            return false
        end
        local snapshot = PNC.NeedsDebug.PerformAction(args)
        ClientState.needsDebugAuthorized = true
        ClientState.needsDebug = snapshot
        ClientState.needsDebugReason = nil
        ClientState.lastNeedsDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end,

    director_debug_action = function(_, args)
        if not PNC.AbstractDirectorDebug then
            return false
        end
        local snapshot = PNC.AbstractDirectorDebug.PerformAction(args)
        ClientState.directorDebugAuthorized = true
        ClientState.directorDebug = snapshot
        ClientState.directorDebugReason = nil
        ClientState.lastDirectorDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end,
}
