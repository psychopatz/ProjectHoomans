if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerLegacyDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

Router.Register(Const.CMD_DEBUG, function(player, normalizedArgs, rawArgs)
    local args = rawArgs
    if not Router.CanUseDebug(player) then
        PNC.Core.LogWarn("Rejected unauthorized PNC debug command action="
            .. tostring(args and args.action or "unknown"))
        return
    end
    if not args then return end
    if args.action == "spawn" then
        H.HandleDebugSpawn(player, args)
        return
    end
    if args.action == "teleport_to_npc" then
        H.TeleportPlayerToRecord(player, args.id)
        return
    end
    if H.HandleRelationshipAction(player, args) then return end
    if H.HandleKnowledgeOrRecruitAction(player, args) then return end
    if H.HandleDiagnosticAction(player, args) then return end
    if H.HandleAPIAction(player, args) then return end
    if H.HandleBodyAudit(player, args) then return end
end)

return Handler

