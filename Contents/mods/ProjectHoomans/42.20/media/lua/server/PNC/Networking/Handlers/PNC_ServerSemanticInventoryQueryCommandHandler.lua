-- Authoritative ingress for read-only semantic inventory queries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_SEMANTIC_INVENTORY_QUERY_REQUEST, function(
    player, args
)
    local service = PNC.Semantics
        and PNC.Semantics.InventoryQueryService
    if service and type(service.HandleRequest) == "function" then
        service.HandleRequest(args or {}, {
            player = player,
            npcID = args and args.npcID,
            conversationID = args and args.conversationID,
            requestID = args and args.requestID,
            conversationToken = args and (args.conversationToken
                or args.token),
            network = true,
        })
    end
end)
