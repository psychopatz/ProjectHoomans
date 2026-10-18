-- Authoritative ingress for the fixed semantic quest contract.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local MAX_RECENT_REQUESTS = 64
local recentRequests = {}
local recentRequestOrder = {}

local function bounded(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    return string.sub(value, 1, tonumber(maximum) or 128)
end

local function requestKey(player, args)
    args = type(args) == "table" and args or {}
    local requestID = bounded(args.requestID, 128)
    if not requestID or requestID == "" then return nil end
    local playerID
    if type(player) == "table" then
        playerID = player.characterUUID
            or (type(player.getOnlineID) == "function"
                and player:getOnlineID())
    end
    playerID = bounded(playerID or player, 128) or "unknown"
    return table.concat({ playerID, requestID,
        bounded(args.giverNPCID or args.npcID, 128) or "",
        bounded(args.questID, 96) or "",
        bounded(args.operation, 32) or "",
    }, "\31")
end

local function normalizedResult(args, result)
    args = type(args) == "table" and args or {}
    result = type(result) == "table" and result or {}
    local instance = type(result.instance) == "table"
        and result.instance or {}
    local objective = type(result.objective) == "table"
        and result.objective or instance.objective or {}
    return {
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
    }
end

local function sendResult(player, payload)
    if not player or type(sendServerCommand) ~= "function" then return end
    sendServerCommand(player, Const.MODULE, Const.CMD_SEMANTIC_QUEST_RESULT,
        payload)
end

local function remember(key, payload)
    if not key then return end
    recentRequests[key] = payload
    recentRequestOrder[#recentRequestOrder + 1] = key
    while #recentRequestOrder > MAX_RECENT_REQUESTS do
        local old = table.remove(recentRequestOrder, 1)
        recentRequests[old] = nil
    end
end

Router.Register(Const.CMD_SEMANTIC_QUEST_REQUEST, function(player, args)
    local key = requestKey(player, args)
    local cached = key and recentRequests[key] or nil
    if cached then
        local duplicate = {}
        for field, value in pairs(cached) do
            if field ~= "objective" then duplicate[field] = value end
        end
        duplicate.objective = {}
        for field, value in pairs(cached.objective or {}) do
            duplicate.objective[field] = value
        end
        duplicate.duplicate = true
        duplicate.reason = "duplicate_request"
        sendResult(player, duplicate)
        return
    end
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
    local payload = normalizedResult(args, result)
    remember(key, payload)
    sendResult(player, payload)
end)
