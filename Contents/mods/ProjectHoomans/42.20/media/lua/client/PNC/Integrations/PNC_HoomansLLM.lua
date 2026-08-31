-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PNC/Integrations/PNC_HoomansLLMContext"
require "PNC/Integrations/PNC_ConversationMemorySync"
require "PNC/UI/Nameplates/PNC_NameplateSpeech"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Layout = PsychopatzCore.Conversation.Layout
local Context = PNC.HoomansLLM.Context
local Message = PsychopatzCore.Conversation.Message
local Trace = PsychopatzCore.DebugTrace
local Speech = PNC.NameplateSpeech

if not Layout.defaults.llmInput then
    local choices = Layout.GetNormalized("choices")
    local inputHeight = 0.085
    local inputY = (choices.y or 0.64) + (choices.h or 0.27) + 0.008
    if inputY + inputHeight > 0.985 then
        inputY = 0.985 - inputHeight
    end
    Layout.defaults.llmInput = {
        x = choices.x or 0.26,
        y = inputY,
        w = choices.w or 0.43,
        h = inputHeight,
    }
end

-- Keep this aligned with the context adapter and the bridge string limit. The
-- old 1024-byte cap silently discarded most long player messages before the
-- provider ever saw them.
local MAX_INPUT_LENGTH = 4000
local MAX_LOG_TEXT = 900
local Pending = nil
local ActiveSpeech = {}
local serial = 0

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function logText(value)
    value = trim(value)
    value = string.gsub(value, "[%r\n]+", " ")
    if #value > MAX_LOG_TEXT then
        value = string.sub(value, 1, MAX_LOG_TEXT - 1) .. "…"
    end
    return value ~= "" and value or "<empty>"
end

local function log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " " .. tostring(details or ""))
    end
end

local function traceEnabled()
    return Trace and Trace.IsEnabled and Trace.IsEnabled() == true
end

local function bridgeEnabled()
    local bootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
    return bootstrap and bootstrap.IsEnabled
        and bootstrap:IsEnabled() == true
end

Integration.IsBridgeEnabled = bridgeEnabled

local function now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs()
        or 0
end

local function currentView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

local function buildPacket(view, requestID, message)
    local context = Context.Build(view, message)
    context.request_id = requestID
    context.session_id = context.session_id
        or "pnc_session_" .. tostring(now()) .. "_" .. tostring(serial)
    view.session.llmSessionID = context.session_id
    local packet = {
        status = "pending",
        request_id = requestID,
        npc_id = context.npc_uuid,
        world_uuid = context.world_uuid,
        player_uuid = context.player_uuid,
        session_id = context.session_id,
        npc_name = context.npc_name,
        player_name = context.player_name,
        model = "default",
        conversation_context = context,
    }
    if traceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.request_queued",
            requestID = requestID,
            data = packet,
        })
    end
    return packet
end

function Integration.Submit(view, value)
    if not bridgeEnabled() then
        return false, "bridge_disabled"
    end
    if Pending then return false, "llm_request_pending" end
    local headless = view and view.headless == true
        and view.hoomansLLM == true
    if not view or (view ~= currentView() and not headless)
        or not view.session
    then
        return false, "conversation_unavailable"
    end
    if not view:isConversationInteractive() then
        return false, "conversation_busy"
    end
    value = trim(value)
    if value == "" then return false, "empty_message" end
    value = string.sub(value, 1, MAX_INPUT_LENGTH)

    local session = view.session
    serial = serial + 1
    local requestID = "pnc_llm_" .. tostring(now()) .. "_" .. tostring(serial)
    -- Build the packet before changing the session state. If a context
    -- adapter is unavailable, the conversation remains usable instead of
    -- being left permanently in the waiting state.
    local packet = buildPacket(view, requestID, value)
    if not packet then return false, "context_unavailable" end
    local pendingChoices = session.currentNode and session.currentNode.choices or {}
    local inputMessage = session:append("player", value, {
        source = {
            kind = "llm",
            channel = "input",
            requestID = requestID,
            sessionID = packet.session_id,
        },
    })
    if inputMessage then packet.message_id = inputMessage.messageID end
    session.pendingChoices = pendingChoices
    session.pendingNext = nil
    session.pendingClose = nil
    session.pendingCloseReason = nil
    session.llmPending = true
    -- A never-ready queue item keeps the core session interactive lock held
    -- while the external provider is working. It is removed on delivery.
    session.queue = {
        {
            speaker = "npc",
            payload = { fallback = "", delayMs = math.huge },
            readyAt = math.huge,
        },
    }
    session.busy = true
    view.historyPart:setTyping("npc")
    Pending = {
        requestID = requestID,
        npcID = tostring(view.spec and view.spec.npcID or "unknown"),
        view = view,
        packet = packet,
        claimed = false,
    }
    if Speech and Speech.SetPending then
        Speech.SetPending(
            Pending.npcID,
            requestID,
            session.conversationID
        )
    end
    log(
        "chat_submit",
        "npc=" .. tostring(Pending.npcID)
            .. " request=" .. requestID
            .. " chars=" .. tostring(#value)
            .. " message=" .. logText(value)
    )
    return true
end

function Integration.Poll()
    if not Pending or Pending.claimed then return { status = "idle" } end
    Pending.claimed = true
    log(
        "task_polled",
        "npc=" .. tostring(Pending.npcID)
            .. " request=" .. tostring(Pending.requestID)
    )
    if traceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.request_polled",
            requestID = Pending.requestID,
            data = {
                npcID = Pending.npcID,
                sessionID = Pending.packet and Pending.packet.session_id,
            },
        })
    end
    return Pending.packet
end

local function exposedTool(packet, name)
    local context = packet and packet.conversation_context or {}
    local tools = context.available_tools or {}
    for _, tool in ipairs(tools) do
        local definition = tool and tool["function"] or nil
        if definition and tostring(definition.name or "") == name then
            return true
        end
    end
    local toolIDs = context.available_tool_ids or {}
    local expectedID = "projecthoomans.llm:" .. tostring(name or "")
    for _, toolID in ipairs(toolIDs) do
        if tostring(toolID) == expectedID then return true end
    end
    return false
end

local function applySemanticTools(packet, arguments, npcID, session)
    local calls = arguments and arguments.semantic_tool_calls
    local results = {}
    if type(calls) ~= "table" then return results end
    for index, call in ipairs(calls) do
        local name = trim(call and call.name)
        local callID = trim(call and call.id)
        if callID == "" then callID = "tool_" .. tostring(index) end
        local callArguments = call and type(call.arguments) == "table"
            and call.arguments or {}
        local result = { id = callID, name = name, accepted = false }
        if name == "social_react" and exposedTool(packet, name) then
            local execute = PNC.Client and PNC.Client.ExecuteLLMSocialReaction
            local kind = trim(callArguments.kind)
            if kind == "" then
                kind = trim(callArguments.reaction)
            end
            local intensity = trim(callArguments.intensity)
            if execute then
                result.accepted, result.reason = execute(
                    npcID,
                    kind,
                    intensity,
                    {
                        origin = "llm_tool",
                        requestID = packet and packet.request_id,
                        callID = callID,
                        token = packet and packet.conversation_context
                            and packet.conversation_context.conversation_token,
                    }
                )
                result.reaction = kind
                result.intensity = intensity
            else
                result.reason = "social_reaction_client_unavailable"
            end
        elseif string.find(name, "^order_") == 1 and exposedTool(packet, name) then
            local commandID = trim(callArguments.command_id)
            local definition = PNC.CompanionCommands
                and PNC.CompanionCommands.Get(commandID) or nil
            local execute = PNC.Client and PNC.Client.ExecuteCompanionCommand
            if definition and execute then
                result.accepted = execute(commandID, npcID, "conversation", {
                    origin = "llm_tool",
                    requestID = packet and packet.request_id,
                }) == true
                result.reason = result.accepted and "submitted" or "rejected_by_game"
            else
                result.reason = "unknown_command"
            end
        else
            result.reason = "tool_not_exposed"
        end
        results[#results + 1] = result
    end
    session.llmSemanticResults = results
    if traceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.tool_results",
            requestID = packet and packet.request_id,
            data = {
                npcID = npcID,
                calls = calls,
                results = results,
            },
        })
    end
    return results
end

local function completeTextResponse(view, response, source)
    local session = view and view.session
    if not session then return false end
    session.queue = {}
    session.llmPending = nil
    session.busy = true
    source = source or {}
    source.messageID = source.messageID
        or (source.requestID and "llm-response:" .. tostring(source.requestID))
    session:queueMessage("npc", { fallback = response }, {
        source = source,
        messageID = source.messageID,
    })
    Pending = nil
    return true
end

local function publishDetachedResponse(pending, response, source)
    local view = pending and pending.view
    local session = view and view.session
    local packet = pending and pending.packet or {}
    local context = packet.conversation_context or {}
    if not view then return nil end
    if session then
        session.queue = {}
        session.llmPending = nil
        session.busy = false
        session.pendingNext = nil
        session.pendingClose = nil
        session.pendingCloseReason = nil
        if session.historyPart then
            session.historyPart:setTyping(nil)
        elseif view.historyPart then
            view.historyPart:setTyping(nil)
        end
    end
    if Speech and Speech.ClearPending then
        Speech.ClearPending(pending.npcID, pending.requestID)
    end
    source = source or {}
    source.messageID = source.messageID
        or (source.requestID and "llm-response:" .. tostring(source.requestID))
    local payload = { fallback = response }
    local message = Message.New({
        messageID = source.messageID,
        saveUUID = context.world_uuid or Message.GetSaveID(),
        conversationID = context.conversation_id
            or context.session_id
            or "llm:" .. tostring(pending.requestID),
        sequence = 0,
        speaker = "npc",
        speakerID = pending.npcID,
        speakerName = context.npc_name,
        speakerKind = "npc",
        playerUUID = context.player_uuid,
        npcUUID = context.npc_uuid or pending.npcID,
        namespace = session and session.namespace or "default",
        payload = payload,
        text = response,
        gameDay = Message.GetGameDay(),
        worldAgeHours = Message.GetWorldAgeHours(),
        participants = context.participants,
        source = source,
        presentationState = { conversationUI = false, nameplate = true },
    })
    local History = PsychopatzCore.Conversation.History
        or require "PsychopatzCore/UI/Conversation/PsychopatzConversationHistory"
    if History and History.Append then
        History.Append(
            session and session.namespace or "default",
            pending.npcID,
            "npc",
            payload,
            session and session.characterUUID or context.player_uuid,
            message
        )
    end
    Message.Publish(message)
    if session and view.historyPart and view.historyPart.addMessage then
        view.historyPart:addMessage(message)
    end
    return message
end

local function responseOrFailure(arguments, actionAccepted, actionAttempted)
    local response = trim(arguments and arguments.response_text)
    if response ~= "" then return string.sub(response, 1, 3900), false end

    local failure = trim(arguments and arguments.error)
    if failure == "" and actionAccepted then
        return "I will take care of that.", false
    end
    if failure == "" and actionAttempted then
        return "I understand.", false
    end
    if failure == "" then
        local finishReason = trim(arguments and arguments.finish_reason)
        local toolCount = tonumber(arguments and arguments.tool_call_count) or 0
        failure = finishReason ~= ""
            and "provider returned an empty response (finish_reason="
                .. finishReason .. ", tool_calls=" .. tostring(toolCount) .. ")"
            or "provider returned an empty response"
    end
    if failure ~= "" then
        return "I cannot answer right now. (" .. string.sub(failure, 1, 420) .. ")", true
    end
    return "I cannot answer right now.", true
end

function Integration.Deliver(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local requestID = tostring(arguments.request_id or "")
    if not Pending or Pending.requestID ~= requestID or not Pending.claimed then
        return nil, "NOT_AVAILABLE", "LLM request is no longer active."
    end
    local view = Pending.view
    local active = currentView()
    if not view or view ~= active or not view.session
        or tostring(view.spec and view.spec.npcID or "") ~= Pending.npcID
    then
        local calls = arguments and arguments.semantic_tool_calls
        local actionAttempted = type(calls) == "table" and #calls > 0
        local semanticResults = {}
        if view and view.session then
            semanticResults = applySemanticTools(
                Pending.packet,
                arguments,
                Pending.npcID,
                view.session
            )
        end
        local actionAccepted = false
        for _, result in ipairs(semanticResults) do
            if result.accepted == true then actionAccepted = true break end
        end
        local response, providerFailure = responseOrFailure(
            arguments,
            actionAccepted,
            actionAttempted
        )
        if traceEnabled() then
            Trace.Record({
                source = "ProjectHoomans",
                event = "llm.response_detached",
                requestID = requestID,
                data = {
                    npcID = Pending.npcID,
                    arguments = arguments,
                    semanticResults = semanticResults,
                    fallbackResponse = response,
                    presentation = "nameplate",
                },
            })
        end
        local message = publishDetachedResponse(Pending, response, {
            kind = "llm",
            channel = "response_detached",
            requestID = requestID,
            sessionID = Pending.packet and Pending.packet.session_id,
            providerFailure = providerFailure == true,
            contextEligible = providerFailure ~= true,
        })
        Pending = nil
        return {
            accepted = message ~= nil,
            reason = message and "conversation_closed" or "conversation_unavailable",
            presentation = message and "nameplate" or nil,
            message_id = message and message.messageID or nil,
        }
    end

    local semanticResults = applySemanticTools(Pending.packet, arguments, Pending.npcID, view.session)
    local response = trim(arguments.response_text)
    local providerFailure = false
    if response == "" then
        local actionAccepted = false
        for _, result in ipairs(semanticResults) do
            if result.accepted == true then actionAccepted = true break end
        end
        response, providerFailure = responseOrFailure(
            arguments,
            actionAccepted,
            #semanticResults > 0
        )
    end
    response = string.sub(response, 1, 3900)
    if traceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.response_received",
            requestID = requestID,
            data = {
                npcID = Pending.npcID,
                arguments = arguments,
                semanticResults = semanticResults,
                presentation = "conversation_or_tts",
                finalResponse = response,
            },
        })
    end
    log(
        "response_deliver",
        "npc=" .. tostring(Pending.npcID)
            .. " request=" .. requestID
            .. " chars=" .. tostring(#response)
            .. " response=" .. logText(response)
    )
    local session = view.session
    if tostring(arguments.presentation_mode or "") == "tts"
        and trim(arguments.utterance_id) ~= ""
    then
        -- Keep the active request reserved until HoomansLLM reports that the
        -- local OS audio process actually started.  No audio bytes or model
        -- paths enter this payload.
        Pending.ttsPending = true
        Pending.utteranceID = trim(arguments.utterance_id)
        Pending.conversationID = trim(arguments.conversation_id)
        Pending.responseText = response
        Pending.responseIsFailure = providerFailure == true
        session.llmPending = true
        session.busy = true
        view.historyPart:setTyping("npc")
        if traceEnabled() then
            Trace.Record({
                source = "ProjectHoomans",
                event = "llm.presentation_queued",
                requestID = requestID,
                data = {
                    npcID = Pending.npcID,
                    mode = "tts",
                    utteranceID = Pending.utteranceID,
                },
            })
        end
        return {
            accepted = true,
            presentation = "tts_pending",
            utterance_id = Pending.utteranceID,
        }
    end
    session.pendingChoices = Pending.packet and session.pendingChoices or {}
    local deliveredNpcID = Pending.npcID
    completeTextResponse(view, response, {
        kind = "llm",
        channel = "response",
        requestID = requestID,
        sessionID = Pending.packet and Pending.packet.session_id,
        messageID = "llm-response:" .. requestID,
        providerFailure = providerFailure == true,
        contextEligible = providerFailure ~= true,
    })
    if traceEnabled() then
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

local function pendingMatches(arguments)
    return Pending
        and Pending.ttsPending
        and Pending.requestID == trim(arguments and arguments.request_id)
        and Pending.utteranceID == trim(arguments and arguments.utterance_id)
end

function Integration.SpeechStarted(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    if not pendingMatches(arguments) then
        return { accepted = false, reason = "speech_request_not_pending" }
    end
    local view = Pending.view
    local session = view and view.session
    if not view or view ~= currentView() or not session then
        if traceEnabled() then
            Trace.Record({
                source = "ProjectHoomans",
                event = "llm.tts_detached",
                requestID = Pending.requestID,
                data = {
                    npcID = Pending.npcID,
                    utteranceID = Pending.utteranceID,
                    presentation = "nameplate",
                },
            })
        end
        local message = publishDetachedResponse(Pending, Pending.responseText, {
            kind = "llm",
            channel = "tts_detached",
            requestID = Pending.requestID,
            sessionID = Pending.packet and Pending.packet.session_id,
            utteranceID = Pending.utteranceID,
            providerFailure = Pending.responseIsFailure == true,
            contextEligible = Pending.responseIsFailure ~= true,
        })
        Pending = nil
        return {
            accepted = message ~= nil,
            reason = message and "conversation_closed" or "conversation_unavailable",
            presentation = message and "nameplate" or nil,
        }
    end
    local speech = {
        view = view,
        requestID = Pending.requestID,
        conversationID = Pending.conversationID,
        npcID = Pending.npcID,
        utteranceID = Pending.utteranceID,
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
        fallback = Pending.responseText,
        utterance_id = Pending.utteranceID,
        speech_started = true,
    }, {
        source = {
            kind = "llm",
            channel = "tts",
            requestID = Pending.requestID,
            sessionID = Pending.packet and Pending.packet.session_id,
            utteranceID = Pending.utteranceID,
            messageID = "llm-response:" .. Pending.requestID,
            providerFailure = Pending.responseIsFailure == true,
            contextEligible = Pending.responseIsFailure ~= true,
        },
    })
    view.historyPart:setTyping(nil)
    ActiveSpeech[Pending.utteranceID] = speech
    Pending = nil
    log(
        "speech_started",
        "npc=" .. tostring(speech.npcID)
            .. " utterance=" .. tostring(speech.utteranceID)
    )
    if traceEnabled() then
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
    local utteranceID = trim(arguments.utterance_id)
    local speech = ActiveSpeech[utteranceID]
    if not speech
        or speech.requestID ~= trim(arguments.request_id)
        or speech.view ~= currentView()
    then
        return { accepted = false, reason = "speech_not_active" }
    end
    ActiveSpeech[utteranceID] = nil
    local session = speech.view.session
    if session then
        session.queue = {}
        if session.finishPending then session:finishPending() end
    end
    log(
        "speech_finished",
        "npc=" .. tostring(speech.npcID)
            .. " utterance=" .. tostring(utteranceID)
    )
    return { accepted = true }
end

function Integration.SpeechFallback(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    if pendingMatches(arguments) then
        local view = Pending.view
        local response = Pending.responseText
        local npcID = Pending.npcID
        if view and view == currentView() and view.session then
            view.session.pendingChoices = Pending.packet
                and view.session.pendingChoices or {}
            completeTextResponse(view, response, {
                kind = "llm",
                channel = "tts_fallback",
                requestID = Pending.requestID,
                sessionID = Pending.packet and Pending.packet.session_id,
                utteranceID = Pending.utteranceID,
                messageID = "llm-response:" .. Pending.requestID,
                providerFailure = Pending.responseIsFailure == true,
                contextEligible = Pending.responseIsFailure ~= true,
            })
            log(
                "speech_fallback",
                "npc=" .. tostring(arguments.npc_uuid or npcID)
                    .. " reason=" .. logText(arguments.error)
            )
            return { accepted = true, presentation = "text_only" }
        end
        local message = publishDetachedResponse(Pending, response, {
            kind = "llm",
            channel = "tts_fallback_detached",
            requestID = Pending.requestID,
            sessionID = Pending.packet and Pending.packet.session_id,
            utteranceID = Pending.utteranceID,
            providerFailure = Pending.responseIsFailure == true,
            contextEligible = Pending.responseIsFailure ~= true,
        })
        Pending = nil
        if message then
            return { accepted = true, presentation = "nameplate" }
        end
    end
    return { accepted = false, reason = "speech_request_not_pending" }
end

function Integration.GetPending()
    return Pending
end

return Integration
