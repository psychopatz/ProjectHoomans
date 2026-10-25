-- Single semantic-turn interpretation and cognition preparation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local Suggestions = Internal.Suggestions
local audit = Internal.audit
local attachInteractionEnvelope = Internal.attachInteractionEnvelope

local function rejected(view, value, reason)
    audit("semantic.input.rejected", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        rawText = value,
        reason = reason,
    })
    return nil, reason or "semantic_input_rejected"
end

function Internal.InterpretSingleSubmission(view, prepared)
    local value = prepared.value
    local semanticFrame = prepared.semanticFrame
    audit("semantic.input.received", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        rawText = value,
    })

    local router, routerReason = Internal.RouterFor(view)
    if not router then
        return rejected(view, value, routerReason)
    end
    local service = Internal.ActorConversationService
        and Internal.ActorConversationService(view) or nil
    local context = Internal.ShallowContext(view)
    local options = {
        timestamp = Internal.Now(),
    }
    local preview
    if semanticFrame then
        local expectedRevision = tonumber(semanticFrame.requestRevision)
        local receiptKey = tostring(view.session.conversationID or "")
            .. ":" .. tostring(expectedRevision)
            .. ":" .. tostring(semanticFrame.candidateID or "")
        view.session.semanticSuggestionReceipts =
            view.session.semanticSuggestionReceipts or {}
        if view.session.semanticSuggestionReceipts[receiptKey] then
            return nil, "duplicate_suggestion"
        end
        local currentRevision = tonumber(router.state and router.state.sequence)
            or 0
        if expectedRevision == nil or expectedRevision ~= currentRevision then
            return nil, "stale_suggestion"
        end
        local frameIR, frameReason = Suggestions.FrameToIR(
            semanticFrame, view)
        if not frameIR then return nil, frameReason end
        local eligible, eligibilityReason = Suggestions.CheckFrame(
            semanticFrame, context, frameIR
        )
        if eligible ~= true then return nil, eligibilityReason end
        preview = {
            schemaVersion = 1,
            kind = "semantic_dialogue_preview",
            accepted = true,
            ir = frameIR,
            decision = router:Decide(frameIR, context, options),
            state = router.state,
            sequence = router.state and router.state.sequence,
        }
    elseif service and type(service.Preview) == "function" then
        preview = service:Preview(value, context, options)
    elseif type(router.Preview) == "function" then
        preview = router:Preview(value, context, options)
    else
        preview = router:Process(value, context, options)
    end
    if preview.accepted ~= true then
        return rejected(view, value, preview.reason)
    end

    -- Recover only a bounded, question-shaped no-match when the current
    -- conversation supplies a single safe topic. The recovered IR is then
    -- routed through the same production policy and ProcessIR path as an
    -- authored pattern; actions still cannot be created by this spoke.
    if not semanticFrame
        and preview.ir and type(Internal.Recover) == "function"
    then
        local recovered = Internal.Recover(preview.ir, context, options)
        if recovered then
            preview.ir = recovered
            preview.decision = router:Decide(
                recovered,
                context,
                options
            )
            audit("semantic.input.recovered", {
                npcID = view.spec and view.spec.npcID,
                conversationID = view.session.conversationID,
                rawText = value,
                pattern = recovered.provenance
                    and recovered.provenance.pattern,
                topic = recovered.subject,
                confidence = recovered.confidence,
            }, { requestID = preview.sequence })
        end
    end

    attachInteractionEnvelope(
        view,
        preview,
        semanticFrame and "semantic_choice" or "typed_text",
        preview.ir,
        context,
        semanticFrame
    )

    local cognitionAccepted
    local cognitionRequestID
    local cognitionPending
    local clearSemanticMemoryTarget = false
    if Internal.RequestCognitionForIR then
        cognitionAccepted, _, cognitionRequestID, cognitionPending =
            Internal.RequestCognitionForIR(view, preview.ir)
        if preview.ir and preview.ir.intent == "GOSSIP"
            and cognitionAccepted == true
            and cognitionPending ~= true
        then
            -- Single-player/server-hosted cognition can finish synchronously.
            -- Rebuild the snapshot after the server fills its memory cache so
            -- this same turn can use the returned gossip.
            context = Internal.ShallowContext(view)
            clearSemanticMemoryTarget = true
        end
    end

    local identityRequest = Internal.PrepareIdentityRequest
        and Internal.PrepareIdentityRequest(view, preview.ir, context)

    return {
        router = router,
        service = service,
        context = context,
        options = options,
        preview = preview,
        cognitionRequestID = cognitionRequestID,
        cognitionPending = cognitionPending,
        clearSemanticMemoryTarget = clearSemanticMemoryTarget,
        identityRequest = identityRequest,
    }
end

return Input
