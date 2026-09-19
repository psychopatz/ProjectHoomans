-- Authorizes query requests and builds compact response payloads.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.Semantics.InventoryQueryService
local Internal = Service.Internal
local Contract = Internal.Contract
local Diagnostics = Internal.Diagnostics
local copyValue = Internal.CopyValue

local function authority()
    return not PNC.Core or not PNC.Core.IsAuthority
        or PNC.Core.IsAuthority() == true
end

local function recordFor(request, context)
    local npcID = tostring(context.npcID or request.npcID or "")
    if npcID == "" then return nil, "npc_required" end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    if record.alive == false then return nil, "npc_unavailable" end
    return record
end

local function authorize(request, context, record)
    context = type(context) == "table" and context or {}
    if context.internal == true or not context.player then
        return true, "server_owned"
    end
    local token = tostring(context.conversationToken
        or request.conversationToken or "")
    if token == "" then return false, "conversation_token_required" end
    local authorityAPI = PNC.Conversation
        and PNC.Conversation.Authority
    local internal = authorityAPI and authorityAPI.Internal
    if not internal or type(internal.ValidateLease) ~= "function" then
        return false, "conversation_authority_unavailable"
    end
    return internal.ValidateLease(context.player, record, token)
end

local function resultPayload(request, status, reason, result)
    result = type(result) == "table" and result or {}
    request = type(request) == "table" and request or {}
    local payload = {
        accepted = status == "found" or status == "empty",
        status = status,
        reason = reason,
        requestID = request and request.requestID,
        npcID = request and request.npcID,
        conversationID = request and request.conversationID,
        query = copyValue(request and request.query),
        items = copyValue(result.items) or {},
        totalCount = tonumber(result.totalCount) or 0,
        distinctItems = tonumber(result.distinctItems) or 0,
        inventoryRevision = result.inventoryRevision,
    }
    if Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    then
        Diagnostics.Record("semantic.inventory.response", {
            npcID = payload.npcID,
            conversationID = payload.conversationID,
            requestID = payload.requestID,
            status = payload.status,
            accepted = payload.accepted == true,
            reason = payload.reason,
            query = payload.query,
            totalCount = payload.totalCount,
            distinctItems = payload.distinctItems,
            inventoryRevision = payload.inventoryRevision,
            items = payload.items,
        }, { requestID = payload.requestID })
    end
    return payload
end

function Service.HandleRequest(raw, context)
    context = type(context) == "table" and context or {}
    local request, reason = Contract.Normalize(raw)
    local record
    local authorized
    local result
    local status
    if not authority() then
        return resultPayload(raw, "failed", "server_authority_required")
    end
    if not request then return resultPayload(raw, "failed", reason) end
    context.npcID = context.npcID or request.npcID
    request.npcID = request.npcID or tostring(context.npcID or "")
    record, reason = recordFor(request, context)
    if not record then return resultPayload(request, "failed", reason) end
    authorized, reason = authorize(request, context, record)
    if authorized ~= true then
        return resultPayload(request, "failed", reason or "query_unauthorized")
    end
    result, reason = Service.Query(record, request.query, context)
    status = result and result.status or "failed"
    local payload = resultPayload(request, status, reason, result)
    if context.network == true and context.player and sendServerCommand then
        sendServerCommand(
            context.player,
            PNC.Const.MODULE,
            PNC.Const.CMD_SEMANTIC_INVENTORY_QUERY_RESULT,
            payload
        )
    end
    return payload
end

return Service
