if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerLegacyDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

function H.HandleDiagnosticAction(player, args)
    local network = PNC.Network
    if args.action == "faction_debug_action" then
        network.SendFactionDebug(
            player,
            PNC.FactionDebug.PerformAction(player, args),
            true,
            nil
        )
        return true
    end
    if args.action == "community_debug_action" then
        network.SendCommunityDebug(
            player,
            PNC.CommunityDebug.PerformAction(player, args),
            true,
            nil
        )
        return true
    end
    if args.action == "needs_debug_action" then
        network.SendNeedsDebug(
            player,
            PNC.NeedsDebug.PerformAction(args),
            true,
            nil
        )
        return true
    end
    if args.action == "director_debug_action" then
        network.SendDirectorDebug(
            player,
            PNC.AbstractDirectorDebug.PerformAction(args),
            true,
            nil
        )
        return true
    end
    return false
end

return Handler

