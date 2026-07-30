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
    end
)

Internal.RegisterServerCommand(Const.CMD_MAP_COMMAND_RESULT, function(args)
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(args)
    end
end)

function Client.HandleServerCommand(command, args)
    local handler
    ClientState.lastSyncReceiveAt = Core.Now()
    handler = Handlers[command]
    if handler then
        handler(args or {})
    end
end
