-- Semantic request transport for the client request façade.
--
-- These requests are intentionally separate from broad bootstrap, debug, and
-- colony requests. They carry only the current dialogue contract across the
-- client/server boundary.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function campDiagnostics()
    local perceptionDebug = PNC.PerceptionDebug
    local diagnostics = perceptionDebug
        and perceptionDebug.CampDiagnostics or nil
    if diagnostics and type(diagnostics.RecordClient) == "function" then
        return diagnostics
    end
    pcall(require,
        "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics")
    perceptionDebug = PNC.PerceptionDebug
    diagnostics = perceptionDebug
        and perceptionDebug.CampDiagnostics or nil
    return diagnostics
end

local function recordSemanticCampClient(status, reason, request, context,
    hint)
    local diagnostics = campDiagnostics()
    if diagnostics and type(diagnostics.RecordClient) == "function" then
        diagnostics.RecordClient(status, reason, {
            commandID = "camp",
            npcID = request and request.npcID
                or context and (context.npcID or context.targetID),
            scope = request and request.scope or context and context.scope,
            requestID = request and request.requestID
                or context and context.requestID,
            commandSource = context and (
                context.commandSource or context.source or context.origin),
        }, hint)
    end
end

local function recordSemanticCampServer(result, request, context)
    local diagnostics = campDiagnostics()
    if diagnostics and type(diagnostics.RecordServer) == "function" then
        result = type(result) == "table" and result or {}
        diagnostics.RecordServer({
            commandID = "camp",
            npcID = result.npcID or request and request.npcID
                or context and (context.npcID or context.targetID),
            scope = result.siteScope or request and request.scope
                or context and context.scope,
            requestID = result.requestID or request and request.requestID
                or context and context.requestID,
            commandSource = context and (
                context.commandSource or context.source or context.origin),
            accepted = result.accepted == true,
            reason = result.reason or result.status,
            siteLabel = result.siteLabel,
            siteScope = result.siteScope,
            siteID = result.siteID,
            siteRoomType = result.siteRoomType,
        })
    end
end

-- Semantic task requests are contracts only. In multiplayer they cross the
-- normal client-command boundary; in singleplayer the same server service is
-- called directly so local-first dialogue does not depend on an LLM bridge.
function Client.RequestSemanticTask(request, context)
    context = type(context) == "table" and context or {}
    if type(request) ~= "table" then
        return false, "semantic_task_request_missing"
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if string.upper(tostring(request.action or "")) == "CAMP"
        and player
        and type(request.target) == "table"
        and request.target.kind == "camp_site"
        and type(request.target.clientHint) ~= "table"
    then
        -- Dialogue CAMP is client-observed just like the command path. The
        -- hint search already happened at the action boundary; do not turn a
        -- missing local observation into a server-wide fallback scan.
        recordSemanticCampClient("REJECTED", "camp_no_visible_site",
            request, context)
        return false, "camp_no_visible_site"
    end
    local payload = {}
    for key, value in pairs(request) do payload[key] = value end
    payload.npcID = payload.npcID or context.npcID or context.targetID
    payload.scope = payload.scope or context.scope or "single"
    payload.conversationID = payload.conversationID
        or context.conversationID
    payload.conversationToken = payload.conversationToken
        or context.conversationToken or context.token
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_SEMANTIC_TASK_REQUEST,
            payload
        )
        if string.upper(tostring(payload.action or "")) == "CAMP" then
            recordSemanticCampClient("PENDING", "network_queued", payload,
                context, payload.target and payload.target.clientHint)
        end
        return true, "sent"
    end
    local service = PNC.Semantics and PNC.Semantics.TaskRequestService
    if not service or type(service.Submit) ~= "function" then
        return false, "semantic_task_service_unavailable"
    end
    local result = service.Submit(payload, {
        player = player,
        npcID = payload.npcID,
        scope = payload.scope,
        conversationToken = payload.conversationToken,
    })
    if type(result) ~= "table" then
        if string.upper(tostring(payload.action or "")) == "CAMP" then
            recordSemanticCampServer({
                accepted = result == true,
                reason = result == true and "accepted" or "rejected",
            }, payload, context)
        end
        return result == true, result == true and "accepted" or "rejected"
    end
    if string.upper(tostring(payload.action or "")) == "CAMP" then
        recordSemanticCampServer(result, payload, context)
    end
    return result.accepted == true, result.reason or result.status, result
end

-- Read-only semantic inventory queries use their own transport and response
-- contract. They must never enter the semantic task/action-plan path.
function Client.RequestSemanticInventoryQuery(request, context)
    context = type(context) == "table" and context or {}
    if type(request) ~= "table" then
        return false, "semantic_inventory_query_missing"
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local payload = {}
    for key, value in pairs(request) do payload[key] = value end
    payload.requestID = payload.requestID
        or Internal.RequestID("semantic_inventory_query")
    payload.npcID = payload.npcID or context.npcID or context.targetID
    payload.conversationID = payload.conversationID
        or context.conversationID
    payload.conversationToken = payload.conversationToken
        or context.conversationToken or context.token
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_SEMANTIC_INVENTORY_QUERY_REQUEST,
            payload
        )
        return true, "pending", {
            accepted = true,
            status = "pending",
            requestID = payload.requestID,
            npcID = payload.npcID,
        }
    end

    local service = PNC.Semantics
        and PNC.Semantics.InventoryQueryService
    if not service or type(service.HandleRequest) ~= "function" then
        return false, "semantic_inventory_query_service_unavailable"
    end
    local result = service.HandleRequest(payload, {
        player = player,
        npcID = payload.npcID,
        conversationID = payload.conversationID,
        conversationToken = payload.conversationToken,
    })
    if type(result) ~= "table" then
        return false, "semantic_inventory_query_failed"
    end
    return result.accepted == true, result.reason or result.status, result
end

return Client
