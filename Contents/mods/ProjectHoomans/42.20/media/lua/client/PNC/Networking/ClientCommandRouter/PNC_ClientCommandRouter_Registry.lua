PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Handlers = Internal.ServerCommandHandlers or {}

Internal.ServerCommandHandlers = Handlers

function Internal.RegisterServerCommand(command, handler)
    if command == nil or type(handler) ~= "function" then return false end
    Handlers[command] = handler
    return true
end

function Client.HandleServerCommand(command, args)
    ClientState.lastSyncReceiveAt = Core.Now()
    if type(args) ~= "table" then
        args = {}
    end
    local handler = Handlers[command]
    if handler then handler(args) end
end

return Client
