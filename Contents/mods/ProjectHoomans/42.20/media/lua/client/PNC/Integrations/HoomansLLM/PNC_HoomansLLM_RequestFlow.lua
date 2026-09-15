-- Interactive request queue, lease reservation, and session preparation.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local State = Internal.State
local Runtime = Internal.Runtime
local Admission = Internal.RequestAdmission
local Session = Internal.RequestSession
local RequestFlow = Internal.RequestFlow or {}
Internal.RequestFlow = RequestFlow

local Speech = PNC.NameplateSpeech

function RequestFlow.ClearRequestState(item)
    local state = item and item.lifecycleState or nil
    if state and tostring(state.llmRequestID or "")
        == tostring(item.requestID or "")
    then
        state.llmRequestID = nil
    end
end

function RequestFlow.ActivateNext()
    State.Pending = table.remove(State.PendingQueue, 1)
    if State.Pending then
        Runtime.Log(
            "task_ready",
            "npc=" .. tostring(State.Pending.npcID)
                .. " request=" .. tostring(State.Pending.requestID)
        )
    end
    return State.Pending
end

function RequestFlow.Finish()
    local finished = State.Pending
    local context = finished and finished.packet
        and finished.packet.conversation_context or {}
    local client = PNC.Client
    local released
    local releaseReason
    if finished and client and client.ReleaseLLMRequest then
        released, releaseReason = client.ReleaseLLMRequest(
            finished.npcID,
            context.conversation_token,
            finished.requestID,
            "request_completed"
        )
        if released ~= true then
            Runtime.Log(
                "llm_request_release_failed",
                "npc=" .. tostring(finished.npcID)
                    .. " request=" .. tostring(finished.requestID)
                    .. " reason=" .. tostring(
                        releaseReason or "rejected"
                    )
            )
        else
            Runtime.Log(
                "llm_request_released",
                "npc=" .. tostring(finished.npcID)
                    .. " request=" .. tostring(finished.requestID)
                    .. " reason=" .. tostring(
                        releaseReason or "released"
                    )
            )
        end
    end
    RequestFlow.ClearRequestState(finished)
    if finished and Speech and Speech.ClearPending then
        Speech.ClearPending(finished.npcID, finished.requestID)
    end
    RequestFlow.ActivateNext()
    return finished
end

function Integration.Submit(view, value, part)
    if not Runtime.IsBridgeEnabled() then
        return false, "bridge_disabled"
    end
    if State.Pending or #State.PendingQueue > 0 then
        return false, "llm_request_pending"
    end
    local headless = view and view.headless == true
        and view.hoomansLLM == true
    if not view or (view ~= Runtime.CurrentView() and not headless)
        or not view.session
    then
        return false, "conversation_unavailable"
    end
    if not view:isConversationInteractive() then
        return false, "conversation_busy"
    end
    value = Runtime.Trim(value)
    if value == "" then return false, "empty_message" end
    value = string.sub(value, 1, State.MAX_INPUT_LENGTH)

    local views = Admission.RecipientViews(view, part)
    local items = {}
    local seen = {}
    local item
    local targetView
    for _, targetView in ipairs(views) do
        local targetID = targetView and targetView.spec
            and tostring(targetView.spec.npcID or "") or ""
        if targetID == "" or seen[targetID] then
            return false, "conversation_unavailable"
        end
        seen[targetID] = true
        local targetHeadless = targetView.headless == true
            and targetView.hoomansLLM == true
        if targetView ~= Runtime.CurrentView() and not targetHeadless then
            return false, "conversation_unavailable"
        end
        if not targetView.session
            or not targetView:isConversationInteractive()
        then
            return false, "conversation_busy"
        end
        item = Admission.Create(targetView, value)
        if not item then return false, "context_unavailable" end
        items[#items + 1] = item
    end
    if #items == 0 then return false, "conversation_unavailable" end
    local recipientCount = #items
    -- Build every packet before changing any session state. A multi-recipient
    -- send is therefore atomic if one context adapter cannot build its view.
    for _, queued in ipairs(items) do
        local reserved, reserveReason = Admission.Reserve(queued)
        if not reserved then
            for _, failedItem in ipairs(items) do
                RequestFlow.ClearRequestState(failedItem)
            end
            return false, reserveReason
        end
    end
    for _, queued in ipairs(items) do
        Session.Prepare(queued, value)
    end
    State.PendingQueue = items
    RequestFlow.ActivateNext()
    Runtime.Log(
        "chat_submit",
        "recipients=" .. tostring(recipientCount)
            .. " first_npc=" .. tostring(State.Pending.npcID)
            .. " request=" .. tostring(State.Pending.requestID)
            .. " chars=" .. tostring(#value)
            .. " message=" .. Runtime.LogText(value)
    )
    return true
end

function Integration.GetPending()
    return State.Pending
end

return RequestFlow
