-- Adapt an authoritative task result to a conversation message.
-- This spoke owns conversation/group delivery; it does not alter task state.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local TaskResponses = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResponses"

local TaskResultPresentation = {}

function TaskResultPresentation.QueueResult(view, payload, pending, action)
    action = action or TaskResponses.ActionName(payload, pending)
    local session = view and view.session
    if not session or type(session.queueMessage) ~= "function" then
        return false, "conversation_queue_unavailable"
    end
    local group = view and view.groupConversation
    local outputSession = group
        and type(group.PrimarySession) == "function"
        and group:PrimarySession() or session
    if not outputSession or type(outputSession.queueMessage) ~= "function" then
        return false, "conversation_queue_unavailable"
    end
    local requestID = tostring(payload.requestID or "")
    local text = TaskResponses.ForResult(payload, pending, action)
    local site = TaskResponses.CampSiteDetails(payload, pending)
    local speakerID
    local speakerName
    if group and type(group.SpeakerFor) == "function" then
        speakerID, speakerName = group:SpeakerFor(view)
    end
    outputSession:queueMessage("npc", {
        key = "semantic.task.result",
        domain = "pnc.system.shared.categories",
        fallback = text,
        text = text,
    }, {
        speakerID = speakerID,
        speakerName = speakerName,
        npcID = speakerID or view.spec and view.spec.npcID,
        participants = group and group.participantIDs or nil,
        source = {
            kind = "semantic",
            channel = "task_result",
            requestID = requestID,
            action = action,
            status = payload.status,
            reason = payload.reason,
            admissionReason = payload.admissionReason,
            admissionPlanState = payload.admissionPlanState,
            admissionStepState = payload.admissionStepState,
            admissionActive = payload.admissionActive,
            admissionPlanID = payload.admissionPlanID,
            admissionCleanupReason = payload.admissionCleanupReason,
            siteLabel = site and site.label or payload.siteLabel,
            siteScope = site and site.scope or payload.siteScope,
            siteID = site and site.siteID or payload.siteID,
            siteRoomType = site and site.roomType or payload.siteRoomType,
            siteRisk = site and site.risk or payload.siteRisk,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
        provenance = {
            provider = "server_semantic_task",
            requestID = requestID,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
    })
    return true
end

Internal.TaskResultPresentation = TaskResultPresentation

return TaskResultPresentation
