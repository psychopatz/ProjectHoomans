-- Side-effect boundary for semantic dialogue actions.
-- Known movement actions use the existing authoritative command transport;
-- task actions use only explicitly registered domain transports.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local CommandAdapter = PNC.Semantics.CommandAdapter
local TaskAdapter = PNC.Semantics.TaskAdapter
local InventoryQueryAdapter = PNC.Semantics.InventoryQueryAdapter
local Diagnostics = PNC.Semantics.SemanticDiagnostics

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

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
    audit("semantic.inventory.dispatch", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = dispatched.requestID,
        status = dispatched.status,
        accepted = dispatched.accepted == true,
        pending = dispatched.pending == true,
        reason = dispatched.reason,
        query = decision.inventoryQuery,
    }, { requestID = dispatched.requestID })
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
    if commandResult.status ~= "unmapped" then
        audit("semantic.command.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = context.requestID,
            action = decision.actionIntent.action,
            status = commandResult.status,
            accepted = commandResult.accepted == true,
            reason = commandResult.reason,
        }, { requestID = context.requestID })
        return commandResult
    end
    local session = view and view.session
    local provisionalID = context.requestID
    if session and provisionalID then
        session.semanticTaskRequests = session.semanticTaskRequests or {}
        -- Register before transport so a same-tick server response cannot
        -- race the request into the inactive-result cache.
        session.semanticTaskRequests[tostring(provisionalID)] = {
            action = decision.actionIntent.action,
            rawText = value,
        }
    end
    local taskResult = TaskAdapter.Dispatch(decision.actionIntent, context)
    local status = tostring(taskResult and taskResult.status or "")
    local request = taskResult and taskResult.request or nil
    local requestID = request and request.requestID or context.requestID
    audit("semantic.task.dispatch", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = requestID,
        action = decision.actionIntent.action,
        status = status,
        accepted = taskResult and taskResult.accepted == true,
        reason = taskResult and taskResult.reason,
        planID = taskResult and taskResult.planID,
    }, { requestID = requestID })
    if session and requestID and status ~= "unmapped"
        and status ~= "skipped"
    then
        session.semanticTaskRequests = session.semanticTaskRequests or {}
        if provisionalID and tostring(provisionalID) ~= tostring(requestID) then
            session.semanticTaskRequests[tostring(provisionalID)] = nil
        end
        session.semanticTaskRequests[tostring(requestID)] = {
            action = decision.actionIntent.action,
            rawText = value,
            request = request,
        }
    elseif session and provisionalID then
        session.semanticTaskRequests[tostring(provisionalID)] = nil
    end
    if taskResult and taskResult.accepted ~= true
        and Input.ReceiveSemanticTaskResult
    then
        Input.ReceiveSemanticTaskResult({
            requestID = requestID,
            npcID = context.npcID,
            action = decision.actionIntent.action,
            accepted = false,
            status = status ~= "" and status or "failed",
            reason = taskResult.reason,
            admissionReason = taskResult.details
                and taskResult.details.reason,
            admissionPlanState = taskResult.details
                and taskResult.details.planState,
            admissionStepState = taskResult.details
                and taskResult.details.stepState,
            admissionActive = taskResult.details
                and taskResult.details.active,
            admissionPlanID = taskResult.details
                and taskResult.details.planID,
            admissionCleanupReason = taskResult.details
                and taskResult.details.cleanupReason,
        })
    end
    return taskResult
end

return Input
