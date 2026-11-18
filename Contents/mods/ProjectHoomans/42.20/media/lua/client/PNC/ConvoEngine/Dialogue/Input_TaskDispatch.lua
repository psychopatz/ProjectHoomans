-- Correlate a client task dispatch with admission and completion results.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/ConvoEngine/Dialogue/Input_Tasks"
local TaskResponses = require
    "PNC/ConvoEngine/Dialogue/Input_TaskResponses"
local TaskProjection = PNC.Semantics.TaskProjection
    or require "PNC/Semantics/PNC_SemanticTaskProjection"

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
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

function Internal.DispatchTaskAction(view, actionIntent, context, value)
    local taskAdapter = PNC.Semantics and PNC.Semantics.TaskAdapter
    if type(taskAdapter) ~= "table"
        or type(taskAdapter.Dispatch) ~= "function"
    then
        return {
            status = "task_adapter_unavailable",
            accepted = false,
            reason = "task_adapter_unavailable",
        }
    end

    local session = view and view.session
    local actionName = string.upper(tostring(
        actionIntent and actionIntent.action or ""
    ))
    if actionName == "WAIT_AT" then
        local projection = TaskProjection.Build({
            session = session,
            npcID = context and context.npcID,
            clientState = PNC.Network and PNC.Network.ClientState or nil,
            entry = view and view.spec and view.spec.context
                and view.spec.context.entry or nil,
            existing = context and context.taskProjection or nil,
        })
        local existing = projection[actionName]
        local st = type(existing) == "table"
            and tostring(existing.status or "") or ""
        if st == "active" or st == "completed" or st == "failed"
            or st == "rejected"
        then
            local reason = st == "active" and "task_already_active"
                or ("task_already_" .. st)
            local resultStatus = st == "active" and "rejected" or st
            return {
                status = resultStatus,
                accepted = false,
                reason = reason,
                action = actionName,
                details = {
                    status = resultStatus,
                    taskStatus = st,
                    duplicate = true,
                },
            }
        end
    end
    local provisionalID = context.requestID
    if session and provisionalID then
        session.semanticTaskRequests = session.semanticTaskRequests or {}
        -- Register before transport so a same-tick server response cannot
        -- race the request into the inactive-result cache.
        session.semanticTaskRequests[tostring(provisionalID)] = {
            action = actionIntent.action,
            rawText = value,
        }
    end
    local taskResult = taskAdapter.Dispatch(actionIntent, context)
    local status = tostring(taskResult and taskResult.status or "")
    local request = taskResult and taskResult.request or nil
    local requestID = request and request.requestID or context.requestID
    audit("semantic.task.dispatch", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = requestID,
        action = actionIntent.action,
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
            action = actionIntent.action,
            rawText = value,
            request = request,
            siteLabel = taskResult and taskResult.details
                and taskResult.details.siteLabel,
            siteScope = taskResult and taskResult.details
                and taskResult.details.siteScope,
            siteID = taskResult and taskResult.details
                and taskResult.details.siteID,
        }
    elseif session and provisionalID then
        session.semanticTaskRequests[tostring(provisionalID)] = nil
    end
    local preserveTaskResponse = TaskResponses
        and type(TaskResponses.UseExistingResultResponse) == "function"
        and TaskResponses.UseExistingResultResponse(
            taskResult, nil, actionIntent.action)
    if taskResult and taskResult.accepted ~= true
        and not (context.generatedFlow
            and context.generatedFlow.generated == true
            and preserveTaskResponse ~= true)
        and Input.ReceiveSemanticTaskResult
    then
        Input.ReceiveSemanticTaskResult({
            requestID = requestID,
            npcID = context.npcID,
            action = actionIntent.action,
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

return Internal.DispatchTaskAction
