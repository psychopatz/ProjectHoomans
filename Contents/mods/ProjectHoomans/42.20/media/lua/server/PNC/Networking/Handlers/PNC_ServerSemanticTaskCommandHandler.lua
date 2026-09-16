-- Authoritative ingress for semantic task contracts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function sendResult(player, args, result)
    if not player or type(sendServerCommand) ~= "function" then return end
    args = type(args) == "table" and args or {}
    result = type(result) == "table" and result or {}
    local request = type(result.request) == "table"
        and result.request or {}
    sendServerCommand(player, Const.MODULE, Const.CMD_SEMANTIC_TASK_RESULT, {
        requestID = result.requestID or request.requestID or args.requestID,
        npcID = result.npcID or request.npcID or args.npcID,
        action = result.action or request.action or args.action,
        planID = result.planID,
        accepted = result.accepted == true,
        status = result.status or (result.accepted == true
            and "accepted" or "rejected"),
        reason = result.reason,
    })
end

Router.Register(Const.CMD_SEMANTIC_TASK_REQUEST, function(player, args)
    local service = PNC.Semantics and PNC.Semantics.TaskRequestService
    local result
    if service and type(service.Submit) == "function" then
        result = service.Submit(args or {}, {
            player = player,
            npcID = args and args.npcID,
            scope = args and args.scope,
            requestID = args and args.requestID,
            conversationID = args and args.conversationID,
            conversationToken = args and args.conversationToken
                or args and args.token,
        })
    else
        result = {
            accepted = false,
            status = "failed",
            reason = "semantic_task_service_unavailable",
        }
    end
    sendResult(player, args, result)
end)
