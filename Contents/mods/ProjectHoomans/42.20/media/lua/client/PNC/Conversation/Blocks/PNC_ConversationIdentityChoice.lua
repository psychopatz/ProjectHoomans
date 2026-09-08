-- Build 42.20 adapter for the identity-disclosure conversation action.
-- Identity knowledge is intentionally separate from declarative topic blocks
-- because it invokes the authoritative knowledge service.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local IdentityChoice = PNC.Conversation.IdentityChoice or {}
PNC.Conversation.IdentityChoice = IdentityChoice

local function currentConversationToken(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local context = view and view.spec and view.spec.context or nil
    local state = context and context.conversationLifecycleState or nil
    if context and tostring(view.spec.npcID or "") == tostring(npcID or "")
        and state and state.token
    then return state.token end
    return nil
end

function IdentityChoice.Request(npcID)
    if PNC.Client and PNC.Client.RequestNPCKnowledgeTopic then
        return PNC.Client.RequestNPCKnowledgeTopic(npcID, "identity_name", {
            conversationToken = currentConversationToken(npcID),
            origin = "conversation",
        })
    end
    return false
end

function IdentityChoice.Build(npcID, projection, identityArguments)
    if type(projection) ~= "table" or projection.canAskName ~= true then
        return nil
    end
    return {
        id = "ask_name",
        text = {
            key = "choice.ask_name",
            domain = "pnc.system.shared.categories",
            args = identityArguments,
        },
        action = function()
            -- Keep the identity projection unknown while the disclosure is
            -- in flight. Only the request lifecycle is loading; the social
            -- category menu must remain usable.
            projection.state = "unknown"
            projection.requestState = "loading"
            projection.knowledgePending = true
            projection.canAskName = false
            local accepted = IdentityChoice.Request(npcID)
            if accepted ~= true then
                projection.requestState = "error"
                projection.knowledgePending = false
                projection.canAskName = true
            end
        end,
    }
end

-- Compatibility entry point for integrations that used the original adapter.
PNC.Conversation.RequestKnowledgeTopic = function(npcID, topicID)
    if topicID ~= nil and topicID ~= "identity_name" then return false end
    return IdentityChoice.Request(npcID)
end

return IdentityChoice
