-- Client seam for read-only semantic inventory questions.
--
-- This adapter only transports a bounded query.  It cannot transfer items or
-- create a gameplay task; the authoritative answer comes back through the
-- normal server-command router.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Contract = PNC.Semantics.InventoryQuery
    or require "PNC/Semantics/PNC_SemanticInventoryQuery"
local Adapter = PNC.Semantics.InventoryQueryAdapter or {}
PNC.Semantics.InventoryQueryAdapter = Adapter

Adapter.VERSION = 1

function Adapter.Dispatch(query, context)
    context = type(context) == "table" and context or {}
    local request, reason = Contract.Normalize({
        requestID = context.requestID,
        source = "semantic_dialogue",
        npcID = context.npcID or context.targetID,
        conversationID = context.conversationID,
        conversationToken = context.conversationToken or context.token,
        confidence = context.confidence,
        rawText = context.rawText,
        normalizedText = context.normalizedText,
        query = query,
        provenance = context.provenance,
    })
    if not request then
        return {
            status = "rejected",
            accepted = false,
            reason = reason,
        }
    end
    local client = PNC.Client
    if not client or type(client.RequestSemanticInventoryQuery)
        ~= "function"
    then
        return {
            status = "unavailable",
            accepted = false,
            reason = "inventory_query_transport_unavailable",
            request = request,
        }
    end
    local accepted, resultReason, result =
        client.RequestSemanticInventoryQuery(request, context)
    result = type(result) == "table" and result or {}
    return {
        status = result.status
            or (accepted == true and "accepted" or "rejected"),
        accepted = accepted == true,
        pending = result.status == "pending",
        reason = resultReason,
        result = result,
        request = request,
    }
end

return Adapter
