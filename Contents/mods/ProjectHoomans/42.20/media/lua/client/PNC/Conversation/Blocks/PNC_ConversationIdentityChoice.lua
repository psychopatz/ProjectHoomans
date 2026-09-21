-- Build 42.20 adapter for the semantic identity-exchange conversation action.
-- Asking for a name starts the semantic prompt; verified claims reach the
-- authoritative knowledge service through the semantic input lifecycle.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local IdentityChoice = PNC.Conversation.IdentityChoice or {}
PNC.Conversation.IdentityChoice = IdentityChoice

local function currentConversationView(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and view.spec
        and tostring(view.spec.npcID or "") == tostring(npcID or "")
    then return view end
    return nil
end

function IdentityChoice.Request(npcID)
    local view = currentConversationView(npcID)
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    if not view then return false, "conversation_unavailable" end
    if not input or type(input.Submit) ~= "function" then
        return false, "semantic_dialogue_input_unavailable"
    end
    return input.Submit(view, "what is your name")
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
            -- This action starts dialogue, not a knowledge request. Keep the
            -- identity unknown until a truthful player-name claim is verified.
            projection.state = "unknown"
            projection.requestState = "prompting"
            projection.knowledgePending = false
            projection.canAskName = false
            local accepted = IdentityChoice.Request(npcID)
            if accepted ~= true then
                projection.requestState = "error"
                projection.knowledgePending = false
                projection.canAskName = true
            else
                projection.requestState = "prompted"
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
