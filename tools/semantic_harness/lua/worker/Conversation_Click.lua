-- Semantic suggestion-click orchestration.

local Click = {}
local Validation = require "worker/Conversation_Click_Validation"
local Refresh = require "worker/Conversation_Click_Refresh"
local Response = require "worker/Conversation_Click_Response"

function Click.run(context, frame, Conversation)
    local Runtime = context.Runtime
    local Values = context.Values
    local Input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local Suggestions = PNC.Semantics and PNC.Semantics.DialogueSuggestions
    local view = Runtime.view
    if not view or not view.session or not Input
        or type(Input.SubmitSemanticFrame) ~= "function"
    then
        return nil, "conversation_unavailable"
    end

    local classification, classificationReason =
        Validation.classify(frame, Suggestions)
    if not classification then
        return nil, classificationReason
    end

    local revision = tonumber(frame.requestRevision)
    local currentRevision = tonumber(Runtime.lastSuggestionRevision)
    local receiptKey = Validation.receiptKey(frame, revision)
    if Validation.wasReplayed(Runtime, receiptKey) then
        return Validation.rejected(
            frame,
            "suggestion_click_replayed",
            currentRevision or 0
        )
    end
    if revision == nil or currentRevision == nil
        or revision ~= currentRevision
    then
        return Validation.rejected(
            frame,
            "suggestion_click_stale",
            currentRevision or 0
        )
    end

    local state = {
        Runtime = Runtime,
        Values = Values,
        Input = Input,
        Suggestions = Suggestions,
        view = view,
        frame = frame,
        Conversation = Conversation,
        classification = classification,
        revision = revision,
        currentRevision = currentRevision,
        receiptKey = receiptKey,
        transcriptBefore = #Runtime.transcript,
        queuedBefore = #Runtime.queued,
        traceBefore = #Runtime.trace,
        transportBefore = #Runtime.transport,
        translationBefore = #Runtime.translationLookups,
        blockBefore = view.spec.context.activeConversationBlockID,
        contextBefore = context.Conversation.contextSnapshot(
            context, view
        ),
    }
    state.accepted, state.reason, state.projection =
        Refresh.apply(context, state)
    if state.accepted == true then
        Runtime.turn = Runtime.turn + 1
        Runtime.now = Runtime.now + 1
    end
    return Response.build(context, state)
end

return Click
