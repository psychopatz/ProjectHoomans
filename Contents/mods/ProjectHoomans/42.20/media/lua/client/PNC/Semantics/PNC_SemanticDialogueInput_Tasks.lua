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

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function activeView(payload)
    local candidates = {}
    local active = Input.ActiveView
    local activeGroup = active and active.groupConversation or nil
    if activeGroup and payload and payload.npcID
        and type(activeGroup.ViewFor) == "function"
    then
        local memberView = activeGroup:ViewFor(payload.npcID)
        if memberView and memberView.session
            and memberView.closed ~= true
            and memberView.lifecycleFinished ~= true
        then
            return memberView
        end
    end
    if active then candidates[#candidates + 1] = active end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local visible = conversation and conversation.instance or nil
    if visible and visible ~= active then
        candidates[#candidates + 1] = visible
    end
    for index = 1, #candidates do
        local view = candidates[index]
        local session = view and view.session or nil
        if view and session and view.closed ~= true
            and view.lifecycleFinished ~= true
        then
            if not payload or not payload.npcID
                or tostring(view.spec and view.spec.npcID or "")
                    == tostring(payload.npcID)
            then
                return view
            end
        end
    end
    return nil
end

local function cacheResult(payload)
    local state = PNC.Network and PNC.Network.ClientState or nil
    if not state then return end
    state.semanticTaskResults = state.semanticTaskResults or {}
    state.semanticTaskResultOrder = state.semanticTaskResultOrder or {}
    local requestID = tostring(payload and payload.requestID or "")
    if requestID == "" then return end
    if state.semanticTaskResults[requestID] == nil then
        state.semanticTaskResultOrder[#state.semanticTaskResultOrder + 1] =
            requestID
    end
    state.semanticTaskResults[requestID] = copyValue(payload)
    while #state.semanticTaskResultOrder > 16 do
        local old = table.remove(state.semanticTaskResultOrder, 1)
        state.semanticTaskResults[old] = nil
    end
end

local function actionName(payload, pending)
    return string.upper(tostring(payload and payload.action
        or pending and pending.action or ""))
end

local function responseFor(payload, pending)
    local action = actionName(payload, pending)
    local status = string.lower(tostring(payload and payload.status or ""))
    local reason = string.lower(tostring(payload and payload.reason or ""))
    if status == "completed" then
        if action == "GIVE" then
            return "Here you go."
        end
        if action == "WAIT_AT" then
            return "I'm here."
        end
        if action == "CAMP" then
            local label = payload.siteLabel or pending and pending.siteLabel
                or "the safe place"
            return "We're set up at " .. tostring(label) .. "."
        end
        if action == "EAT" then
            return "That hit the spot."
        end
        if action == "DRINK" then
            return "I feel better."
        end
        if action == "REFILL" then
            return "It's full now."
        end
        if action == "CONSUME" then
            return "That's done."
        end
        return "It's done."
    end
    if action == "GIVE"
        and (string.find(reason, "item", 1, true)
            or string.find(reason, "inventory", 1, true)
            or string.find(reason, "classification", 1, true))
    then
        return "I don't have that."
    end
    if (action == "EAT" or action == "DRINK" or action == "CONSUME")
        and (string.find(reason, "item", 1, true)
            or string.find(reason, "suitable", 1, true)
            or string.find(reason, "consum", 1, true)
            or string.find(reason, "classification", 1, true))
    then
        return "I don't have anything suitable."
    end
    if action == "REFILL"
        and (string.find(reason, "water", 1, true)
            or string.find(reason, "container", 1, true)
            or string.find(reason, "source", 1, true))
    then
        return "I can't refill that here."
    end
    if action == "CAMP" then
        if string.find(reason, "no_safe_room", 1, true)
            or string.find(reason, "no_room_or_campfire", 1, true)
        then
            return "I don't see a safe place to camp nearby."
        end
        if string.find(reason, "room_not_found", 1, true) then
            return "I can't find a safe room like that nearby."
        end
        if string.find(reason, "campfire", 1, true) then
            return "There isn't a usable campfire nearby."
        end
    end
    if action == "WAIT_AT"
        and (string.find(reason, "not_found", 1, true)
            or string.find(reason, "world_", 1, true)
            or string.find(reason, "target", 1, true))
    then
        return "I can't find that place nearby."
    end
    if reason == "npc_action_plan_active" then
        return "I'm still handling the last thing you asked."
    end
    if reason == "npc_action_plan_stale_cleanup_failed" then
        return "I need a moment to finish my last task."
    end
    if string.find(reason, "path", 1, true)
        or string.find(reason, "movement", 1, true)
    then
        return "I can't get there right now."
    end
    return "I couldn't do that right now."
end

local function queueResult(view, payload, pending)
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
    local text = responseFor(payload, pending)
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
            action = actionName(payload, pending),
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
    local view = activeView(payload)
    local session = view and view.session or nil
    local pending = session and session.semanticTaskRequests
        and session.semanticTaskRequests[requestID] or nil
    if not pending then
        cacheResult(payload)
        return false, "semantic_task_not_active"
    end

    local status = string.lower(tostring(payload.status or ""))
    if payload.accepted == true and (status == "accepted"
        or status == "sent" or status == "pending")
    then
        -- Admission is acknowledged by the existing deterministic response.
        -- Keep the request until the plan completes or fails.
        return true, "task_admitted"
    end

    session.semanticTaskRequests[requestID] = nil
    audit("semantic.task.presentation", {
        npcID = payload.npcID,
        requestID = requestID,
        action = actionName(payload, pending),
        status = payload.status,
        reason = payload.reason,
        siteLabel = payload.siteLabel,
        response = responseFor(payload, pending),
    }, { requestID = requestID })
    return queueResult(view, payload, pending)
end

return Input
