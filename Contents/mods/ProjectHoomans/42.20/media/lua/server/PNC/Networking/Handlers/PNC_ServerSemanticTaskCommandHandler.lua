-- Authoritative ingress for semantic task contracts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function bounded(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    maximum = tonumber(maximum) or 128
    return string.sub(value, 1, maximum)
end

local function sendResult(player, args, result)
    local details
    if not player or type(sendServerCommand) ~= "function" then return end
    args = type(args) == "table" and args or {}
    result = type(result) == "table" and result or {}
    details = type(result.details) == "table" and result.details or nil
    local request = type(result.request) == "table"
        and result.request or {}
    local site = details and type(details.site) == "table"
        and details.site or nil
    sendServerCommand(player, Const.MODULE, Const.CMD_SEMANTIC_TASK_RESULT, {
        requestID = bounded(result.requestID or request.requestID
            or args.requestID, 128),
        npcID = bounded(result.npcID or request.npcID or args.npcID, 128),
        action = bounded(result.action or request.action or args.action, 32),
        planID = bounded(result.planID, 160),
        accepted = result.accepted == true,
        status = bounded(result.status or (result.accepted == true
            and "accepted" or "rejected"), 32),
        reason = bounded(result.reason, 128),
        admissionReason = bounded(details and details.reason, 64),
        admissionPlanState = bounded(details and details.planState, 32),
        admissionStepState = bounded(details and details.stepState, 32),
        admissionActive = details and details.active == true,
        admissionPlanID = bounded(details and details.planID, 160),
        admissionCleanupReason = bounded(
            details and details.cleanupReason, 128),
        siteLabel = bounded(result.siteLabel or site and site.label, 64),
        siteScope = bounded(result.siteScope or site and site.scope, 16),
        siteID = bounded(result.siteID or site and site.siteID, 128),
        siteRoomType = bounded(result.roomType or site and site.roomType, 48),
        siteRisk = bounded(result.risk or site and site.risk, 32),
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
