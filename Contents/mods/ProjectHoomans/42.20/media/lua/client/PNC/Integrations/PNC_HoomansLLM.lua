-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Layout = PsychopatzCore.Conversation.Layout
local Text = PsychopatzCore.Conversation.Text

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
local MAX_HISTORY_MESSAGES = 24
local MAX_HISTORY_TEXT = 1200
local Pending = nil
local serial = 0

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
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

local function messageText(message)
    if not message then return "" end
    local payload = message.payload or message
    return trim(Text.Resolve(payload))
end

local function buildPacket(view, requestID)
    local context = view.spec and view.spec.context or {}
    local npcName = trim(context.npcName or view.spec.npcID or "the survivor")
    local playerName = trim(context.playerName or "the player")
    local relationship = trim(
        context.conversationRelationshipID
            or context.relationshipID
            or "unknown"
    )
    local role = trim(context.factionRole or context.npcType or "survivor")
    local system = table.concat({
        "You are " .. npcName .. ", an NPC in Project Hoomans.",
        "Stay in character as a " .. role .. " survivor.",
        "Answer the player naturally and concisely using only the supplied conversation context.",
        "Do not claim to have performed game actions; the player can use the response choices for actions.",
        "The player's name is " .. playerName .. ".",
        "Your relationship with the player is " .. relationship .. ".",
    }, " ")
    local messages = {
        { role = "system", content = system },
    }
    local history = view.historyPart and view.historyPart.messages or {}
    local first = math.max(1, #history - MAX_HISTORY_MESSAGES + 1)
    local index
    for index = first, #history do
        local message = history[index]
        local content = messageText(message)
        if content ~= "" then
            content = string.sub(content, 1, MAX_HISTORY_TEXT)
            messages[#messages + 1] = {
                role = message.speaker == "player" and "user" or "assistant",
                content = content,
            }
        end
    end
    return {
        status = "pending",
        request_id = requestID,
        npc_id = tostring(view.spec and view.spec.npcID or "unknown"),
        npc_name = npcName,
        player_name = playerName,
        model = "default",
        messages = messages,
        metadata = {
            npc_name = npcName,
            player_name = playerName,
            relationship = relationship,
            conversation_time = tostring(context.conversationTimeID or ""),
        },
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
        packet = buildPacket(view, requestID),
        claimed = false,
    }
    return true
end

function Integration.Poll()
    if not Pending or Pending.claimed then return { status = "idle" } end
    Pending.claimed = true
    return Pending.packet
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

    local response = trim(arguments.response_text)
    if response == "" then
        local failure = trim(arguments.error)
        response = failure ~= ""
            and "I cannot answer right now. (" .. string.sub(failure, 1, 420) .. ")"
            or "I cannot answer right now."
    end
    response = string.sub(response, 1, 3900)
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
