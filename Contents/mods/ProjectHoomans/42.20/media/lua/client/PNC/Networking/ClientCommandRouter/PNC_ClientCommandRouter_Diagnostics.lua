local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_DEBUG_ROSTER, function(args)
    ClientState.debugAuthorized = args.authorized == true
    ClientState.debugRoster = args.diagnostics or {}
    ClientState.debugAudit = args.audit or {}
    ClientState.lastDebugRosterReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_RELATIONSHIP_DEBUG, function(args)
    ClientState.relationshipDebugAuthorized = args.authorized == true
    ClientState.relationshipDebug = args.snapshot
    ClientState.relationshipDebugReason = args.reason
    ClientState.lastRelationshipDebugReceiveAt = Core.Now()
    local relationship = PNC.Conversation and PNC.Conversation.Relationship
    if relationship and relationship.ReceiveDebugSnapshot then
        relationship.ReceiveDebugSnapshot(args.snapshot)
    end
end)

Internal.RegisterServerCommand(Const.CMD_FACTION_DEBUG, function(args)
    ClientState.factionDebugAuthorized = args.authorized == true
    ClientState.factionDebug = args.snapshot
    ClientState.factionDebugReason = args.reason
    ClientState.lastFactionDebugReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_FACTION_MEMBERS, function(args)
    ClientState.factionMembers = args.snapshot
    ClientState.factionMembersReason = args.reason
    ClientState.lastFactionMembersReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_COMMUNITY_DEBUG, function(args)
    ClientState.communityDebugAuthorized = args.authorized == true
    ClientState.communityDebug = args.snapshot
    ClientState.communityDebugReason = args.reason
    ClientState.lastCommunityDebugReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_NEEDS_DEBUG, function(args)
    ClientState.needsDebugAuthorized = args.authorized == true
    ClientState.needsDebug = args.snapshot
    ClientState.needsDebugReason = args.reason
    ClientState.lastNeedsDebugReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_DIRECTOR_DEBUG, function(args)
    ClientState.directorDebugAuthorized = args.authorized == true
    ClientState.directorDebug = args.snapshot
    ClientState.directorDebugReason = args.reason
    ClientState.lastDirectorDebugReceiveAt = Core.Now()
end)

return PNC.Client
