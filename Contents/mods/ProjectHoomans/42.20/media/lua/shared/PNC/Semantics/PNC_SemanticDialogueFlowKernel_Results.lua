-- Authoritative action results and bounded flow snapshots.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Kernel = PNC.Semantics.DialogueFlowKernel
local Internal = Kernel.Internal
local Registry = Internal.Registry
local copyValue = Internal.CopyValue
local contextStateFor = Internal.ContextStateFor
local readSession = Internal.ReadSession
local storeSession = Internal.StoreSession
local removeSession = Internal.RemoveSession
local sequenceFor = Internal.SequenceFor
local nodeFor = Internal.NodeFor
local completeActive = Internal.CompleteActive

local function resultOutcome(action, actionResult)
    local mapping = action and action.resultTransitions or {}
    local status = tostring(actionResult and actionResult.status or "")
    local reason = tostring(actionResult and actionResult.reason or "")
    local details = actionResult and actionResult.details
    local detailStatus = type(details) == "table"
        and tostring(details.status or "") or ""
    if actionResult and actionResult.accepted ~= true then
        if mapping[detailStatus] then
            return mapping[detailStatus], mapping[detailStatus]
        end
        if mapping[status] then
            return mapping[status], mapping[status]
        end
        if mapping[reason] then
            return mapping[reason], mapping[reason]
        end
        if status == "failed" or detailStatus == "failed"
            or reason == "task_transport_failed"
        then
            return "failed", mapping.failed or "failed"
        end
        return "rejected", mapping.rejected or "rejected"
    end
    if mapping[detailStatus] then
        return mapping[detailStatus], mapping[detailStatus]
    end
    if mapping[status] then
        return mapping[status], mapping[status]
    end
    if mapping[reason] then return mapping[reason], mapping[reason] end
    if status == "pending" or reason == "network_queued" then
        local fallback = mapping.queued and "queued" or "admitted"
        return fallback, mapping.queued or mapping.admitted or fallback
    end
    local fallback = mapping.admitted and "admitted" or "queued"
    return fallback, mapping.accepted or mapping[fallback] or fallback
end

-- Apply an authoritative result to a generated action node. This is a flow
-- state mutation only; the existing command/task adapter has already
-- dispatched once before this function is called.
function Kernel.ApplyActionResult(flowResult, actionResult, state, context, options)
    options = type(options) == "table" and options or {}
    if type(flowResult) ~= "table" or flowResult.generated ~= true
        or type(flowResult.action) ~= "table"
    then
        return nil, "generated_action_flow_unavailable"
    end
    context = type(context) == "table" and context or {}
    local storage = contextStateFor(state, context)
    local session = storage and readSession(storage, flowResult.key) or nil
    if not session or not session.active then
        return nil, "generated_action_session_unavailable"
    end
    local active = session.active
    local flow = Registry.Get(active.flowId or flowResult.flowId)
    local node = flow and nodeFor(flow, active.nodeId)
    if not node or type(node.action) ~= "table" then
        return nil, "generated_action_node_unavailable"
    end
    local outcome, target = resultOutcome(node.action, actionResult)
    if not target or target == "cancel" or target == "suspend"
        or target == "resume"
    then
        return nil, "generated_result_transition_unavailable"
    end
    local sequence = sequenceFor(state, storage)
    local result = copyValue(flowResult)
    result.resultOutcome = outcome
    result.resultStatus = actionResult and actionResult.status
    result.resultReason = actionResult and actionResult.reason
    result.resultNodeId = target
    result.toNodeId = target
    result.nodeId = target
    local targetNode = nodeFor(flow, target)
    result.responsePool = targetNode and targetNode.responsePool or nil
    result.responseTemplate = targetNode and targetNode.responseTemplate or nil
    result.transition = "result"
    result.diagnostics = result.diagnostics or {}
    result.diagnostics.resultOutcome = outcome
    result.diagnostics.resultNodeId = target
    result.diagnostics.resultReason = result.resultReason
    active.lastResult = {
        outcome = outcome,
        status = result.resultStatus,
        reason = result.resultReason,
        sequence = sequence,
    }
    active.nodeId = target
    active.lastSequence = sequence
    if targetNode and targetNode.terminal == true then
        completeActive(session, result)
    end
    session.lastTransition = "result"
    session.lastResult = copyValue(active.lastResult)
    if session.active or #session.suspended > 0 then
        session.revision = (tonumber(session.revision) or 0) + 1
        storeSession(storage, session)
        result.status = "advanced"
        result.active = copyValue(session.active)
        result.suspended = copyValue(session.suspended)
    else
        removeSession(storage, flowResult.key)
        result.status = "retired"
        result.active = nil
        result.suspended = {}
    end
    return result
end

function Kernel.Snapshot(state, context)
    local storage = contextStateFor(state, context)
    if type(storage) ~= "table" then return {} end
    if type(storage.FlowSnapshot) == "function" then
        return storage:FlowSnapshot()
    end
    local output = {}
    for index = 1, #(storage.flowOrder or {}) do
        local key = storage.flowOrder[index]
        if storage.flowSessions and storage.flowSessions[key] then
            output[#output + 1] = copyValue(storage.flowSessions[key])
        end
    end
    return output
end

return Kernel
