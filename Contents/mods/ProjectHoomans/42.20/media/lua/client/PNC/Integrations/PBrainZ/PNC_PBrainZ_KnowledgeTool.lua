-- LLM knowledge-disclosure and identity tool handlers.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolFlow = Internal.ToolFlow
local Handlers = Internal.ToolHandlers

Handlers.disclose_knowledge = function(result, packet, npcID, arguments)
    if not ToolFlow.Exposed(packet, "disclose_knowledge") then
        result.reason = "tool_not_exposed"
        return
    end
    local topicID = Runtime.Trim(arguments.topic_id)
    result.topicID = topicID
    local request = PNC.Client and PNC.Client.RequestNPCKnowledgeTopic
    if request and topicID ~= "" then
        local accepted, reason, disclosureRequestID = request(
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
end

Handlers.ask_name = function(result, packet, npcID)
    if not ToolFlow.Exposed(packet, "ask_name") then
        result.reason = "tool_not_exposed"
        return
    end
    result.topicID = "identity_name"
    local request = PNC.Client and PNC.Client.RequestNPCKnowledgeTopic
    if request then
        local accepted, reason, disclosureRequestID = request(
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
end

return Handlers
