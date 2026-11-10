-- Typed conversation turn execution.

local Turn = {}

function Turn.run(context, text, Conversation)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.turn = Runtime.turn + 1
    Runtime.now = Runtime.now + 1
    local view = Runtime.view
    local queuedBefore = #Runtime.queued
    local transcriptBefore = #Runtime.transcript
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local semanticClickFrame = Runtime.semanticClickFrame
    Runtime.semanticClickFrame = nil
    local accepted
    local reason
    if semanticClickFrame then
        accepted, reason = PNC.Semantics.DialogueInput.SubmitSemanticFrame(
            view, semanticClickFrame
        )
    else
        accepted, reason = PNC.Semantics.DialogueInput.Submit(view, text)
    end
    local composer = PNC.Conversation and PNC.Conversation.Composer
    local mode = Runtime.scenario and Runtime.scenario.runtime
        and Runtime.scenario.runtime.mode or "singleplayer"
    if accepted == true and mode ~= "multiplayer"
        and view.spec.context.pendingConversationRequest ~= nil
        and composer and type(composer.PumpLocalRequests) == "function"
    then
        -- The real game receives this request through its normal network
        -- authority.  The harness only supplies the deterministic transport
        -- boundary, so pump the same composer request after typed input.
        composer.PumpLocalRequests()
    end
    -- The harness transport is an authoritative fixture. Refresh the same
    -- production context projection after a command so the next suggestion
    -- set reflects follow/stay state rather than replaying stale affordances.
    Conversation.refreshViewContext(context)
    local result = view.lastSemanticDialogueResult
    -- Inspect the exact situation built by the production input router, not
    -- a separately re-created approximation in the Python test harness.
    local router = view.session and view.session.semanticDialogueRouter
    local routedContext = router and router.context
    local routedSituation = routedContext and routedContext.dialogueSituation
    local actorService = view.session
        and view.session.semanticActorConversationService
    local newMessages = {}
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = queuedBefore + 1, #Runtime.queued do
        newMessages[#newMessages + 1] = Values.copy(Runtime.queued[index])
    end
    for index = transcriptBefore + 1, #Runtime.transcript do
        -- Transcript includes player input and queued NPC lines; preserve both.
    end
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local actionResult = view.lastSemanticActionResult
    Runtime.lastSemanticActionResult = Values.copy(actionResult)
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, actionResult
    )
    local response = {
        ok = true,
        type = "turn",
        input = text,
        accepted = accepted == true,
        reason = reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            actionResult = Values.copy(actionResult),
            compound = Values.copy(view.lastSemanticCompound),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = newMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(routedSituation),
        actorConversation = actorService
            and actorService.Snapshot and actorService:Snapshot() or nil,
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
        choiceSurface = Values.copy(
            view.session and view.session.choicePresentationState
        ),
        conversationBlock = Values.copy(
            view.spec and view.spec.context and view.spec.context.conversationBlock
        ),
        conversationGraph = Values.copy(
            Conversation.graphProjection(view)
        ),
    }
    context.OutputProjection.annotateTransport(response)
    response.observation = context.OutputProjection.observation(
        context, response, view.spec and view.spec.context
    )
    response.observation.conversationBlock = Values.copy(
        response.conversationBlock
    )
    response.observation.conversationGraph = Values.copy(
        response.conversationGraph
    )
    -- Authoritative receipts can arrive synchronously through the worker's
    -- dual-role transport after the ordinary semantic result is planned.
    -- Preserve their exact final NPC payload in the Inspector trace even
    -- when no native UI composer is present to build a plan envelope.
    response.observation.authoritativeMessages = {}
    for _, message in ipairs(newMessages) do
        if type(message) == "table" and message.speaker == "npc" then
            response.observation.authoritativeMessages[#response.observation.authoritativeMessages + 1] =
                Values.copy(message.payload)
        end
    end
    response.observation.authoritativeMessageCount =
        #response.observation.authoritativeMessages
    if response.observation.suggestions then
        Runtime.lastSuggestionRevision = tonumber(
            response.observation.suggestions.revision
        )
    end
    return response
end

return Turn
