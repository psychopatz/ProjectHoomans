-- Delivery routing for detached responses, TTS handoff, and live text.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local RequestFlow = Internal.RequestFlow
local ToolFlow = Internal.ToolFlow
local SemanticResult = Internal.SemanticResult
local Presentation = Internal.ResponsePresentation
local Fallback = Internal.ResponseFallback
local Delivery = Internal.ResponseDelivery or {}
Internal.ResponseDelivery = Delivery
local Trace = PsychopatzCore and PsychopatzCore.DebugTrace
local SemanticTelemetryPrompt = require
    "PNC/Semantics/PNC_SemanticTelemetryPrompt"

local function anyAccepted(results)
    for _, result in ipairs(results) do
        if result.accepted == true then return true end
    end
    return false
end

local function providerFailed(arguments)
    return arguments and (
        arguments.provider_failure == true
        or arguments.providerFailure == true
        or arguments.context_eligible == false
        or arguments.contextEligible == false
    )
end

local function detached(pending, arguments)
    local calls = arguments and arguments.semantic_tool_calls
    local actionAttempted = type(calls) == "table" and #calls > 0
    if SemanticResult and SemanticResult.Apply then
        SemanticResult.Apply(pending, arguments)
    end
    local semanticResults = {}
    local view = pending.view
    if view and view.session then
        semanticResults = ToolFlow.Apply(
            pending.packet,
            arguments,
            pending.npcID,
            view.session
        )
    end
    local response, failed = Fallback.OrFailure(
        arguments,
        anyAccepted(semanticResults),
        actionAttempted,
        semanticResults,
        pending.packet,
        tostring(arguments.presentation_reason or "") == "tool_ack"
    )
    if Runtime.TraceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.response_detached",
            requestID = pending.requestID,
            data = {
                npcID = pending.npcID,
                arguments = arguments,
                semanticResults = semanticResults,
                fallbackResponse = response,
                presentation = "nameplate",
            },
        })
    end
    local message = Presentation.PublishDetached(pending, response, {
        kind = "llm",
        channel = "response_detached",
        requestID = pending.requestID,
        sessionID = pending.packet and pending.packet.session_id,
        providerFailure = failed == true,
        contextEligible = failed ~= true,
    })
    RequestFlow.Finish()
    return {
        accepted = message ~= nil,
        reason = message and "conversation_closed" or "conversation_unavailable",
        presentation = message and "nameplate" or nil,
        message_id = message and message.messageID or nil,
    }
end

local function liveResponse(pending, arguments)
    local view = pending and pending.view
    local session = view and view.session
    local semanticPending = session and session.semanticDialoguePending
    local rawText = semanticPending and semanticPending.rawText
    local semanticResult
    if SemanticResult and SemanticResult.Apply then
        semanticResult = SemanticResult.Apply(pending, arguments)
    end
    local decision = semanticResult and semanticResult.decision or {}
    if decision.branch == "ASK_CLARIFICATION"
        and SemanticTelemetryPrompt
        and type(SemanticTelemetryPrompt.Offer) == "function"
    then
        SemanticTelemetryPrompt.Offer(view, rawText, semanticResult, "llm")
    end
    local semanticResults = ToolFlow.Apply(
        pending.packet,
        arguments,
        pending.npcID,
        pending.view.session
    )
    local forceToolReply = tostring(arguments.presentation_reason or "")
        == "tool_ack"
    local response = forceToolReply and ""
        or Runtime.CleanResponseText(arguments.response_text)
    local failed = providerFailed(arguments)
    -- Provider failures may still carry a legacy/generic response from an
    -- older bridge. Let the authoritative semantic result own presentation.
    if failed then response = "" end
    if response == "" then
        response, failed = Fallback.OrFailure(
            arguments,
            anyAccepted(semanticResults),
            #semanticResults > 0,
            semanticResults,
            pending.packet,
            forceToolReply
        )
    end
    return response, failed, Runtime.DeclinedPortraitAnimation(semanticResults)
end

local function queueSpeech(pending, view, arguments, response, failed, animation)
    -- Keep the active request reserved until PBrainZ reports that the
    -- local OS audio process actually started. No audio bytes or model paths
    -- enter this payload.
    pending.ttsPending = true
    pending.utteranceID = Runtime.Trim(arguments.utterance_id)
    pending.conversationID = Runtime.Trim(arguments.conversation_id)
    pending.responseText = response
    pending.responseIsFailure = failed == true
    pending.portraitAnimation = animation
    pending.conversationToken = Runtime.ConversationTokenOf(pending.packet)
    local session = view.session
    session.llmPending = true
    session.busy = true
    view.historyPart:setTyping("npc")
    if Runtime.TraceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.presentation_queued",
            requestID = pending.requestID,
            data = {
                npcID = pending.npcID,
                mode = "tts",
                utteranceID = pending.utteranceID,
            },
        })
    end
    return {
        accepted = true,
        presentation = "tts_pending",
        utterance_id = pending.utteranceID,
    }
end

local function deliverText(pending, view, response, failed, animation)
    local requestID = pending.requestID
    local session = view.session
    session.pendingChoices = pending.packet and session.pendingChoices or {}
    local deliveredNpcID = pending.npcID
    Presentation.CompleteText(view, response, {
        kind = "llm",
        channel = "response",
        requestID = requestID,
        sessionID = pending.packet and pending.packet.session_id,
        messageID = "llm-response:" .. requestID,
        providerFailure = failed == true,
        contextEligible = failed ~= true,
        portraitAnimation = animation,
        conversationToken = Runtime.ConversationTokenOf(pending.packet),
    })
    if Runtime.TraceEnabled() then
        local Trace = PsychopatzCore and PsychopatzCore.DebugTrace
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.presentation_completed",
            requestID = requestID,
            data = {
                npcID = deliveredNpcID,
                mode = "conversation",
                messageID = "llm-response:" .. requestID,
            },
        })
    end
    return { accepted = true }
end

function Delivery.Deliver(pending, arguments)
    local view = pending.view
    local active = Runtime.CurrentView()
    if not view or view ~= active or not view.session
        or tostring(view.spec and view.spec.npcID or "") ~= pending.npcID
    then
        return detached(pending, arguments)
    end
    local response, failed, animation = liveResponse(pending, arguments)
    Runtime.Log(
        "response_deliver",
        "npc=" .. tostring(pending.npcID)
            .. " request=" .. tostring(pending.requestID)
            .. " chars=" .. tostring(#response)
            .. " response=" .. Runtime.LogText(response)
    )
    if tostring(arguments.presentation_mode or "") == "tts"
        and Runtime.Trim(arguments.utterance_id) ~= ""
    then
        return queueSpeech(pending, view, arguments, response, failed, animation)
    end
    return deliverText(pending, view, response, failed, animation)
end

return Delivery
