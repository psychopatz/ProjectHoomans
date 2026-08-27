-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PNC/Integrations/PNC_HoomansLLMContext"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Layout = PsychopatzCore.Conversation.Layout
local Context = PNC.HoomansLLM.Context

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

local MAX_INPUT_LENGTH = 1024
local MAX_LOG_TEXT = 900
local Pending = nil
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
    return {
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
end

function Integration.Submit(view, value)
    if not bridgeEnabled() then
        return false, "bridge_disabled"
    end
    if Pending then return false, "llm_request_pending" end
    if not view or view ~= currentView() or not view.session then
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
    session:append("player", value)
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
    return false
end

local function applySemanticTools(packet, arguments, npcID, session)
    local calls = arguments and arguments.semantic_tool_calls
    local results = {}
    if type(calls) ~= "table" then return results end
    for _, call in ipairs(calls) do
        local name = trim(call and call.name)
        local callArguments = call and type(call.arguments) == "table"
            and call.arguments or {}
        local result = { name = name, accepted = false }
        if name == "social_react" and exposedTool(packet, name) then
            -- There is no generic client-side relationship mutation API. Keep
            -- this as an observable intent until a specific SocialEvent command
            -- is registered by the authoritative gameplay layer.
            result.reason = "social_event_boundary_unavailable"
        elseif string.find(name, "^order_") == 1 and exposedTool(packet, name) then
            local commandID = trim(callArguments.command_id)
            local definition = PNC.CompanionCommands
                and PNC.CompanionCommands.Get(commandID) or nil
            local execute = PNC.Client and PNC.Client.ExecuteCompanionCommand
            if definition and execute then
                result.accepted = execute(commandID, npcID, "conversation", nil) == true
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
    return results
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
        Pending = nil
        return { accepted = false, reason = "conversation_closed" }
    end

    local semanticResults = applySemanticTools(Pending.packet, arguments, Pending.npcID, view.session)
    local response = trim(arguments.response_text)
    if response == "" then
        local failure = trim(arguments.error)
        local actionAccepted = false
        for _, result in ipairs(semanticResults) do
            if result.accepted == true then actionAccepted = true break end
        end
        response = failure ~= ""
            and "I cannot answer right now. (" .. string.sub(failure, 1, 420) .. ")"
            or actionAccepted and "I will take care of that."
            or "I cannot answer right now."
    end
    response = string.sub(response, 1, 3900)
    log(
        "response_deliver",
        "npc=" .. tostring(Pending.npcID)
            .. " request=" .. requestID
            .. " chars=" .. tostring(#response)
            .. " response=" .. logText(response)
    )
    local session = view.session
    session.queue = {}
    session.llmPending = nil
    session.busy = true
    session.pendingChoices = Pending.packet and session.pendingChoices or {}
    session:queueMessage("npc", { fallback = response })
    Pending = nil
    return { accepted = true }
end

function Integration.GetPending()
    return Pending
end

return Integration
