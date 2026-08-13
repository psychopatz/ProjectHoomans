-- Thin authoritative boundary for domain-owned client command handlers.

PNC = PNC or {}
PNC.ServerCommandRouter = PNC.ServerCommandRouter or {}

local Router = PNC.ServerCommandRouter
local Handlers = Router.Handlers or {}

Router.Handlers = Handlers

function Router.Register(command, handler)
    if command == nil or type(handler) ~= "function" then
        return false
    end
    Handlers[command] = handler
    return true
end

function Router.Handle(command, player, args)
    local handler = Handlers[command]
    if not handler then return false end
    handler(player, args or {})
    return true
end

return Router
