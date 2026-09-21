-- Provider-response cleanup and deterministic tool/failure acknowledgements.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolReplies = PNC.Conversation and PNC.Conversation.ToolReplies
local Fallback = Internal.ResponseFallback or {}
Internal.ResponseFallback = Fallback

function Fallback.DedicatedToolReply(packet, semanticResults)
    if not ToolReplies or not ToolReplies.Build then return nil end
    local context = packet and packet.conversation_context or {}
    return ToolReplies.Build(semanticResults, context)
end

function Fallback.OrFailure(
    arguments,
    actionAccepted,
    actionAttempted,
    semanticResults,
    packet,
    forceToolReply
)
    local response = Runtime.CleanResponseText(arguments and arguments.response_text)
    local providerFailure = arguments and (
        arguments.provider_failure == true
        or arguments.providerFailure == true
        or arguments.context_eligible == false
        or arguments.contextEligible == false
    )
    if forceToolReply then
        local dedicated = Fallback.DedicatedToolReply(packet, semanticResults)
        if dedicated and dedicated ~= "" then
            return dedicated, providerFailure == true
        end
    end
    if providerFailure then
        local dedicated = Fallback.DedicatedToolReply(packet, semanticResults)
        if dedicated and dedicated ~= "" then
            return dedicated, true
        end
    end
    if response ~= "" then
        return response, providerFailure == true
    end

    local dedicated = Fallback.DedicatedToolReply(packet, semanticResults)
    if dedicated and dedicated ~= "" then
        return dedicated, providerFailure == true
    end

    local calls = arguments and arguments.semantic_tool_calls
    local hasNameAction = false
    local hasSocialAction = false
    local hasOrderAction = false
    for _, call in ipairs(type(calls) == "table" and calls or {}) do
        local name = Runtime.Trim(call and call.name)
        if name == "ask_name" then
            hasNameAction = true
        elseif name == "social_react" then
            hasSocialAction = true
        elseif string.find(name, "^order_") == 1 then
            hasOrderAction = true
        end
    end
    if hasNameAction then
        local fallback = "I'll tell you my name once we've established some trust. What's your name?"
        local translation = PNC.Translation
        if translation and type(translation.TrFormat) == "function" then
            return translation.TrFormat(
                "UI_PNC_Conversation_Semantic_QuestionIdentity",
                fallback
            ), false
        end
        return fallback, false
    end
    if hasSocialAction then return "I hear you.", false end
    if hasOrderAction then return "All right.", false end
    local failure = Runtime.Trim(arguments and arguments.error)
    if failure == "" and actionAccepted then
        return "All right.", false
    end
    if failure == "" and actionAttempted then
        return "I hear you.", false
    end
    if failure == "" then
        local finishReason = Runtime.Trim(arguments and arguments.finish_reason)
        local toolCount = tonumber(arguments and arguments.tool_call_count) or 0
        failure = finishReason ~= ""
            and "provider returned an empty response (finish_reason="
                .. finishReason .. ", tool_calls=" .. tostring(toolCount) .. ")"
            or "provider returned an empty response"
    end
    if failure ~= "" then
        return "I cannot answer right now. ("
            .. string.sub(failure, 1, 420) .. ")", true
    end
    return "I cannot answer right now.", true
end

return Fallback
