-- Semantic click validation and replay protection.

local Validation = {}

function Validation.classify(frame, Suggestions)
    if type(frame) ~= "table" then
        return nil, "suggestion_frame_required"
    end
    local classification = {
        isCategory = Suggestions
            and Suggestions.IsConversationCategoryFrame
            and Suggestions.IsConversationCategoryFrame(frame),
        isChoice = Suggestions
            and Suggestions.IsConversationChoiceFrame
            and Suggestions.IsConversationChoiceFrame(frame),
        isRootChoice = Suggestions
            and Suggestions.IsConversationRootChoiceFrame
            and Suggestions.IsConversationRootChoiceFrame(frame),
        isShortcut = Suggestions
            and Suggestions.IsShortcutFrame
            and Suggestions.IsShortcutFrame(frame),
        isBack = Suggestions
            and Suggestions.IsBackFrame
            and Suggestions.IsBackFrame(frame),
        isGroup = Suggestions
            and Suggestions.IsGroupFrame
            and Suggestions.IsGroupFrame(frame),
    }
    if not classification.isCategory and not classification.isChoice
        and not classification.isRootChoice
        and not classification.isShortcut and not classification.isBack
        and not classification.isGroup
    then
        return nil, "unsupported_conversation_frame"
    end
    return classification
end

function Validation.receiptKey(frame, revision)
    return table.concat({
        tostring(frame.candidateID or ""), tostring(revision),
    }, ":")
end

function Validation.wasReplayed(Runtime, receiptKey)
    Runtime.semanticClickReceipts = Runtime.semanticClickReceipts or {}
    return Runtime.semanticClickReceipts[receiptKey] == true
end

function Validation.rejected(frame, reason, revision)
    return {
        ok = true,
        type = "semantic_click",
        input = tostring(frame.textFallback or frame.candidateID or ""),
        accepted = false,
        reason = reason,
        messages = {},
        trace = {},
        transport = {},
        toolCalls = {},
        observation = {
            suggestions = {
                schemaVersion = 1,
                kind = "semantic_dialogue_suggestions",
                revision = revision,
                candidates = {},
                groups = {},
                trace = {{
                    source = "suggestion_click",
                    status = "rejected",
                    reason = reason,
                    candidateCount = 0,
                }},
            },
        },
    }
end

return Validation

