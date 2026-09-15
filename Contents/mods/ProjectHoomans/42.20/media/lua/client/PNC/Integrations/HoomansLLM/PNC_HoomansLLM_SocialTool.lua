-- LLM social-reaction tool handler.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolFlow = Internal.ToolFlow
local LLMTools = PNC.ConversationLLMTools
local Handlers = Internal.ToolHandlers

Handlers.social_react = function(result, packet, npcID, arguments, callID)
    if not ToolFlow.Exposed(packet, "social_react") then
        result.reason = "tool_not_exposed"
        return
    end
    local execute = PNC.Client and PNC.Client.ExecuteLLMSocialReaction
    local kind = Runtime.Trim(arguments.kind)
    if kind == "" then kind = Runtime.Trim(arguments.reaction) end
    local intensity = Runtime.Trim(arguments.intensity)
    local subtype = Runtime.Trim(arguments.subtype)
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
            result.relationshipBefore = authoritativeResult.relationshipBefore
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
end

return Handlers.social_react
