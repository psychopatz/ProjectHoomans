if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

function H.HandleKnowledgeOrRecruitAction(player, args)
    local network = PNC.Network
    if args.action == "knowledge_debug_action" then
        local snapshot
        local reason
        if PNC.NPCKnowledge and PNC.NPCKnowledge.ExecuteDebugForPlayer then
            snapshot, reason = PNC.NPCKnowledge.ExecuteDebugForPlayer(
                player,
                args
            )
        else
            reason = "knowledge_service_unavailable"
        end
        network.SendKnowledgeDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "conversation_debug_recruit" then
        local ok
        local reason
        if PNC.DebugCompanionRecruit and PNC.DebugCompanionRecruit.Try then
            ok, reason = PNC.DebugCompanionRecruit.Try(player, args)
        else
            ok, reason = false, "debug_recruit_service_unavailable"
        end
        if ok ~= true then
            PNC.Core.LogWarn("Rejected debug companion recruit npc="
                .. tostring(args.npcID or args.id or "unknown")
                .. " reason=" .. tostring(reason))
        elseif PNC.ColonyManagement
            and PNC.ColonyManagement.BuildSnapshot
        then
            network.SendColonyManagement(
                player,
                PNC.ColonyManagement.BuildSnapshot(player)
            )
        end
        return true
    end
    return false
end

return Handler
