-- Public semantic submission and direct-frame routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local DialogueRuntime = Internal.DialogueRuntime
local Suggestions = Internal.Suggestions

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
    -- Core has already cleared the presented row before invoking its action.
    -- Execute the exact normalized authored action inline and let that same
    -- Core selection continue through response/next/close evaluation.  This
    -- is intentionally not Session:selectChoice(originalChoice): doing so
    -- would re-enter the session while the semantic row is still executing
    -- and can overwrite Core's pending lifecycle fields.
    if type(options) == "table"
        and options.coreAuthoredChoice == true
    then
        local allowed, receiptOrReason = Internal.BeginDirectFrame(
            view, frame, options
        )
        if not allowed then return false, receiptOrReason end
        local authoredChoice = options.authoredChoice
        if type(authoredChoice) ~= "table" then
            return false, "conversation_root_choice_unavailable"
        end
        Input.ActiveView = view
        if type(authoredChoice.action) == "function" then
            local context = view and view.session
                and view.session.context
                or view and view.spec and view.spec.context or {}
            authoredChoice.action(
                context,
                authoredChoice.source,
                view and view.session
            )
        end
        Internal.FinishDirectFrame(view, receiptOrReason)
        return true, "accepted"
    end
    if type(Suggestions.IsNavigationFrame) == "function"
        and Suggestions.IsNavigationFrame(frame)
    then
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local current, currentReason = Internal.NavigationFrameMatchesProjection(
            view, frame
        )
        if not current then return false, currentReason end
        local value = Suggestions.ResolveFrameText(frame)
        if value == "" then return false, "navigation_frame_text_missing" end

        local group = view and view.groupConversation
        local accepted
        local submitReason
        if group
            and type(group.SubmitSemanticNavigationFrame) == "function"
        then
            accepted, submitReason = group:SubmitSemanticNavigationFrame(
                frame, value
            )
        else
            accepted, submitReason = Internal.SubmitSingle(
                view,
                value,
                { semanticFrame = frame, navigationFrame = true }
            )
        end
        if accepted ~= true then
            return false, submitReason or "navigation_frame_rejected"
        end

        local projected, projectionReason = Internal.ApplyNavigationProjection(
            view, frame
        )
        if projected ~= true then
            return false, projectionReason or "navigation_projection_failed"
        end
        Internal.FinishDirectFrame(view, receiptOrReason)
        return true, "accepted"
    end
    -- A frame is already semantic state; retain its bounded meaning for
    -- lifecycle adapters without reparsing its presentation text. Existing
    -- branches still own acceptance, ConversationBlocks, authority/effects.
    if type(Suggestions.IsBackFrame) == "function"
        and Suggestions.IsBackFrame(frame)
    then
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        if type(Internal.SelectSemanticRoot) ~= "function" then
            return false, "semantic_root_unavailable"
        end
        local accepted, rootReason = Internal.SelectSemanticRoot(view, frame)
        if accepted == true then
            Internal.FinishDirectFrame(view, receiptOrReason)
        end
        return accepted, rootReason
    end
    if type(Suggestions.IsShortcutFrame) == "function"
        and Suggestions.IsShortcutFrame(frame)
    then
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local value = Suggestions.ResolveFrameText(frame)
        if value == "" then return false, "suggestion_frame_unavailable" end
        -- Keep the canonical shortcut frame attached to the submission. A
        -- native group host must not reparse the display label and turn a
        -- topic shortcut such as "What's up?" into a generic navigation
        -- acknowledgement.
        local accepted, submitReason = Input.Submit(view, value, {
            semanticFrame = frame,
            semanticShortcut = true,
        })
        if accepted == true then
            Internal.FinishDirectFrame(view, receiptOrReason)
        end
        return accepted, accepted == true and "accepted"
            or submitReason or "semantic_shortcut_rejected"
    end
    if type(Suggestions.IsGroupFrame) == "function"
        and Suggestions.IsGroupFrame(frame)
    then
        local allowed, reason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, reason end
        if type(Internal.SelectSemanticGroup) ~= "function" then
            return false, "semantic_group_unavailable"
        end
        local accepted, groupReason = Internal.SelectSemanticGroup(view, frame)
        if accepted == true then
            Internal.FinishDirectFrame(view, reason)
        end
        return accepted, groupReason
    end
    local isRootChoice = type(Suggestions.IsConversationRootChoiceFrame)
        == "function" and Suggestions.IsConversationRootChoiceFrame(frame)
    if isRootChoice then
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer then return false, "conversation_root_unavailable" end
        local choice
        local resolveReason
        if type(composer.ResolveSemanticRootChoice) == "function" then
            choice, resolveReason = composer.ResolveSemanticRootChoice(
                view, frame
            )
        else
            resolveReason = "conversation_root_resolver_unavailable"
        end
        if not choice then return false, resolveReason end
        local accepted
        local extensions = frame.extensions or {}
        if extensions.route == "conversation_category" then
            if type(composer.RequestCategory) ~= "function" then
                return false, "conversation_category_unavailable"
            end
            local npcID = view.spec and view.spec.npcID or nil
            accepted = composer.RequestCategory(
                npcID,
                extensions.categoryID,
                extensions.choiceID
            )
        elseif view.session and type(view.session.selectChoice) == "function" then
            accepted = view.session:selectChoice(choice)
        else
            return false, "conversation_root_choice_unavailable"
        end
        if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_root_choice_rejected"
    end
    if type(Suggestions.IsConversationCategoryFrame) == "function"
        and Suggestions.IsConversationCategoryFrame(frame)
    then
        -- Category suggestions are already typed by the production semantic
        -- layer. Route the canonical frame to the existing conversation
        -- composer/authority boundary; never reparse its display text.
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer or type(composer.RequestCategory) ~= "function" then
            return false, "conversation_category_unavailable"
        end
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local npcID = view and view.spec and view.spec.npcID or nil
        local accepted = composer.RequestCategory(
            npcID,
            frame.extensions.categoryID
        )
        if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_category_rejected"
    end
    if type(Suggestions.IsConversationChoiceFrame) == "function"
        and Suggestions.IsConversationChoiceFrame(frame)
    then
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer or type(composer.RequestChoice) ~= "function" then
            return false, "conversation_choice_unavailable"
        end
        local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local npcID = view and view.spec and view.spec.npcID or nil
        local extensions = frame.extensions
        local accepted = composer.RequestChoice(
            npcID,
            extensions.blockID,
            extensions.nodeID,
            extensions.choiceID
        )
        if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_choice_rejected"
    end
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
        { semanticFrame = frame }
    )
end
