-- Public semantic submission and direct-frame routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local DialogueRuntime = Internal.DialogueRuntime
local Suggestions = Internal.Suggestions

require "PNC/Semantics/PNC_SemanticDialogueInput_SubmissionFrames_Conversation"
require "PNC/Semantics/PNC_SemanticDialogueInput_SubmissionFrames_Navigation"

function Input.Submit(view, value, part)
    if not DialogueRuntime.IsEnabled() then
        return false, "semantic_dialogue_disabled"
    end
    local group = view and view.groupConversation
    if group and type(group.Submit) == "function" then
        return group:Submit(value, part)
    end
    return Internal.SubmitSingle(view, value, part)
end

function Input.SubmitSemanticFrame(view, frame, options)
    if not DialogueRuntime.IsEnabled() then
        return false, "semantic_dialogue_disabled"
    end

    local handled, accepted, reason = Internal.SubmitCoreAuthoredFrame(
        view, frame, options)
    if handled then return accepted, reason end
    handled, accepted, reason = Internal.SubmitNavigationFrame(
        view, frame)
    if handled then return accepted, reason end
    handled, accepted, reason = Internal.SubmitConversationFrame(
        view, frame, options)
    if handled then return accepted, reason end

    -- Capability rows carry their semantic parent group so an authoritative
    -- action can refresh the same contextual Orders hub after execution even
    -- when Core has rebuilt the authored menu during response delivery.
    if type(frame) == "table"
        and frame.kind == "semantic_click_frame"
        and type(frame.groupID) == "string"
        and frame.groupID ~= ""
    then
        view.semanticSuggestionGroupID = frame.groupID
        if view.session then
            view.session.semanticSuggestionGroupID = frame.groupID
        end
        if view.spec and view.spec.context then
            view.spec.context.semanticSuggestionGroupID = frame.groupID
        end
    end
    local group = view and view.groupConversation
    if group and type(group.SubmitSemanticFrame) == "function" then
        return group:SubmitSemanticFrame(frame)
    end
    if type(Suggestions.ResolveFrameText) ~= "function" then
        return false, "suggestion_frame_unavailable"
    end
    if group and type(group.Submit) == "function" then
        Internal.RecordSemanticChoiceEnvelope(view, frame)
        return group:Submit(Suggestions.ResolveFrameText(frame), {
            semanticFrame = frame,
        })
    end
    Internal.RecordSemanticChoiceEnvelope(view, frame)
    return Internal.SubmitSingle(
        view,
        Suggestions.ResolveFrameText(frame),
        {
            semanticFrame = frame,
            semanticTransientSurface = type(options) == "table"
                and options.transientCombatSurface == true,
        }
    )
end

return Input
