-- LLM knowledge-disclosure and identity tool handlers.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local ToolFlow = Internal.ToolFlow
local Handlers = Internal.ToolHandlers

local function identityQuestionResponse(packet, npcID)
    local dialogueInput = PNC.Semantics
        and PNC.Semantics.DialogueInput or nil
    local dialogueInternal = dialogueInput and dialogueInput.Internal or nil
    local context = packet and packet.conversation_context or {}
    local state
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and view.spec
        and tostring(view.spec.npcID or "") == tostring(npcID or "")
    then
        if dialogueInternal
            and type(dialogueInternal.ShallowContext) == "function"
        then
            context = dialogueInternal.ShallowContext(view) or context
        end
        state = view.session and view.session.semanticDialogueState or nil
    end
    if dialogueInternal
        and type(dialogueInternal.IdentityQuestionResponse) == "function"
    then
        return dialogueInternal.IdentityQuestionResponse(context, state)
    end
    return nil
end

Handlers.disclose_knowledge = function(result, packet, npcID, arguments)
    if not ToolFlow.Exposed(packet, "disclose_knowledge") then
        result.reason = "tool_not_exposed"
        return
    end
    local topicID = Runtime.Trim(arguments.topic_id)
    local preferenceItemType = Runtime.Trim(
        arguments.preference_item_type
    )
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
                preferenceItemType = preferenceItemType,
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
    local response = identityQuestionResponse(packet, npcID)
    local text = response and tostring(response.text or response.fallback or "")
        or ""
    if text == "" then
        local fallback = "I'll tell you my name once we've established some trust. What's your name?"
        local translation = PNC.Translation
        if translation and type(translation.TrFormat) == "function" then
            text = translation.TrFormat(
                "UI_PNC_Conversation_Semantic_QuestionIdentity",
                fallback
            )
        else
            text = fallback
        end
    end
    result.accepted = true
    result.reason = "identity_exchange_prompted"
    result.authoritative = false
    result.responseText = text
    result.replyContext = { outcome = "identity_exchange_prompt" }
end

return Handlers
