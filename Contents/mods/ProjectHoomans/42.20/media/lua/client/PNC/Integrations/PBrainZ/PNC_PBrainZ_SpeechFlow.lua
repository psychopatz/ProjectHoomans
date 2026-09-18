-- Local TTS speech lifecycle for active and detached LLM responses.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local State = Internal.State
local Runtime = Internal.Runtime
local RequestFlow = Internal.RequestFlow
local ResponsePresentation = Internal.ResponsePresentation
local SpeechFlow = Internal.SpeechFlow or {}
Internal.SpeechFlow = SpeechFlow

local Speech = PNC.NameplateSpeech
local Trace = PsychopatzCore and PsychopatzCore.DebugTrace

local function pendingMatches(arguments)
    local pending = State.Pending
    return pending
        and pending.ttsPending
        and pending.requestID == Runtime.Trim(arguments and arguments.request_id)
        and pending.utteranceID == Runtime.Trim(arguments and arguments.utterance_id)
end

function Integration.SpeechStarted(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    if not pendingMatches(arguments) then
        return { accepted = false, reason = "speech_request_not_pending" }
    end
    local pending = State.Pending
    local view = pending.view
    local session = view and view.session
    if not view or view ~= Runtime.CurrentView() or not session then
        if Runtime.TraceEnabled() then
            Trace.Record({
                source = "ProjectHoomans",
                event = "llm.tts_detached",
                requestID = pending.requestID,
                data = {
                    npcID = pending.npcID,
                    utteranceID = pending.utteranceID,
                    presentation = "nameplate",
                },
            })
        end
        local message = ResponsePresentation.PublishDetached(
            pending, pending.responseText, {
            kind = "llm",
            channel = "tts_detached",
            requestID = pending.requestID,
            sessionID = pending.packet and pending.packet.session_id,
            utteranceID = pending.utteranceID,
            providerFailure = pending.responseIsFailure == true,
            contextEligible = pending.responseIsFailure ~= true,
        })
        RequestFlow.Finish()
        return {
            accepted = message ~= nil,
            reason = message and "conversation_closed" or "conversation_unavailable",
            presentation = message and "nameplate" or nil,
        }
    end
    local speech = {
        view = view,
        requestID = pending.requestID,
        conversationID = pending.conversationID,
        npcID = pending.npcID,
        utteranceID = pending.utteranceID,
    }
    session.queue = {
        {
            speaker = "__tts_hold",
            payload = { fallback = "", delayMs = math.huge },
            readyAt = math.huge,
        },
    }
    session.llmPending = nil
    session.busy = true
    session:append("npc", {
        fallback = pending.responseText,
        utterance_id = pending.utteranceID,
        speech_started = true,
    }, {
        source = {
            kind = "llm",
            channel = "tts",
            requestID = pending.requestID,
            sessionID = pending.packet and pending.packet.session_id,
            utteranceID = pending.utteranceID,
            messageID = "llm-response:" .. pending.requestID,
            providerFailure = pending.responseIsFailure == true,
            contextEligible = pending.responseIsFailure ~= true,
            conversationToken = pending.conversationToken,
        },
        portraitAnimation = pending.portraitAnimation,
    })
    view.historyPart:setTyping(nil)
    State.ActiveSpeech[pending.utteranceID] = speech
    RequestFlow.Finish()
    Runtime.Log(
        "speech_started",
        "npc=" .. tostring(speech.npcID)
            .. " utterance=" .. tostring(speech.utteranceID)
    )
    if Runtime.TraceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.speech_started",
            requestID = speech.requestID,
            data = {
                npcID = speech.npcID,
                utteranceID = speech.utteranceID,
            },
        })
    end
    return { accepted = true, presentation = "displayed" }
end

function Integration.SpeechFinished(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local utteranceID = Runtime.Trim(arguments.utterance_id)
    local speech = State.ActiveSpeech[utteranceID]
    if not speech
        or speech.requestID ~= Runtime.Trim(arguments.request_id)
        or speech.view ~= Runtime.CurrentView()
    then
        return { accepted = false, reason = "speech_not_active" }
    end
    State.ActiveSpeech[utteranceID] = nil
    local session = speech.view.session
    if session then
        session.queue = {}
        if session.finishPending then session:finishPending() end
    end
    Runtime.Log(
        "speech_finished",
        "npc=" .. tostring(speech.npcID)
            .. " utterance=" .. tostring(utteranceID)
    )
    return { accepted = true }
end

function Integration.SpeechFallback(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local pending = State.Pending
    if pendingMatches(arguments) then
        local view = pending.view
        local response = pending.responseText
        local npcID = pending.npcID
        if view and view == Runtime.CurrentView() and view.session then
            view.session.pendingChoices = pending.packet
                and view.session.pendingChoices or {}
            ResponsePresentation.CompleteText(view, response, {
                kind = "llm",
                channel = "tts_fallback",
                requestID = pending.requestID,
                sessionID = pending.packet and pending.packet.session_id,
                utteranceID = pending.utteranceID,
                messageID = "llm-response:" .. pending.requestID,
                providerFailure = pending.responseIsFailure == true,
                contextEligible = pending.responseIsFailure ~= true,
                portraitAnimation = pending.portraitAnimation,
                conversationToken = pending.conversationToken,
            })
            Runtime.Log(
                "speech_fallback",
                "npc=" .. tostring(arguments.npc_uuid or npcID)
                    .. " reason=" .. Runtime.LogText(arguments.error)
            )
            return { accepted = true, presentation = "text_only" }
        end
        local message = ResponsePresentation.PublishDetached(pending, response, {
            kind = "llm",
            channel = "tts_fallback_detached",
            requestID = pending.requestID,
            sessionID = pending.packet and pending.packet.session_id,
            utteranceID = pending.utteranceID,
            providerFailure = pending.responseIsFailure == true,
            contextEligible = pending.responseIsFailure ~= true,
        })
        RequestFlow.Finish()
        if message then
            return { accepted = true, presentation = "nameplate" }
        end
    end
    return { accepted = false, reason = "speech_request_not_pending" }
end

return SpeechFlow
