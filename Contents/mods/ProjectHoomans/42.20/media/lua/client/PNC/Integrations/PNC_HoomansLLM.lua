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
local PendingQueue = {}
local ActiveSpeech = {}
local serial = 0

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function cleanResponseText(value)
    value = trim(value)
    -- Text-only providers such as Horde may stop inside the optional action
    -- envelope. It is a protocol fragment, never NPC dialogue. Complete
    -- envelopes should already have been extracted by PBrainZ; this is a
    -- defensive presentation boundary for older or partial bridge replies.
    value = string.gsub(
        value,
        "<projecthoomans%-action>[%s%S]-</projecthoomans%-action>",
        ""
    )
    value = string.gsub(
        value,
        "<projecthoomans%-action[^>]*>[%s%S]*$",
        ""
    )
    value = string.gsub(value, "</projecthoomans%-action%s*>", "")
    return trim(value)
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

local function recipientViews(view, part)
    local inline = Integration.Inline
    if part and inline and part == inline.part
        and tostring(part.inputMode or "nearest") == "nearby"
        and type(inline.hosts) == "table"
        and #inline.hosts > 0
    then
        return inline.hosts
    end
    return { view }
end

local function queueItem(view, value)
    serial = serial + 1
    local requestID = "pnc_llm_" .. tostring(now()) .. "_" .. tostring(serial)
    local packet = buildPacket(view, requestID, value)
    local lifecycleState = view and view.spec and view.spec.context
        and view.spec.context.conversationLifecycleState
        or view and view.lifecycleState or nil
    if not packet then return nil end
    if lifecycleState then lifecycleState.llmRequestID = requestID end
    return {
        requestID = requestID,
        npcID = tostring(view.spec and view.spec.npcID or "unknown"),
        view = view,
        packet = packet,
        lifecycleState = lifecycleState,
        claimed = false,
    }
end

local function clearLLMRequestState(item)
    local state = item and item.lifecycleState or nil
    if state and tostring(state.llmRequestID or "")
        == tostring(item.requestID or "")
    then
        state.llmRequestID = nil
    end
end

local function reserveQueueItem(item)
    local client = PNC.Client
    local context = item and item.packet
        and item.packet.conversation_context or {}
    if not client or not client.ReserveLLMRequest then
        return true
    end
    local accepted, reason = client.ReserveLLMRequest(
        item.npcID,
        context.conversation_token,
        item.requestID
    )
    if accepted ~= true then
        log(
            "llm_request_reserve_failed",
            "npc=" .. tostring(item.npcID)
                .. " request=" .. tostring(item.requestID)
                .. " reason=" .. tostring(reason or "rejected")
        )
        return false, reason or "llm_request_reserve_failed"
    end
    log(
        "llm_request_reserved",
        "npc=" .. tostring(item.npcID)
            .. " request=" .. tostring(item.requestID)
            .. " reason=" .. tostring(reason or "reserved")
    )
    return true
end

local function prepareQueueItem(item, value)
    local view = item.view
    local session = view.session
    local pendingChoices = session.currentNode
        and session.currentNode.choices or {}
    local inputMessage = session:append("player", value, {
        source = {
            kind = "llm",
            channel = "input",
            requestID = item.requestID,
            sessionID = item.packet.session_id,
        },
    })
    if inputMessage then item.packet.message_id = inputMessage.messageID end
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
    if Speech and Speech.SetPending then
        Speech.SetPending(
            item.npcID,
            item.requestID,
            session.conversationID
        )
    end
end

local function activateNextPending()
    Pending = table.remove(PendingQueue, 1)
    if Pending then
        log(
            "task_ready",
            "npc=" .. tostring(Pending.npcID)
                .. " request=" .. tostring(Pending.requestID)
        )
    end
    return Pending
end

local function finishPendingRequest()
    local finished = Pending
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
            log(
                "llm_request_release_failed",
                "npc=" .. tostring(finished.npcID)
                    .. " request=" .. tostring(finished.requestID)
                    .. " reason=" .. tostring(
                        releaseReason or "rejected"
                    )
            )
        else
            log(
                "llm_request_released",
                "npc=" .. tostring(finished.npcID)
                    .. " request=" .. tostring(finished.requestID)
                    .. " reason=" .. tostring(
                        releaseReason or "released"
                    )
            )
        end
    end
    clearLLMRequestState(finished)
    if finished and Speech and Speech.ClearPending then
        Speech.ClearPending(finished.npcID, finished.requestID)
    end
    activateNextPending()
    return finished
end

function Integration.Submit(view, value, part)
    if not bridgeEnabled() then
        return false, "bridge_disabled"
    end
    if Pending or #PendingQueue > 0 then
        return false, "llm_request_pending"
    end
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

    local views = recipientViews(view, part)
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
        local headless = targetView.headless == true
            and targetView.hoomansLLM == true
        if targetView ~= currentView() and not headless then
            return false, "conversation_unavailable"
        end
        if not targetView.session
            or not targetView:isConversationInteractive()
        then
            return false, "conversation_busy"
        end
        item = queueItem(targetView, value)
        if not item then return false, "context_unavailable" end
        items[#items + 1] = item
    end
    if #items == 0 then return false, "conversation_unavailable" end
    local recipientCount = #items
    -- Build every packet before changing any session state. A multi-recipient
    -- send is therefore atomic if one context adapter cannot build its view.
    for _, queued in ipairs(items) do
        local reserved, reserveReason = reserveQueueItem(queued)
        if not reserved then
            for _, failedItem in ipairs(items) do
                clearLLMRequestState(failedItem)
            end
            return false, reserveReason
        end
    end
    for _, queued in ipairs(items) do
        prepareQueueItem(queued, value)
    end
    PendingQueue = items
    activateNextPending()
    log(
        "chat_submit",
        "recipients=" .. tostring(recipientCount)
            .. " first_npc=" .. tostring(Pending.npcID)
            .. " request=" .. tostring(Pending.requestID)
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
    log(
        "tool_calls_received",
        "npc=" .. tostring(npcID)
            .. " request=" .. tostring(packet and packet.request_id)
            .. " count=" .. tostring(#calls)
    )
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
        elseif name == "ask_name" and exposedTool(packet, name) then
            local requestTopic = PNC.Client
                and PNC.Client.RequestNPCKnowledgeTopic
            result.topicID = "identity_name"
            if requestTopic then
                local accepted, reason, disclosureRequestID = requestTopic(
                    npcID,
                    "identity_name"
                )
                result.accepted = accepted == true
                result.reason = reason or (result.accepted
                    and "submitted" or "rejected_by_game")
                result.disclosureRequestID = disclosureRequestID
            else
                result.reason = "identity_knowledge_client_unavailable"
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
        log(
            "tool_call_result",
            "npc=" .. tostring(npcID)
                .. " request=" .. tostring(packet and packet.request_id)
                .. " id=" .. tostring(callID)
                .. " name=" .. tostring(name)
                .. " reaction=" .. tostring(result.reaction or "")
                .. " accepted=" .. tostring(result.accepted == true)
                .. " reason=" .. tostring(result.reason or "")
        )
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
    finishPendingRequest()
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
    local response = cleanResponseText(arguments and arguments.response_text)
    local providerFailure = arguments and (
        arguments.provider_failure == true
        or arguments.providerFailure == true
        or arguments.context_eligible == false
        or arguments.contextEligible == false
    )
    if response ~= "" then
        return response, providerFailure == true
    end

    local calls = arguments and arguments.semantic_tool_calls
    local hasNameAction = false
    local hasSocialAction = false
    local hasOrderAction = false
    for _, call in ipairs(type(calls) == "table" and calls or {}) do
        local name = trim(call and call.name)
        if name == "ask_name" then
            hasNameAction = true
        elseif name == "social_react" then
            hasSocialAction = true
        elseif string.find(name, "^order_") == 1 then
            hasOrderAction = true
        end
    end
    if hasNameAction then return "Sure. Let me introduce myself.", false end
    if hasSocialAction then return "I hear you.", false end
    if hasOrderAction then return "All right.", false end
    local failure = trim(arguments and arguments.error)
    if failure == "" and actionAccepted then
        return "All right.", false
    end
    if failure == "" and actionAttempted then
        return "I hear you.", false
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
        finishPendingRequest()
        return {
            accepted = message ~= nil,
            reason = message and "conversation_closed" or "conversation_unavailable",
            presentation = message and "nameplate" or nil,
            message_id = message and message.messageID or nil,
        }
    end

    local semanticResults = applySemanticTools(Pending.packet, arguments, Pending.npcID, view.session)
    local response = cleanResponseText(arguments.response_text)
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
        finishPendingRequest()
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
    finishPendingRequest()
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
        finishPendingRequest()
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
