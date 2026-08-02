--[[
    PNC Client Command Router
    Dispatches inbound server commands to domain-owned handlers.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Handlers = Internal.ServerCommandHandlers or {}

Internal.ServerCommandHandlers = Handlers

function Internal.RegisterServerCommand(command, handler)
    if command == nil or type(handler) ~= "function" then
        return false
    end
    Handlers[command] = handler
    return true
end

Internal.RegisterServerCommand(Const.CMD_DEBUG_ROSTER, function(args)
    ClientState.debugAuthorized = args.authorized == true
    ClientState.debugRoster = args.diagnostics or {}
    ClientState.debugAudit = args.audit or {}
    ClientState.lastDebugRosterReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(
    Const.CMD_RELATIONSHIP_DEBUG,
    function(args)
        ClientState.relationshipDebugAuthorized =
            args.authorized == true
        ClientState.relationshipDebug = args.snapshot
        ClientState.relationshipDebugReason = args.reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(args.snapshot)
        end
    end
)

Internal.RegisterServerCommand(
    Const.CMD_CONVERSATION_RELATIONSHIP,
    function(args)
        local summary = args.summary
        if type(summary) ~= "table" or not summary.npcID then return end
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[tostring(summary.npcID)] =
            summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(summary)
        end
    end
)

Internal.RegisterServerCommand(
    Const.CMD_FACTION_DEBUG,
    function(args)
        ClientState.factionDebugAuthorized =
            args.authorized == true
        ClientState.factionDebug = args.snapshot
        ClientState.factionDebugReason = args.reason
        ClientState.lastFactionDebugReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(
    Const.CMD_FACTION_MEMBERS,
    function(args)
        ClientState.factionMembers = args.snapshot
        ClientState.factionMembersReason = args.reason
        ClientState.lastFactionMembersReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(
    Const.CMD_COMMUNITY_DEBUG,
    function(args)
        ClientState.communityDebugAuthorized =
            args.authorized == true
        ClientState.communityDebug = args.snapshot
        ClientState.communityDebugReason = args.reason
        ClientState.lastCommunityDebugReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(Const.CMD_MAP_COMMAND_RESULT, function(args)
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_FACTION_TOLL, function(args)
    if not PNC.FactionTollUI then
        require "PNC/UI/Factions/PNC_FactionTollWindow"
    end
    if PNC.FactionTollUI
        and PNC.FactionTollUI.HandleServerMessage
    then
        PNC.FactionTollUI.HandleServerMessage(args or {})
    end
end)

Internal.RegisterServerCommand(
    Const.CMD_CONVERSATION_CEASEFIRE_RESULT,
    function(args)
        if PNC.Conversation
            and PNC.Conversation.HandleCeasefireResult
        then
            PNC.Conversation.HandleCeasefireResult(args or {})
        end
    end
)

function Client.HandleServerCommand(command, args)
    local handler
    ClientState.lastSyncReceiveAt = Core.Now()
    handler = Handlers[command]
    if handler then
        handler(args or {})
    end
end
