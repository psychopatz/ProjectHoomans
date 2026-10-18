-- Authoritative ingress for the fixed semantic quest contract.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function bounded(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    return string.sub(value, 1, tonumber(maximum) or 128)
end

local function sendResult(player, args, result)
    if not player or type(sendServerCommand) ~= "function" then return end
    args = type(args) == "table" and args or {}
    result = type(result) == "table" and result or {}
    local instance = type(result.instance) == "table"
        and result.instance or {}
    local objective = type(result.objective) == "table"
        and result.objective or instance.objective or {}
    sendServerCommand(player, Const.MODULE, Const.CMD_SEMANTIC_QUEST_RESULT, {
        requestID = bounded(result.requestID or args.requestID, 128),
        npcID = bounded(result.giverNPCID or result.npcID or args.npcID, 128),
        giverNPCID = bounded(result.giverNPCID or args.giverNPCID
            or args.npcID, 128),
        questID = bounded(result.questID or args.questID, 96),
        operation = bounded(result.operation or args.operation, 32),
        accepted = result.accepted == true,
        status = bounded(result.status or (result.accepted == true
            and "accepted" or "rejected"), 32),
        reason = bounded(result.reason, 128),
        responsePoolID = bounded(result.responsePoolID, 128),
        revision = tonumber(result.revision or instance.revision) or 0,
        instanceID = bounded(result.instanceID or instance.id, 128),
        objective = {
            id = bounded(objective.id, 64),
            required = tonumber(objective.required) or 0,
            delivered = tonumber(objective.delivered) or 0,
            itemFullType = bounded(objective.itemFullType, 96),
            direction = bounded(objective.direction, 32),
        },
    })
end

Router.Register(Const.CMD_SEMANTIC_QUEST_REQUEST, function(player, args)
    local service = PNC.QuestService
    local result
    if service and type(service.HandleRequest) == "function" then
        result = service.HandleRequest(player, args or {}, {
            network = true,
            conversationID = args and args.conversationID,
            conversationToken = args and (args.conversationToken
                or args.token),
        })
    else
        result = {
            accepted = false,
            status = "failed",
            reason = "semantic_quest_service_unavailable",
        }
    end
    sendResult(player, args, result)
end)
