-- Client presentation boundary for semantic task admission and completion.
-- The server remains authoritative; this spoke only turns bounded task
-- results into conversation messages and keeps failures visible.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local TaskResponses = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResponses"
local TaskResultPresentation = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResultPresentation"
local TaskResultRouting = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResultRouting"
local actionName = TaskResponses.ActionName

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function mergeCampSiteDetails(pending, payload)
    if type(pending) ~= "table" then return end
    local site = TaskResponses.CampSiteDetails(payload, pending)
    if not site then return end
    pending.siteLabel = site.label or pending.siteLabel
    pending.siteScope = site.scope or pending.siteScope
    pending.siteID = site.siteID or pending.siteID
    pending.siteRoomType = site.roomType or pending.siteRoomType
    pending.siteRisk = site.risk or pending.siteRisk
end

function Input.ReceiveSemanticTaskResult(payload)
    payload = type(payload) == "table" and payload or {}
    local requestID = tostring(payload.requestID or "")
    if requestID == "" then return false, "task_result_id_missing" end
    audit("semantic.task.result", {
        npcID = payload.npcID,
        requestID = requestID,
        action = payload.action,
        planID = payload.planID,
        accepted = payload.accepted == true,
        status = payload.status,
        reason = payload.reason,
        admissionReason = payload.admissionReason,
        admissionPlanState = payload.admissionPlanState,
        admissionStepState = payload.admissionStepState,
        admissionActive = payload.admissionActive,
        admissionPlanID = payload.admissionPlanID,
        admissionCleanupReason = payload.admissionCleanupReason,
        siteLabel = payload.siteLabel,
        siteScope = payload.siteScope,
        siteID = payload.siteID,
        siteRoomType = payload.siteRoomType,
        siteRisk = payload.siteRisk,
    }, { requestID = requestID })
    local view = TaskResultRouting.ActiveView(payload)
    local session = view and view.session or nil
    local pending = session and session.semanticTaskRequests
        and session.semanticTaskRequests[requestID] or nil
    if not pending then
        TaskResultRouting.CacheUnmatched(payload)
        return false, "semantic_task_not_active"
    end

    local status = string.lower(tostring(payload.status or ""))
    if payload.accepted == true and (status == "accepted"
        or status == "sent" or status == "pending")
    then
        -- Keep the request until the plan completes or fails, while retaining
        -- the authoritative site metadata for the eventual completion line.
        if actionName(payload, pending) == "CAMP" then
            mergeCampSiteDetails(pending, payload)
        end
        return true, "task_admitted"
    end

    session.semanticTaskRequests[requestID] = nil
    local action = actionName(payload, pending)
    audit("semantic.task.presentation", {
        npcID = payload.npcID,
        requestID = requestID,
        action = action,
        status = payload.status,
        reason = payload.reason,
        siteLabel = payload.siteLabel,
        response = TaskResponses.ForResult(payload, pending, action),
    }, { requestID = requestID })
    return TaskResultPresentation.QueueResult(view, payload, pending, action)
end

return Input
