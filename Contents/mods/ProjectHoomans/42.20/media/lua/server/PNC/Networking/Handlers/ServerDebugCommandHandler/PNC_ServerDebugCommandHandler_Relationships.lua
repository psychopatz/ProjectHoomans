if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

function H.HandleRelationshipAction(player, args)
    local network = PNC.Network
    if args.action == "social_trigger_event" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.TriggerSocialEvent(player, args)
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "conversation_relationship_standing" then
        local summary
        local reason
        summary, reason = PNC.RelationshipDebug.SetConversationStanding(
            player,
            args
        )
        network.SendConversationRelationship(player, summary, reason)
        return true
    end
    if args.action == "relationship_debug_baseline" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.ApplyDebugBaseline(
            player,
            args
        )
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "relationship_pacification" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.SetPlayerPacification(
            player,
            args
        )
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    return false
end

return Handler
