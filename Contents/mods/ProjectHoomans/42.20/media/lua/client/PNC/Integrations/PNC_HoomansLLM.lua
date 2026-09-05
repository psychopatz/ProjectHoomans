-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Conversation/PsychopatzNameParts"
require "PNC/Conversation/PNC_ConversationLLMTools"
require "PNC/Conversation/PNC_ConversationToolReplies"
require "PNC/Integrations/PNC_HoomansLLMContext"
require "PNC/Integrations/PNC_ConversationMemorySync"
require "PNC/UI/Nameplates/PNC_NameplateSpeech"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local NameParts = PsychopatzCore.Conversation.NameParts
local Layout = PsychopatzCore.Conversation.Layout
local Context = PNC.HoomansLLM.Context
local LLMTools = PNC.ConversationLLMTools
local ToolReplies = PNC.Conversation and PNC.Conversation.ToolReplies
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
local AmbientPending = nil
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
    local lowered = string.lower(value)
    local scaffoldStart = string.find(lowered, "^%s*instruction%s*:")
        or string.find(lowered, "\n%s*instruction%s*:")
        or string.find(lowered, "^%s*response%s*$")
        or string.find(lowered, "\n%s*response%s*$")
        or string.find(lowered, "^%s*answer%s*:")
        or string.find(lowered, "\n%s*answer%s*:")
        or string.find(lowered, "^%s*analysis%s*:")
        or string.find(lowered, "\n%s*analysis%s*:")
        or string.find(lowered, "^%s*self[- ]correction%s*:")
        or string.find(lowered, "\n%s*self[- ]correction%s*:")
        or string.find(lowered, "^%s*final%s+check%s*:")
        or string.find(lowered, "\n%s*final%s+check%s*:")
        or string.find(lowered, "^%s*new%s+attempt%s*:")
        or string.find(lowered, "\n%s*new%s+attempt%s*:")
    if scaffoldStart then
        value = trim(string.sub(value, 1, scaffoldStart - 1))
        if value == "" then return "" end
        return value
    end
    local providerMeta = string.find(lowered, "self[- ]correction%s+check")
        or string.find(lowered, "last turn['’]s instructions")
        or string.find(lowered, "prompt for the final response")
        or string.find(lowered, "player['’]s last message%s*:")
        or string.find(lowered, "required action%s*:")
    if providerMeta then return "" end
    return trim(value)
end

local function replaceAmbientIdentity(text, fullName, firstName, surname)
    local names = { fullName, surname }
    local replacement = tostring(firstName or "")
    if replacement == "" then return text end
    for _, name in ipairs(names) do
        name = trim(name)
        if name ~= "" and name ~= replacement then
            -- Escape Lua pattern punctuation so names such as "O'Neil" and
            -- hyphenated surnames are treated as literal text.
            local pattern = string.gsub(name, "([^%w])", "%%%1")
            text = string.gsub(text, pattern, replacement)
        end
    end
    return text
end

local function enforceAmbientNamePolicy(text, packet)
    local context = packet and packet.conversation_context or {}
    text = replaceAmbientIdentity(
        text,
        context.player_full_name,
        context.player_first_name,
        context.player_surname
    )
    return replaceAmbientIdentity(
        text,
        context.victim_full_name,
        context.victim_first_name,
        context.victim_surname
    )
end

local function logText(value)
    value = trim(value)
    value = string.gsub(value, "[\r\n]+", " ")
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

local function buildAmbientPacket(item, requestID)
    local source = item and item.context or {}
    local npcID = tostring(item and item.speakerID or source.npcID or "")
    local playerID = tostring(item and item.playerUUID
        or source.playerUUID or "ambient-player")
    local npc = NameParts.Split(
        source.speakerFullName
            or item and item.speakerName
            or source.name or npcID or "the survivor",
        source.speakerFirstName or source.firstName,
        source.speakerSurname or source.surname
    )
    local player = NameParts.Split(
        source.playerFullName or source.playerName
            or source.player or "the player",
        source.playerFirstName,
        source.playerSurname
    )
    local npcFullName = npc.fullName or "the survivor"
    local npcFirstName = npc.firstName or npcFullName
    local npcSurname = npc.surname or ""
    local playerFullName = player.fullName or "the player"
    local playerFirstName = player.firstName or playerFullName
    local playerSurname = player.surname or ""
    local victimID = tostring(source.victimNPCID or "")
    local victim = NameParts.Split(
        source.victimFullName or source.victimName
            or source.victim or "your teammate",
        source.victimFirstName,
        source.victimSurname or source.victimLastName
    )
    local victimFullName = victim.fullName or "your teammate"
    local victimFirstName = victim.firstName or victimFullName
    local worldUUID = Message.GetSaveID()
    local sessionID = "pnc_ambient_" .. tostring(requestID)
    local eventType = tostring(source.eventType or item and item.family
        or "ambient_social")
    local playerMessage = tostring(source.playerMessage or "")
    local prompt
    if eventType == "player_spoke" and playerMessage ~= "" then
        prompt = (
            "Write one brief in-character reaction because the player just "
            .. "said: \"" .. playerMessage .. "\". Respond naturally to "
            .. "what they said. Use only the player's first name if you "
            .. "address them (" .. playerFirstName .. "). Do not mention "
            .. "being an AI, prompts, or game systems. Keep it under one "
            .. "sentence."
        )
    elseif eventType == "witnessed_teammate_hurt" then
        prompt = (
            "Write one brief in-character reaction because you witnessed "
            .. "your teammate take damage from a zombie. If you address "
            .. "the teammate, use only their first name ("
            .. victimFirstName .. "). Do not use their surname or full name. "
            .. "Do not mention being an AI, prompts, or game systems. "
            .. "Keep it under one sentence."
        )
    else
        prompt = (
            "Write one brief in-character reaction because you witnessed "
            .. "the player kill a zombie. Do not mention being an AI, prompts, "
            .. "or game systems. If you address the player, use only their first "
            .. "name; never repeat their surname or full name. Keep it under one "
            .. "sentence."
        )
    end
    local context = {
        world_uuid = worldUUID,
        player_uuid = playerID,
        npc_uuid = npcID,
        session_id = sessionID,
        npc_name = npcFullName,
        player_name = playerFirstName,
        npc_full_name = npcFullName,
        npc_first_name = npcFirstName,
        npc_surname = npcSurname,
        player_full_name = playerFullName,
        player_first_name = playerFirstName,
        player_surname = playerSurname,
        victim_npc_id = victimID ~= "" and victimID or nil,
        victim_name = victimFirstName,
        victim_full_name = victimFullName,
        victim_first_name = victimFirstName,
        victim_surname = victim.surname or "",
        player_message = playerMessage ~= "" and playerMessage or nil,
        message = prompt,
        character_card = {},
        relationship_snapshot = {
            state = source.relationshipState,
            category = source.relationshipState,
            npcType = source.socialRole or source.npcType,
            relationshipTier = source.relationshipTier,
        },
        relationship_capabilities = {
            server_authoritative = true,
            available_reactions = {},
        },
        current_state = {},
        scene = {
            current_speaker_id = npcID,
            addressed_targets = { playerID },
        },
        recent_conversation = {},
        available_tools = {},
        voice_binding = source.voiceBinding or source.voice_binding,
        metadata = {
            source = "project-hoomans",
            mode = "ambient_social",
            family = tostring(item and item.family or "ambient"),
            event_type = eventType,
            victim_npc_id = victimID ~= "" and victimID or nil,
            victim_first_name = victimFirstName,
            player_message = playerMessage ~= "" and playerMessage or nil,
            social_role = source.socialRole or source.npcType,
            relationship_state = source.relationshipState,
            relationship_tier = source.relationshipTier,
            llm_instruction = "Return dialogue only; no actions or analysis.",
        },
    }
    return {
        status = "pending",
        request_id = requestID,
        npc_id = npcID,
        world_uuid = worldUUID,
        player_uuid = playerID,
        session_id = sessionID,
        npc_name = npcFullName,
        player_name = playerFirstName,
        victim_name = victimFirstName,
        model = "default",
        conversation_context = context,
    }
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

-- Ambient requests share pollChat/deliverChat with interactive conversation,
-- but have no gameplay tools and never reserve an authoritative conversation
-- token.  They are best-effort: the Core queue always has a deterministic
-- fallback if this client-only provider is unavailable or too slow.
function Integration.SubmitAmbientFlavor(item, callback)
    if not bridgeEnabled() then return false, "bridge_disabled" end
    if Pending or #PendingQueue > 0 or AmbientPending then
        return false, "llm_request_pending"
    end
    if type(item) ~= "table" or type(callback) ~= "function" then
        return false, "ambient_request_invalid"
    end
    serial = serial + 1
    local requestID = "pnc_ambient_llm_" .. tostring(now()) .. "_"
        .. tostring(serial)
    AmbientPending = {
        requestID = requestID,
        eventID = tostring(item.eventID or ""),
        npcID = tostring(item.speakerID or ""),
        packet = buildAmbientPacket(item, requestID),
        callback = callback,
        claimed = false,
    }
    log(
        "ambient_request_queued",
        "npc=" .. AmbientPending.npcID .. " event=" .. AmbientPending.eventID
            .. " request=" .. requestID
    )
    return true, requestID
end

function Integration.CancelAmbientFlavor(eventID)
    if AmbientPending and tostring(AmbientPending.eventID or "")
        == tostring(eventID or "")
    then
        log("ambient_request_cancelled", "event=" .. tostring(eventID))
        AmbientPending = nil
        return true
    end
    return false
end

function Integration.Poll()
    if not Pending then
        if not AmbientPending or AmbientPending.claimed then
            return { status = "idle" }
        end
        AmbientPending.claimed = true
        log(
            "ambient_task_polled",
            "npc=" .. tostring(AmbientPending.npcID)
                .. " request=" .. tostring(AmbientPending.requestID)
        )
        return AmbientPending.packet
    end
    if Pending.claimed then return { status = "idle" } end
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
            local subtype = trim(callArguments.subtype)
            if LLMTools and LLMTools.NormalizeReaction then
                kind = LLMTools.NormalizeReaction(kind) or kind
            end
            if LLMTools and LLMTools.NormalizeSubtypeForReaction then
                subtype = LLMTools.NormalizeSubtypeForReaction(subtype, kind)
            end
            if execute then
                local accepted
                local reason
                local authoritativeResult
                accepted, reason, authoritativeResult = execute(
                    npcID,
                    kind,
                    intensity,
                    {
                        origin = "llm_tool",
                        requestID = packet and packet.request_id,
                        callID = callID,
                        token = packet and packet.conversation_context
                            and packet.conversation_context.conversation_token,
                        subtype = subtype,
                    }
                )
                result.accepted = accepted == true
                result.reason = reason
                result.reaction = kind
                result.intensity = intensity
                result.subtype = subtype
                result.explicit = subtype == "sexual_advance"
                result.authoritative = type(authoritativeResult) == "table"
                if result.authoritative then
                    result.relationship = authoritativeResult.relationship
                    result.relationshipBefore =
                        authoritativeResult.relationshipBefore
                    result.relationshipAfter = authoritativeResult.relationshipAfter
                    result.relationshipDelta = authoritativeResult.relationshipDelta
                    result.cooldownUntil = authoritativeResult.cooldownUntil
                    result.eventID = authoritativeResult.eventID
                    result.memoryID = authoritativeResult.memoryID
                    result.subtype = authoritativeResult.subtype or result.subtype
                    result.explicit = authoritativeResult.explicit
                    result.replyContext = authoritativeResult.replyContext
                end
            else
                result.reason = "social_reaction_client_unavailable"
                result.reaction = kind
                result.intensity = intensity
                result.subtype = subtype
                result.explicit = subtype == "sexual_advance"
            end
            if not result.replyContext then
                result.replyContext = {
                    outcome = result.accepted == true and "accepted" or "rejected",
                    reaction = result.reaction,
                    subtype = result.subtype,
                    reason = result.reason,
                    authoritative = result.authoritative == true,
                }
            end
        elseif name == "disclose_knowledge" and exposedTool(packet, name) then
            local requestTopic = PNC.Client
                and PNC.Client.RequestNPCKnowledgeTopic
            local topicID = trim(callArguments.topic_id)
            result.topicID = topicID
            if requestTopic and topicID ~= "" then
                local accepted, reason, disclosureRequestID = requestTopic(
                    npcID,
                    topicID,
                    {
                        conversationToken = packet
                            and packet.conversation_context
                            and packet.conversation_context.conversation_token,
                        origin = "llm_tool",
                    }
                )
                result.accepted = accepted == true
                result.reason = reason or (result.accepted
                    and "submitted" or "rejected_by_game")
                result.disclosureRequestID = disclosureRequestID
                result.authoritative = false
                result.replyContext = {
                    outcome = result.accepted and "knowledge_request_submitted"
                        or "knowledge_request_rejected",
                    topicID = topicID,
                    reason = result.reason,
                }
            else
                result.reason = topicID == "" and "topic_required"
                    or "knowledge_client_unavailable"
            end
        elseif name == "ask_name" and exposedTool(packet, name) then
            local requestTopic = PNC.Client
                and PNC.Client.RequestNPCKnowledgeTopic
            result.topicID = "identity_name"
            if requestTopic then
                local accepted, reason, disclosureRequestID = requestTopic(
                    npcID,
                    "identity_name",
                    {
                        conversationToken = packet
                            and packet.conversation_context
                            and packet.conversation_context.conversation_token,
                        origin = "llm_tool",
                    }
                )
                result.accepted = accepted == true
                result.reason = reason or (result.accepted
                    and "submitted" or "rejected_by_game")
                result.disclosureRequestID = disclosureRequestID
                result.authoritative = false
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
                result.commandID = commandID
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

local function dedicatedToolReply(packet, semanticResults)
    if not ToolReplies or not ToolReplies.Build then return nil end
    local context = packet and packet.conversation_context or {}
    return ToolReplies.Build(semanticResults, context)
end

local function responseOrFailure(
    arguments,
    actionAccepted,
    actionAttempted,
    semanticResults,
    packet,
    forceToolReply
)
    local response = cleanResponseText(arguments and arguments.response_text)
    local providerFailure = arguments and (
        arguments.provider_failure == true
        or arguments.providerFailure == true
        or arguments.context_eligible == false
        or arguments.contextEligible == false
    )
    if forceToolReply then
        local dedicated = dedicatedToolReply(packet, semanticResults)
        if dedicated and dedicated ~= "" then
            return dedicated, providerFailure == true
        end
    end
    if response ~= "" then
        return response, providerFailure == true
    end

    local dedicated = dedicatedToolReply(packet, semanticResults)
    if dedicated and dedicated ~= "" then
        return dedicated, providerFailure == true
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
    if AmbientPending and AmbientPending.requestID == requestID
        and AmbientPending.claimed
    then
        local pending = AmbientPending
        AmbientPending = nil
        local response = cleanResponseText(arguments.response_text)
        response = enforceAmbientNamePolicy(response, pending.packet)
        if response ~= "" then
            pending.callback(response, {
                ttsManaged = arguments.tts_managed == true,
            })
            log(
                "ambient_response_delivered",
                "npc=" .. tostring(pending.npcID)
                    .. " event=" .. tostring(pending.eventID)
                    .. " chars=" .. tostring(#response)
            )
            return { accepted = true, presentation = "social_flavor" }
        end
        log(
            "ambient_response_empty",
            "npc=" .. tostring(pending.npcID)
                .. " event=" .. tostring(pending.eventID)
        )
        return { accepted = false, reason = "ambient_response_empty" }
    end
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
            actionAttempted,
            semanticResults,
            Pending.packet,
            tostring(arguments.presentation_reason or "") == "tool_ack"
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
    local forceToolReply = tostring(arguments.presentation_reason or "")
        == "tool_ack"
    local response = forceToolReply and ""
        or cleanResponseText(arguments.response_text)
    local providerFailure = false
    if response == "" then
        local actionAccepted = false
        for _, result in ipairs(semanticResults) do
            if result.accepted == true then actionAccepted = true break end
        end
        response, providerFailure = responseOrFailure(
            arguments,
            actionAccepted,
            #semanticResults > 0,
            semanticResults,
            Pending.packet,
            forceToolReply
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
