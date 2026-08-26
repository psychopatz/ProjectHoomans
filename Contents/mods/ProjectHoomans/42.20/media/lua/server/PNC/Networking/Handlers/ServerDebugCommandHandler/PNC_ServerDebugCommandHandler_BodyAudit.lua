if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

function H.HandleBodyAudit(player, args)
    if args.action == "audit_bodies" then
        local bodyLifecycle = PNC.BodyLifecycle
        if bodyLifecycle and bodyLifecycle.AuditLoadedBodies then
            bodyLifecycle.AuditLoadedBodies(PNC.Core.Now(), true)
        end
        PNC.Network.SendDebugRoster(
            player,
            bodyLifecycle and bodyLifecycle.BuildDebugRoster
                and bodyLifecycle.BuildDebugRoster() or {},
            true,
            bodyLifecycle and bodyLifecycle.LastAudit or {}
        )
        return true
    end
    return false
end

return Handler
