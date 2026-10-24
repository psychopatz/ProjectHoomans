-- Semantic frame application and suggestion refresh.

local Refresh = {}

function Refresh.apply(context, state)
    local Runtime = state.Runtime
    local Input = state.Input
    local view = state.view
    local frame = state.frame
    local classification = state.classification
    local currentRevision = state.currentRevision
    local accepted, reason = Input.SubmitSemanticFrame(view, frame)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    local mode = Runtime.scenario and Runtime.scenario.runtime
        and Runtime.scenario.runtime.mode or "singleplayer"
    if accepted ~= true then
        -- Core may clear a row before invoking its semantic action. A busy,
        -- disabled, stale, replayed, or otherwise rejected frame must restore
        -- the exact current production projection without rebuilding context
        -- or mutating the conversation menu.
        local internal = Input.Internal
        if internal and type(internal.ApplySemanticChoices) == "function"
            and view.semanticSuggestions
        then
            internal.ApplySemanticChoices(view, view.semanticSuggestions)
        end
        return accepted, reason, state.Conversation.blockProjection(view)
    end
    if view.lifecycleFinished == true
        or view.closed == true
        or view.session and (
            view.session.lifecycleFinished == true
                or view.session.closed == true
        )
    then
        return accepted, reason, state.Conversation.blockProjection(view)
    end
    if accepted == true and mode ~= "multiplayer"
        and composer and type(composer.PumpLocalRequests) == "function"
    then
        composer.PumpLocalRequests()
    end
    state.Conversation.refreshViewContext(context)
    if classification.isGroup and view.semanticSuggestions then
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        if internal and type(internal.ApplySemanticChoices) == "function" then
            internal.ApplySemanticChoices(view, view.semanticSuggestions)
        end
    end
    local projectedBlock = state.Conversation.blockProjection(view)
    if classification.isRootChoice then
        local internal = Input.Internal
        if classification.isCategory and projectedBlock then
            local router = internal and type(internal.RouterFor) == "function"
                and internal.RouterFor(view) or nil
            local revision = router and router.state
                and tonumber(router.state.sequence) or currentRevision or 0
            if internal and type(internal.ShallowContext) == "function"
                and state.Suggestions
                and type(state.Suggestions.Build) == "function"
            then
                local semanticContext = internal.ShallowContext(view) or {}
                semanticContext.conversationBlock = projectedBlock
                view.semanticSuggestions = state.Suggestions.Build({
                    accepted = false,
                    sequence = revision,
                    state = { sequence = revision },
                    ir = {},
                    decision = {},
                }, semanticContext, nil)
            else
                view.semanticSuggestions = nil
            end
        else
            local refreshed = internal
                and type(internal.RefreshRootSuggestions) == "function"
                and internal.RefreshRootSuggestions(view) or nil
            if not refreshed then view.semanticSuggestions = nil end
        end
    end
    local blockAfter = view.spec.context.activeConversationBlockID
    local applied = accepted == true
    if classification.isCategory then
        applied = applied and blockAfter ~= nil and blockAfter ~= state.blockBefore
    end
    if not applied and accepted == true then
        accepted = false
        reason = view.spec.context.lastConversationError
            or (classification.isCategory and "conversation_block_unavailable"
                or "conversation_outcome_unavailable")
    end
    if accepted == true then
        Runtime.semanticClickReceipts[state.receiptKey] = true
    end
    return accepted, reason, projectedBlock
end

return Refresh

