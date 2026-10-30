-- Close delivery and working-session cleanup. No start/heartbeat policy.
local DialogueSession = require "PNC/Semantics/PNC_SemanticDialogueSession"
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal
local Safety = H.Safety
local Farewell = H.Farewell
local Scene = H.Scene
local isNetworkClient = H.IsNetworkClient
local send = H.Send

local function conversationTopicMask(view)
    local session = view and view.session
    local events = PNC.Conversation and PNC.Conversation.Memory
        and PNC.Conversation.Memory.Events or nil
    if not events or type(events.GetConversationTopicMask) ~= "function" then
        require "PNC/Conversation/Memory/PNC_ConversationMemory"
    end
    -- Close can happen before any semantic or provider request loads the
    -- definitions. Require this lightweight catalog here so visible session
    -- messages are still classified and transferred to today's memory.
    require "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"
    events = PNC.Conversation and PNC.Conversation.Memory
        and PNC.Conversation.Memory.Events or nil
    if events and type(events.GetConversationTopicMask) == "function" then
        local mask = events.GetConversationTopicMask(session, 64)
        return tonumber(mask)
    end
    local mask = session and tonumber(session.conversationTopicMask) or nil
    if not mask or mask ~= mask or mask == math.huge or mask == -math.huge then
        return nil
    end
    mask = math.floor(mask)
    return mask > 0 and mask or nil
end

local function clearWorkingContext(view, spec, preserveSafetyFeedback)
    local session = view and view.session or nil
    local historyPart = view and view.historyPart or nil
    local preservedMessages = {}
    local namespace = session and session.namespace
        or spec and spec.namespace or "ProjectHoomans"
    local npcID = session and session.npcID
        or spec and spec.npcID or "unknown"
    local characterUUID = session and session.characterUUID
        or spec and spec.characterUUID or "unbound"
    local coreConversation = PsychopatzCore
        and PsychopatzCore.Conversation or nil
    local history = coreConversation and coreConversation.History or nil

    if history and type(history.Clear) == "function" then
        history.Clear(namespace, npcID, characterUUID)
    end
    if session then
        session.closed = true
        session.conversationMemoryClosed = true
        DialogueSession.ClearWorkingState(session)
        session.conversationTopicMask = nil
        session.queue = {}
        session.busy = false
        session.llmPending = false
    end
    if historyPart then
        local messagesCleared = false
        local typingCleared = false
        if preserveSafetyFeedback == true
            and type(historyPart.messages) == "table"
        then
            for _, message in ipairs(historyPart.messages) do
                local source = message and message.source
                if type(source) == "table"
                    and source.eventType == "conversation_safety"
                then
                    preservedMessages[#preservedMessages + 1] = message
                end
            end
        end
        -- Optional addon-owned widget callbacks may fail independently of
        -- authoritative scene close; preserve the fallback presentation state.
        if type(historyPart.setMessages) == "function" then
            messagesCleared = pcall(
                historyPart.setMessages,
                historyPart,
                preservedMessages
            )
        end
        if not messagesCleared then
            historyPart.messages = preservedMessages
        end
        if type(historyPart.setTyping) == "function" then
            typingCleared = pcall(
                historyPart.setTyping,
                historyPart,
                nil
            )
        end
        if not typingCleared then
            historyPart.typingSpeaker = nil
        end
    end
    DialogueSession.ReleaseView(view)
end

local function presentSafetyFeedback(spec, state, reason)
    if tostring(reason or "") ~= "danger" then return false end
    if state and state.guardThreats == false then return false end
    if not Safety.GuardsThreats(spec) then return false end
    local presentation = PNC.SemanticSpeechPresentation
    if not presentation then
        local ok, loaded = pcall(
            require,
            "PNC/Conversation/PNC_SemanticSpeechPresentation"
        )
        presentation = ok and loaded or PNC.SemanticSpeechPresentation
    end
    return presentation
        and type(presentation.EnqueueConversationSafety) == "function"
        and presentation.EnqueueConversationSafety(spec, state, reason)
        or false
end

function Lifecycle.Finish(view, spec, state, reason)
    presentSafetyFeedback(spec, state, reason)
    if Farewell and type(Farewell.Schedule) == "function" then
        Farewell.Schedule(spec, state, reason)
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat({
            "Conversation closed",
            "npc=" .. tostring(state and state.npcID
                or spec and spec.npcID or "unknown"),
            "token=" .. tostring(state and state.token or "none"),
            "guardThreats=" .. tostring(not state
                or state.guardThreats ~= false),
            "reason=" .. tostring(reason or "closed"),
        }, " "))
    end
    local topicMask = conversationTopicMask(view)
    if state then
        if isNetworkClient() then
            send(Scene.CMD_END, state, reason, {
                llmRequestID = state and state.llmRequestID or nil,
                memoryTopicMask = topicMask,
            })
        else
            local _, zombie, record = H.Safety.ResolveActors(spec)
            if Scene and Scene.End then
                Scene.End(
                    record,
                    zombie,
                    state.token,
                    "conversation_" .. tostring(reason or "closed"),
                    {
                        llmRequestID = state and state.llmRequestID or nil,
                        memoryTopicMask = topicMask,
                        player = spec and spec.context
                            and spec.context.player,
                    }
                )
            end
        end
    end
    clearWorkingContext(
        view,
        spec,
        tostring(reason or "") == "danger"
    )
end


return Lifecycle
