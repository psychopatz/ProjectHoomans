-- Dedicated-server request/acknowledgement boundary for client-run vanilla
-- grapple actions. The service remains authoritative and rechecks every
-- transition.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_CORPSE_HAUL_ACK, function(player, args)
    if PNC.CorpseHaulService and PNC.CorpseHaulService.HandleClientAck then
        PNC.CorpseHaulService.HandleClientAck(player, args or {})
    end
end)
