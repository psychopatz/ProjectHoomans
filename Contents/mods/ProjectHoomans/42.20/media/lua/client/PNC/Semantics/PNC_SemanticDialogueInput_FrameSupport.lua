-- Shared validation and receipt helpers for semantic input frames.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local InteractionLifecycle = Internal.InteractionLifecycle
local Suggestions = Internal.Suggestions

local function recordSemanticChoiceEnvelope(view, frame)
    if not InteractionLifecycle
        or type(InteractionLifecycle.Envelope) ~= "table"
        or type(InteractionLifecycle.Envelope.SemanticChoice) ~= "function"
    then
        return nil
    end
    local spec = view and view.spec or {}
    local session = view and view.session or {}
    local context = spec.context or {}
    local playerUUID = session.characterUUID
        or spec.characterUUID
        or context.characterUUID
        or context.playerUUID
    local envelope = InteractionLifecycle.Envelope.SemanticChoice(frame, {
        actorID = playerUUID,
        targetID = spec.npcID,
        playerUUID = playerUUID,
        topic = context.currentTopic or context.authoredTopic
            or context.conversationTopic,
        worldHour = context.worldHour,
    })
    if envelope and view then
        view.lastSemanticInteractionEnvelope = envelope
    end
    return envelope
end
Internal.RecordSemanticChoiceEnvelope = recordSemanticChoiceEnvelope

local function semanticFrameKey(view, frame)
    local session = view and view.session or {}
    return tostring(session.conversationID or "")
        .. ":" .. tostring(frame and frame.requestRevision or "")
        .. ":" .. tostring(frame and frame.candidateID or "")
end
Internal.SemanticFrameKey = semanticFrameKey

local function beginDirectFrame(view, frame, options)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    if type(Internal.Interactive) == "function"
        and not Internal.Interactive(view)
    then
        return false, "conversation_busy"
    end
    local context = view.spec and view.spec.context or nil
    if type(context) == "table"
        and context.pendingConversationRequest ~= nil
    then
        return false, "conversation_request_pending"
    end
    local requiresPresentedChoice = false
    if Suggestions then
        requiresPresentedChoice = (
            type(Suggestions.IsConversationCategoryFrame) == "function"
                and Suggestions.IsConversationCategoryFrame(frame)
        ) or (
            type(Suggestions.IsConversationChoiceFrame) == "function"
                and Suggestions.IsConversationChoiceFrame(frame)
        ) or (
            type(Suggestions.IsConversationRootChoiceFrame) == "function"
                and Suggestions.IsConversationRootChoiceFrame(frame)
        )
    end
    local coreAuthoredChoice = type(options) == "table"
        and options.coreAuthoredChoice == true
    if requiresPresentedChoice and not coreAuthoredChoice then
        local presentedChoice
        for _, choice in ipairs(view.session.choices or {}) do
            local source = type(choice) == "table"
                and type(choice.source) == "table" and choice.source or nil
            local presented = source and source.semanticFrame or nil
            if type(presented) == "table"
                and tostring(presented.candidateID or "")
                    == tostring(frame and frame.candidateID or "")
                and tonumber(presented.requestRevision)
                    == tonumber(frame and frame.requestRevision)
            then
                presentedChoice = choice
                break
            end
        end
        if not presentedChoice then
            return false, "suggestion_not_presented"
        end
        if presentedChoice.enabled == false then
            return false, "conversation_choice_disabled"
        end
    end
    recordSemanticChoiceEnvelope(view, frame)
    local router = type(Internal.RouterFor) == "function"
        and Internal.RouterFor(view) or nil
    if not router then return false, "semantic_router_unavailable" end
    local key = semanticFrameKey(view, frame)
    view.session.semanticSuggestionReceipts =
        view.session.semanticSuggestionReceipts or {}
    if view.session.semanticSuggestionReceipts[key] then
        return false, "duplicate_suggestion"
    end
    local expected = tonumber(frame and frame.requestRevision)
    local current = tonumber(router.state and router.state.sequence) or 0
    if expected == nil or expected ~= current then
        return false, "stale_suggestion"
    end
    return true, key
end
Internal.BeginDirectFrame = beginDirectFrame

local function finishDirectFrame(view, key)
    if not view or not view.session or not key then return end
    view.session.semanticSuggestionReceipts =
        view.session.semanticSuggestionReceipts or {}
    view.session.semanticSuggestionReceipts[key] = {
        status = "accepted",
        sequence = key,
    }
end
Internal.FinishDirectFrame = finishDirectFrame
