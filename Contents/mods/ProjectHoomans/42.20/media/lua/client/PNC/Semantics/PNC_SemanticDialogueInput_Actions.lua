-- Side-effect boundary for semantic dialogue actions.
-- Known movement actions use the existing authoritative command transport;
-- task actions use only explicitly registered domain transports.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local CommandAdapter = PNC.Semantics.CommandAdapter
local TaskAdapter = PNC.Semantics.TaskAdapter
local InventoryQueryAdapter = PNC.Semantics.InventoryQueryAdapter

local function actionContext(view, result, value)
    local spec = view and view.spec or {}
    local session = view and view.session
    local actorID = session and session.characterUUID
    local recipientID = spec.npcID
    local lifecycle = spec.context
        and spec.context.conversationLifecycleState or nil
    return {
        npcID = spec.npcID,
        targetID = spec.npcID,
        actor = actorID and { id = actorID } or nil,
        recipient = recipientID and { id = recipientID } or nil,
        dialogueID = session and session.conversationID,
        conversationID = session and session.conversationID,
        requestID = result.sequence,
        scope = "single",
        rawText = value,
        normalizedText = result.ir and result.ir.normalizedText,
        confidence = result.ir and result.ir.confidence,
        provenance = result.ir and result.ir.provenance,
        conversationToken = lifecycle and lifecycle.token or nil,
    }
end

function Internal.DispatchInventoryQuery(view, result, value)
    local decision = result and result.decision or {}
    if type(decision.inventoryQuery) ~= "table"
        or type(InventoryQueryAdapter) ~= "table"
        or type(InventoryQueryAdapter.Dispatch) ~= "function"
    then
        return nil
    end
    local context = actionContext(view, result, value)
    local session = view and view.session
    session.semanticInventoryQueries = session.semanticInventoryQueries or {}
    local requestID = context.requestID
    session.semanticInventoryQueries[tostring(requestID)] = {
        rawText = value,
        query = decision.inventoryQuery,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
    local dispatched = InventoryQueryAdapter.Dispatch(
        decision.inventoryQuery, context)
    dispatched = type(dispatched) == "table" and dispatched or {
        status = "rejected", accepted = false,
    }
    dispatched.requestID = dispatched.request
        and dispatched.request.requestID or requestID
    dispatched.query = decision.inventoryQuery
    if dispatched.result and dispatched.result.status
        and dispatched.result.status ~= "pending"
        and Input.ReceiveInventoryQueryResult
    then
        Input.ReceiveInventoryQueryResult(dispatched.result)
    end
    return dispatched
end

function Internal.DispatchAction(view, result, value)
    local decision = result and result.decision or {}
    if decision.inventoryQuery then
        return Internal.DispatchInventoryQuery(view, result, value)
    end
    if not decision.actionIntent then return nil end
    local context = actionContext(view, result, value)
    local commandResult = CommandAdapter.Dispatch(
        decision.actionIntent, context)
    if commandResult.status ~= "unmapped" then return commandResult end
    return TaskAdapter.Dispatch(decision.actionIntent, context)
end

return Input
