-- Talk session lifecycle, emotes, and target matrix operations.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity
local Internal = TalkParity.Internal
local SpeechDelivery = Internal.SpeechDelivery
local compactScenario = Internal.compactScenario
local compactWorkingWorld = Internal.compactWorkingWorld
local compactTalkSnapshot = Internal.compactTalkSnapshot
local compactTurn = Internal.compactTurn
local compactObservation = Internal.compactObservation

function TalkParity.Start(context, value, utterance)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario, targetOrReason = TalkParity.ApplyTarget(
        Values.copy(Runtime.scenario), value
    )
    if not scenario then return nil, targetOrReason end
    local configured = context.ScenarioSession.reset(context, scenario)
    Runtime.conversationOpened = true
    Runtime.conversationSuspended = false
    if Runtime.view then Runtime.view.opened = true end
    local start, reason = TalkParity.StartProjection(
        context, targetOrReason, Runtime.view
    )
    if not start then return nil, reason end
    local turn = context.Conversation.turn(
        context, tostring(utterance or "hello")
    )
    local snapshot = context.ScenarioSession.snapshot(context)
    -- A saved actor may carry a large raw provider payload (for example a
    -- native inventory blob). Talk parity needs the effective scenario and
    -- conversation projection, not a second copy of the complete source
    -- snapshot on every turn. The full immutable source remains available
    -- through SNAPSHOT/import responses.
    if type(snapshot.sourceSnapshot) == "table" then
        snapshot.sourceSnapshot.data = nil
        snapshot.sourceSnapshot.providerPayloads = nil
    end
    if type(snapshot.workingWorld) == "table" then
        snapshot.workingWorld.baseline = nil
    end
    local conversationPresentation = Values.copy(
        snapshot.conversationPresentation
    )
    local compactScenarioValue = compactScenario(scenario, Values)
    local compactConfigured = compactTalkSnapshot(configured, Values)
    if type(compactConfigured.sourceSnapshot) == "table" then
        compactConfigured.sourceSnapshot.data = nil
        compactConfigured.sourceSnapshot.providerPayloads = nil
    end
    compactConfigured.workingWorld = compactWorkingWorld(
        compactConfigured.workingWorld, Values
    )
    snapshot = compactTalkSnapshot(snapshot, Values)
    return {
        schema = TalkParity.SCHEMA,
        type = "talk_start",
        scenario = compactScenarioValue,
        configured = compactConfigured,
        start = start,
        turn = compactTurn(context, turn),
        observation = compactObservation(context, start, turn, snapshot),
        conversationPresentation = conversationPresentation,
        snapshot = snapshot,
    }
end

function TalkParity.Open(context, value)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario, targetOrReason = TalkParity.ApplyTarget(
        Values.copy(Runtime.scenario), value
    )
    if not scenario then return nil, targetOrReason end
    context.ScenarioSession.reset(context, scenario)
    Runtime.conversationOpened = true
    Runtime.conversationSuspended = false
    if Runtime.view then Runtime.view.opened = true end
    local start, reason = TalkParity.StartProjection(
        context, targetOrReason, Runtime.view
    )
    if not start then return nil, reason end
    local snapshot = context.ScenarioSession.snapshot(context)
    -- Open is the primary Conversation presentation boundary. Do not return
    -- configured inspector data or a second full snapshot here: saved-world
    -- imports can contain large source/working-world payloads, and duplicating
    -- them can exceed the worker transport limit before the bounded
    -- Conversation projection is delivered. SNAPSHOT remains the explicit
    -- inspector boundary.
    return {
        schema = TalkParity.SCHEMA,
        type = "conversation_open",
        start = start,
        presentation = Values.copy(snapshot.conversationPresentation),
    }
end

function TalkParity.Suspend(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local session = view and view.session or nil
    if not view or not session or Runtime.conversationOpened ~= true then
        return nil, "conversation_not_open"
    end
    if view.closed == true or session.closed == true
        or session.lifecycleFinished == true
    then
        return nil, "conversation_closed"
    end
    local pendingRequest = view.spec and view.spec.context
        and view.spec.context.pendingConversationRequest or nil
    if session.busy == true or pendingRequest ~= nil then
        return nil, "conversation_pending"
    end
    Runtime.conversationSuspended = true
    view.suspended = true
    view.opened = false
    session.pendingChoices = nil
    session.pendingNext = nil
    session.pendingClose = nil
    session.pendingCloseReason = nil
    session.busy = false
    if type(session.clearChoices) == "function" then
        session:clearChoices("conversation_suspended")
    end
    local snapshot = context.ScenarioSession.snapshot(context)
    return {
        schema = TalkParity.SCHEMA,
        type = "conversation_suspend",
        presentation = Values.copy(snapshot.conversationPresentation),
        snapshot = snapshot,
    }
end

function TalkParity.Resume(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local session = view and view.session or nil
    if not view or not session or view.suspended ~= true
        or Runtime.conversationSuspended ~= true
    then
        return nil, "conversation_not_suspended"
    end
    if view.closed == true or session.closed == true
        or session.lifecycleFinished == true
    then
        return nil, "conversation_closed"
    end
    Runtime.conversationSuspended = false
    view.suspended = false
    view.opened = true
    Runtime.conversationOpened = true
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal and type(internal.ApplySemanticChoices) == "function"
        and view.semanticSuggestions
    then
        internal.ApplySemanticChoices(view, view.semanticSuggestions)
    end
    local snapshot = context.ScenarioSession.snapshot(context)
    return {
        schema = TalkParity.SCHEMA,
        type = "conversation_resume",
        presentation = Values.copy(snapshot.conversationPresentation),
        snapshot = snapshot,
    }
end

function TalkParity.Close(context, reason)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local session = view and view.session or nil
    if not view or not session or Runtime.conversationOpened ~= true then
        return nil, "conversation_not_open"
    end
    if view.closed == true or session.closed == true then
        return nil, "conversation_closed"
    end
    Runtime.conversationOpened = false
    Runtime.conversationSuspended = false
    view.opened = false
    view.suspended = false
    view.closed = true
    session.closed = true
    session.conversationMemoryClosed = true
    if type(session.clearChoices) == "function" then
        session:clearChoices(reason or "conversation_closed")
    end
    local snapshot = context.ScenarioSession.snapshot(context)
    return {
        schema = TalkParity.SCHEMA,
        type = "conversation_close",
        reason = tostring(reason or "conversation_closed"),
        presentation = Values.copy(snapshot.conversationPresentation),
        snapshot = snapshot,
    }
end

function TalkParity.Emote(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local session = view and view.session or nil
    if not view or not session or Runtime.conversationOpened ~= true then
        return nil, "conversation_not_open"
    end
    if Runtime.conversationSuspended == true or view.suspended == true then
        return nil, "conversation_suspended"
    end
    if view.closed == true or session.closed == true
        or session.lifecycleFinished == true
    then
        return nil, "conversation_closed"
    end
    payload = type(payload) == "table" and payload or {}
    local emote = type(payload.emote) == "table"
        and payload.emote or payload
    local gesture = tostring(
        emote.gesture or emote.id or emote.emoteID or ""
    )
    local lifecycle = PNC.Semantics
        and PNC.Semantics.InteractionLifecycle or nil
    local store = Runtime.interactionLifecycle
    if not lifecycle or not store or type(lifecycle.Envelope) ~= "table"
        or type(lifecycle.Envelope.Emote) ~= "function"
        or type(lifecycle.Apply) ~= "function"
    then
        return nil, "interaction_lifecycle_unavailable"
    end
    local scenario = Runtime.scenario or {}
    local player = scenario.player or {}
    local npc = scenario.npc or {}
    local actorID = payload.actorID
        or player.characterUUID or player.playerUUID or "player-one"
    local targetID = payload.targetID or npc.npcID or npc.id
    local playerUUID = payload.playerUUID or actorID
    local previous = type(lifecycle.Project) == "function"
        and lifecycle.Project(store, playerUUID, targetID) or nil
    local activeBeat = previous and previous.thread
        and previous.thread.activeBeat or nil
    local topic = payload.topic
        or activeBeat and activeBeat.topic
        or scenario.conversation and scenario.conversation.topic
    local eventRef = payload.eventRef or payload.eventID or payload.requestID
    eventRef = eventRef or "conversation:semantic_emote:" .. actorID
        .. ":" .. tostring(targetID or "unknown") .. ":"
        .. gesture .. ":" .. tostring(
            payload.worldHour
                or scenario.world and scenario.world.worldAgeHours or 0
        )
    local baseEnvelope = lifecycle.Envelope.Emote(
        emote,
        {
            actorID = actorID,
            targetID = targetID,
            playerUUID = playerUUID,
            topic = topic,
            eventRef = eventRef,
            worldHour = payload.worldHour
                or scenario.world and scenario.world.worldAgeHours,
        }
    )
    local realizationAuthority = PNC.Semantics
        and PNC.Semantics.RealizationAuthority
        or require "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
    local realization = realizationAuthority
        and type(realizationAuthority.Resolve) == "function"
        and realizationAuthority.Resolve({
            poolID = "semantic.emote.reply",
            responsePlanID = "semantic.emote.reply",
            realizationFamily = "emote_reply",
            act = baseEnvelope and baseEnvelope.act or emote.act,
            topic = topic or "social_reaction",
            context = {
                action = gesture,
                currentTopic = topic,
                previousTopic = activeBeat and activeBeat.topic,
                npcID = targetID,
            },
            salt = eventRef,
        }) or nil
    local provenance = Values.copy(payload.provenance or {})
    if realization then
        provenance.responsePlanID = realization.responsePlanID
        provenance.realizationFamily = realization.realizationFamily
        provenance.realizationID = realization.realizationID
        provenance.poolID = realization.realizationFamily
        provenance.factRefs = realization.groundedFactRefs
    end
    local envelope = lifecycle.Envelope.Emote(
        emote,
        {
            actorID = actorID,
            targetID = targetID,
            playerUUID = playerUUID,
            topic = topic,
            eventRef = eventRef,
            worldHour = payload.worldHour
                or scenario.world and scenario.world.worldAgeHours,
            provenance = provenance,
        }
    )
    local value, reason = lifecycle.Apply(
        store,
        envelope,
        payload.options or { meaningful = payload.meaningful == true }
    )
    local speech
    if value and realization and realization.fallback then
        speech = { accepted = false, reason = "speech_not_delivered" }
        local delivered, deliveryReason = SpeechDelivery.NPC({
            session = session,
            dedupeStore = Runtime.semanticSpeechDelivery,
            eventID = eventRef,
            npcID = targetID,
            target = npc,
            speakerName = npc.displayName or npc.name,
            playerActor = context.player,
            text = realization.fallback,
            semanticAct = realization.semanticAct,
            topic = realization.topic or topic,
            responsePlanID = realization.responsePlanID,
            realizationFamily = realization.realizationFamily,
            realizationID = realization.realizationID,
            factRefs = realization.groundedFactRefs,
            compatibilityFlavorID = realization.compatibilityFlavorID,
            interaction = envelope,
        })
        speech.accepted = delivered == true
        speech.reason = deliveryReason
        speech.text = realization.fallback
    end
    local snapshot = context.ScenarioSession.snapshot(context)
    return {
        schema = TalkParity.SCHEMA,
        type = "conversation_emote",
        accepted = value ~= nil,
        reason = reason,
        envelope = Values.copy(envelope),
        realization = Values.copy(realization),
        speech = Values.copy(speech),
        interaction = Values.copy(snapshot.interactionLifecycle),
        presentation = Values.copy(snapshot.conversationPresentation),
        snapshot = snapshot,
    }
end

function TalkParity.Matrix(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    payload = type(payload) == "table" and payload or {}
    local original = Values.copy(Runtime.scenario)
    local originalDynamicTradingLoaded = Runtime.dynamicTradingLoaded
    local base = Values.copy(original)
    local targetIDs = payload.targetIDs
    if type(targetIDs) ~= "table" or #targetIDs == 0 then
        targetIDs = { "colonist", "follower", "neutral", "hostile" }
    end
    local maximum = math.max(1, math.min(8, tonumber(payload.maximum) or 8))
    local utterance = tostring(payload.utterance or "hello")
    local rows = {}
    for index = 1, math.min(#targetIDs, maximum) do
        local targetID = targetIDs[index]
        local scenario, canonicalOrReason = TalkParity.ApplyTarget(base, targetID)
        if scenario then
            Runtime.dynamicTradingLoaded = originalDynamicTradingLoaded
            context.ScenarioSession.reset(context, scenario)
            local start, startReason = TalkParity.StartProjection(
                context, canonicalOrReason, Runtime.view
            )
            if start then
                local turn = context.Conversation.turn(context, utterance)
                local snapshot = context.ScenarioSession.snapshot(context)
                local row = compactObservation(context, start, turn, snapshot)
                row.index = index - 1
                row.label = start.target.label
                row.target = start.target
                row.integration = Values.copy(start.integration)
                rows[#rows + 1] = row
            else
                rows[#rows + 1] = {
                    index = index - 1,
                    label = tostring(targetID),
                    error = startReason,
                }
            end
        else
            rows[#rows + 1] = {
                index = index - 1,
                label = tostring(targetID),
                error = canonicalOrReason,
            }
        end
    end
    Runtime.dynamicTradingLoaded = originalDynamicTradingLoaded
    context.ScenarioSession.reset(context, original)
    return {
        ok = true,
        schema = "semantic.talk.parity.matrix.v1",
        utterance = utterance,
        targets = TalkParity.GetCatalog(),
        rows = rows,
        restoredScenario = true,
    }
end

return TalkParity
