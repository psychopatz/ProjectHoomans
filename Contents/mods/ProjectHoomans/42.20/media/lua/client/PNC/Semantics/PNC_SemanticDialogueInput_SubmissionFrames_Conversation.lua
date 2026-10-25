-- Conversation-owned semantic frame routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local Suggestions = Internal.Suggestions

function Internal.SubmitCoreAuthoredFrame(view, frame, options)
    if type(options) ~= "table" or options.coreAuthoredChoice ~= true then
        return false
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(
        view, frame, options
    )
    if not allowed then return true, false, receiptOrReason end
    local authoredChoice = options.authoredChoice
    if type(authoredChoice) ~= "table" then
        return true, false, "conversation_root_choice_unavailable"
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
    return true, true, "accepted"
end

local function submitConversationRootFrame(view, frame)
    if not Suggestions.IsConversationRootChoiceFrame
        or not Suggestions.IsConversationRootChoiceFrame(frame)
    then
        return false
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    Input.ActiveView = view
    local composer = PNC.Conversation
        and PNC.Conversation.Composer or nil
    if not composer then return true, false, "conversation_root_unavailable" end
    local choice
    local resolveReason
    if type(composer.ResolveSemanticRootChoice) == "function" then
        choice, resolveReason = composer.ResolveSemanticRootChoice(
            view, frame
        )
    else
        resolveReason = "conversation_root_resolver_unavailable"
    end
    if not choice then return true, false, resolveReason end
    local accepted
    local extensions = frame.extensions or {}
    if extensions.route == "conversation_category" then
        if type(composer.RequestCategory) ~= "function" then
            return true, false, "conversation_category_unavailable"
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
        return true, false, "conversation_root_choice_unavailable"
    end
    if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
    return true, accepted, accepted == true and "accepted"
        or "conversation_root_choice_rejected"
end

local function submitConversationCategoryFrame(view, frame)
    if not Suggestions.IsConversationCategoryFrame
        or not Suggestions.IsConversationCategoryFrame(frame)
    then
        return false
    end
    -- Category suggestions are already typed by the production semantic
    -- layer. Route the canonical frame to the existing composer/authority
    -- boundary; never reparse its display text.
    Input.ActiveView = view
    local composer = PNC.Conversation
        and PNC.Conversation.Composer or nil
    if not composer or type(composer.RequestCategory) ~= "function" then
        return true, false, "conversation_category_unavailable"
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    local npcID = view and view.spec and view.spec.npcID or nil
    local accepted = composer.RequestCategory(
        npcID,
        frame.extensions.categoryID
    )
    if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
    return true, accepted, accepted == true and "accepted"
        or "conversation_category_rejected"
end

local function submitConversationChoiceFrame(view, frame)
    if not Suggestions.IsConversationChoiceFrame
        or not Suggestions.IsConversationChoiceFrame(frame)
    then
        return false
    end
    Input.ActiveView = view
    local composer = PNC.Conversation
        and PNC.Conversation.Composer or nil
    if not composer or type(composer.RequestChoice) ~= "function" then
        return true, false, "conversation_choice_unavailable"
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    local npcID = view and view.spec and view.spec.npcID or nil
    local extensions = frame.extensions
    local accepted = composer.RequestChoice(
        npcID,
        extensions.blockID,
        extensions.nodeID,
        extensions.choiceID
    )
    if accepted == true then Internal.FinishDirectFrame(view, receiptOrReason) end
    return true, accepted, accepted == true and "accepted"
        or "conversation_choice_rejected"
end

function Internal.SubmitConversationFrame(view, frame, options)
    local handled, accepted, reason = submitConversationRootFrame(view, frame)
    if handled then return handled, accepted, reason end
    handled, accepted, reason = submitConversationCategoryFrame(view, frame)
    if handled then return handled, accepted, reason end
    handled, accepted, reason = submitConversationChoiceFrame(view, frame)
    if handled then return handled, accepted, reason end
    return false
end

return Input
