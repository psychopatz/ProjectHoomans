-- Thin authoritative boundary for domain-owned client command handlers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

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
    handler(player, args or {}, args)
    return true
end

function Router.CanUseDebug(player)
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
end

return Router
