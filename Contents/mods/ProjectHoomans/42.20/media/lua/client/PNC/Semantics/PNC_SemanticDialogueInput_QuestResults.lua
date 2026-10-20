-- Correlate authoritative quest-contract results and present one NPC line.
-- Quest state is never changed here; this spoke only owns conversation output.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDialogueInput_TaskResultRouting"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local TaskResultRouting = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResultRouting"
local Diagnostics = PNC.Semantics.SemanticDiagnostics

local QuestResponses = {}

local RESPONSE_BY_STATUS = {
    available = {
        key = "UI_PNC_Conversation_Semantic_QuestOffer",
        en = "I have a clinic-supplies request that you can help with.",
        tl = "May kahilingan ako para sa suplay ng klinika na matutulungan mo.",
    },
    accepted = {
        key = "UI_PNC_Conversation_Semantic_QuestAccepted",
        en = "Thank you. Please bring me one bandage for the clinic.",
        tl = "Salamat. Magdala ka ng isang benda para sa klinika.",
    },
    active = {
        key = "UI_PNC_Conversation_Semantic_QuestProgress",
        en = "The clinic still needs one bandage.",
        tl = "Kailangan pa ng klinika ng isang benda.",
    },
    ready = {
        key = "UI_PNC_Conversation_Semantic_QuestReady",
        en = "The clinic supplies are ready to turn in.",
        tl = "Handa nang ipasa ang mga suplay ng klinika.",
    },
    completed = {
        key = "UI_PNC_Conversation_Semantic_QuestCompleted",
        en = "The clinic-supplies request is complete.",
        tl = "Tapos na ang kahilingan para sa suplay ng klinika.",
    },
    rewarded = {
        key = "UI_PNC_Conversation_Semantic_QuestRewarded",
        en = "Thank you for bringing the clinic supplies.",
        tl = "Salamat sa pagdadala ng mga suplay ng klinika.",
    },
    locked = {
        key = "UI_PNC_Conversation_Semantic_QuestLocked",
        en = "I don't need those clinic supplies right now.",
        tl = "Hindi ko kailangan ang mga suplay ng klinika ngayon.",
    },
    failed = {
        key = "UI_PNC_Conversation_Semantic_QuestFailed",
        en = "I couldn't process that clinic-supplies request.",
        tl = "Hindi ko maproseso ang kahilingan para sa suplay.",
    },
}

local function normalized(value)
    return string.lower(tostring(value or ""))
end

local function currentLanguage()
    local translation = PNC.Translation
    if translation and type(translation.GetLanguage) == "function" then
        local ok, value = pcall(translation.GetLanguage)
        if ok and value then return string.upper(tostring(value)) end
    end
    local manager = rawget(_G, "CustomTranslationManager")
    if manager and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value then return string.upper(tostring(value)) end
    end
    return "EN"
end

function QuestResponses.IsQuestAction(actionResult, action)
    local binding = actionResult and actionResult.binding
    if type(binding) == "table"
        and binding.route == "existing_quest_contract"
    then
        return true
    end
    action = string.upper(tostring(
        action or actionResult and actionResult.action or ""))
    return action == "HELP"
        or action == "QUEST_ACCEPT"
        or action == "QUEST_STATUS"
        or action == "QUEST_TURN_IN"
end

function QuestResponses.UseExistingResultResponse(actionResult, action)
    return QuestResponses.IsQuestAction(actionResult, action)
end

function QuestResponses.ForResult(payload)
    payload = type(payload) == "table" and payload or {}
    local status = normalized(payload.status)
    local response = RESPONSE_BY_STATUS[status]
        or ((payload.accepted == false or status == "rejected")
            and RESPONSE_BY_STATUS.locked)
        or RESPONSE_BY_STATUS.failed
    local fallback = currentLanguage() == "TL" and response.tl or response.en
    local text = fallback
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local ok, localized = pcall(
            translation.GetKey, response.key, fallback)
        if ok and localized ~= nil and tostring(localized) ~= "" then
            text = tostring(localized)
        end
    end
    return {
        key = response.key,
        translationKey = response.key,
        domain = "pnc.system.shared.categories",
        text = text,
        fallback = fallback,
        args = {
            questID = payload.questID,
            status = status,
            reason = payload.reason,
            delivered = payload.objective and payload.objective.delivered,
            required = payload.objective and payload.objective.required,
        },
    }
end

Internal.QuestResponses = QuestResponses

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function cacheUnmatched(payload)
    local state = PNC.Network and PNC.Network.ClientState
    if not state then return false end
    state.semanticQuestResults = state.semanticQuestResults or {}
    state.semanticQuestResultOrder = state.semanticQuestResultOrder or {}
    local requestID = tostring(payload.requestID or "")
    if requestID == "" then return false end
    state.semanticQuestResults[requestID] = payload
    state.semanticQuestResultOrder[#state.semanticQuestResultOrder + 1] = requestID
    while #state.semanticQuestResultOrder > 16 do
        local old = table.remove(state.semanticQuestResultOrder, 1)
        state.semanticQuestResults[old] = nil
    end
    return true
end

function Input.ReceiveSemanticQuestResult(payload)
    payload = type(payload) == "table" and payload or {}
    local requestID = tostring(payload.requestID or "")
    if requestID == "" then return false, "quest_result_id_missing" end
    local view = TaskResultRouting.ActiveView(payload)
    if not view or not view.session then
        cacheUnmatched(payload)
        return false, "quest_result_conversation_unavailable"
    end
    local pending = view.session.semanticQuestRequests
        and view.session.semanticQuestRequests[requestID]
    if not pending then
        cacheUnmatched(payload)
        return false, "quest_result_not_pending"
    end
    view.session.semanticQuestRequests[requestID] = nil
    local group = view.groupConversation
    local outputSession = group
        and type(group.PrimarySession) == "function"
        and group:PrimarySession() or view.session
    if not outputSession or type(outputSession.queueMessage) ~= "function" then
        return false, "conversation_queue_unavailable"
    end
    local response = QuestResponses.ForResult(payload)
    local speakerID
    local speakerName
    if group and type(group.SpeakerFor) == "function" then
        speakerID, speakerName = group:SpeakerFor(view)
    end
    outputSession:queueMessage("npc", response, {
        speakerID = speakerID,
        speakerName = speakerName,
        npcID = speakerID or view.spec and view.spec.npcID,
        participants = group and group.participantIDs or nil,
        source = {
            kind = "semantic",
            channel = "quest_result",
            requestID = requestID,
            questID = payload.questID,
            operation = payload.operation,
            status = payload.status,
            reason = payload.reason,
            revision = payload.revision,
            objective = payload.objective,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
        provenance = {
            provider = "server_semantic_quest",
            requestID = requestID,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
    })
    audit("semantic.quest.presentation", {
        npcID = payload.npcID,
        requestID = requestID,
        questID = payload.questID,
        operation = payload.operation,
        status = payload.status,
        reason = payload.reason,
    }, { requestID = requestID })
    return true
end

return QuestResponses
