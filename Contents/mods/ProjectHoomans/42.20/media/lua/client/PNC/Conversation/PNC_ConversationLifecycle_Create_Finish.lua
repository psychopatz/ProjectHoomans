-- Client-side conversation lifecycle finish provider.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Lifecycle = PNC.Conversation.Lifecycle or {}
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal or {}
local currentTime = H.CurrentTime
local isNetworkClient = H.IsNetworkClient
local send = H.Send
local presentSafetyFeedback = H.PresentSafetyFeedback
local conversationTopicMask = H.ConversationTopicMask
local clearWorkingContext = H.ClearWorkingContext
local Farewell = H.Farewell
local Scene = H.Scene

local function finish(view, spec, state, reason)
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

H.CreateFinish = finish

return Lifecycle
