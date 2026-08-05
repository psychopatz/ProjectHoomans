-- Build 42.20 adapter for the identity-disclosure conversation action.
-- Identity knowledge is intentionally separate from declarative topic blocks
-- because it invokes the authoritative knowledge service.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local IdentityChoice = PNC.Conversation.IdentityChoice or {}
PNC.Conversation.IdentityChoice = IdentityChoice

function IdentityChoice.Request(npcID)
    if PNC.Client and PNC.Client.RequestNPCKnowledgeTopic then
        return PNC.Client.RequestNPCKnowledgeTopic(npcID, "identity_name")
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
            projection.state = "loading"
            IdentityChoice.Request(npcID)
        end,
    }
end

-- Compatibility entry point for integrations that used the original adapter.
PNC.Conversation.RequestKnowledgeTopic = function(npcID, topicID)
    if topicID ~= nil and topicID ~= "identity_name" then return false end
    return IdentityChoice.Request(npcID)
end

return IdentityChoice
