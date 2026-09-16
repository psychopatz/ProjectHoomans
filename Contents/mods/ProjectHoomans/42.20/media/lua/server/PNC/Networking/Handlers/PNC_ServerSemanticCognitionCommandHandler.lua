-- Server-authoritative read-only cognition projection requests.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_SEMANTIC_COGNITION_REQUEST, function(player, args)
    local service = PNC.Semantics and PNC.Semantics.CognitionService
    if service and service.HandleRequest then
        service.HandleRequest(player, args)
    elseif PNC.Network and PNC.Network.SendSemanticCognition then
        PNC.Network.SendSemanticCognition(
            player,
            nil,
            "cognition_service_unavailable",
            args and args.requestID,
            args and args.npcID
        )
    end
end)
