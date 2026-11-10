-- Semantic Lab commands for the production interaction lifecycle.
-- Python transports requests and presents bounded results; Lua owns meaning,
-- provenance, compaction, persistence and authority decisions.

local Handler = {}

local function contextCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 32 then break end
        if type(key) == "string" or type(key) == "number" then
            if type(item) == "table" then
                output[key] = contextCopy(item)
            elseif type(item) == "string"
                or type(item) == "number"
                or type(item) == "boolean"
            then
                output[key] = item
            end
            count = count + 1
        end
    end
    return output
end

local function boundedList(values, limit)
    local output = {}
    if type(values) ~= "table" then return output end
    limit = tonumber(limit) or 8
    for index = 1, math.min(#values, limit) do
        local value = values[index]
        if value ~= nil and tostring(value) ~= "" then
            output[#output + 1] = string.sub(tostring(value), 1, 128)
        end
    end
    return output
end

local function boundedFacts(values, eventRef)
    local output = {}
    if type(values) ~= "table" then return output end
    local count = 0
    for key, value in pairs(values) do
        if count >= 16 then break end
        if type(key) == "string" or type(key) == "number" then
            if type(value) == "table" then
                output[tostring(key)] = contextCopy(value)
                count = count + 1
            elseif type(value) == "string"
                or type(value) == "number"
                or type(value) == "boolean"
            then
                output[tostring(key)] = value
                count = count + 1
            end
        end
    end
    if eventRef and output[eventRef] == nil then
        output[eventRef] = {
            eventRef = eventRef,
            authoritative = true,
            disclosure = "player",
        }
    end
    return output
end

local function selectedOffers(realization)
    local output = {}
    local plan = realization and realization.responsePlan or nil
    for _, turn in ipairs(plan and plan.turns or {}) do
        for _, offer in ipairs(turn.offers or {}) do
            if #output >= 8 then return output end
            if offer and offer.id then
                output[#output + 1] = tostring(offer.id)
            end
        end
    end
    return output
end

local function lifecycle(context)
    local value = context.Runtime and context.Runtime.interactionLifecycle
    local module = PNC.Semantics
        and PNC.Semantics.InteractionLifecycle or nil
    return module, value
end

local function defaults(context, payload)
    payload = type(payload) == "table" and payload or {}
    local scenario = context.Runtime.scenario or {}
    local player = scenario.player or {}
    local npc = scenario.npc or {}
    local conversation = scenario.conversation or {}
    return {
        actorID = payload.actorID
            or player.characterUUID or player.playerUUID or "player-one",
        targetID = payload.targetID or npc.npcID or npc.id or "harness-npc",
        playerUUID = payload.playerUUID
            or player.characterUUID or player.playerUUID or "player-one",
        topic = payload.topic or conversation.topic,
        worldHour = payload.worldHour
            or scenario.world and scenario.world.worldAgeHours,
    }
end

local function buildEnvelope(context, payload)
    local module = lifecycle(context)
    if not module then return nil, "interaction_lifecycle_unavailable" end
    local Envelope = module.Envelope
    payload = type(payload) == "table" and payload or {}
    if type(payload.envelope) == "table" then
        return Envelope.Build(payload.envelope)
    end
    local contextDefaults = defaults(context, payload)
    local source = payload.source or payload.adapter or payload.kind
    if source == "typed_text" or source == "typed" or source == "headless" then
        return Envelope.TypedText(payload.ir or payload, contextDefaults)
    elseif source == "semantic_choice" or source == "button"
        or source == "choice"
    then
        return Envelope.SemanticChoice(
            payload.frame or payload, contextDefaults
        )
    elseif source == "emote" then
        return Envelope.Emote(payload.emote or payload, contextDefaults)
    elseif source == "conversation_lifecycle" or source == "lifecycle" then
        return Envelope.Lifecycle(
            payload.eventType or payload.lifecycleEvent, contextDefaults
        )
    elseif source == "world_event" or source == "event" then
        return Envelope.WorldEvent(payload.event or payload, contextDefaults)
    elseif source == "npc_speech" or source == "npc" then
        payload.npcID = payload.npcID or contextDefaults.targetID
        payload.playerUUID = payload.playerUUID or contextDefaults.playerUUID
        payload.targetID = payload.targetID or contextDefaults.playerUUID
        return Envelope.NPCSpeech(payload)
    end
    return nil, "interaction_source_required"
end

local function result(context, operation, value, reason)
    local module, store = lifecycle(context)
    if not module or not store then return nil, "interaction_lifecycle_unavailable" end
    return {
        ok = value ~= nil,
        type = "interaction_lifecycle",
        operation = operation,
        reason = reason,
        result = context.Values.copy(value),
        metrics = module.Metrics(store),
    }
end

local function npcEvent(context, payload, module, store)
    local Values = context.Values
    local Runtime = context.Runtime
    local defaultsValue = defaults(context, payload)
    local eventType = tostring(
        payload.eventType
            or payload.event and (payload.event.eventType or payload.event.type)
            or "social_reaction"
    )
    local eventRef = tostring(
        payload.eventRef
            or payload.eventID
            or payload.event and (payload.event.eventRef or payload.event.id)
            or "event:semantic-lab:" .. eventType
    )
    local factRefs = boundedList(
        payload.factRefs
            or payload.context and payload.context.factRefs,
        8
    )
    local reactionContext = contextCopy(payload.context or {})
    reactionContext.eventType = eventType
    reactionContext.eventID = eventRef
    reactionContext.npcID = payload.npcID or defaultsValue.targetID
    reactionContext.factRefs = factRefs
    reactionContext.semanticEventFacts = contextCopy(
        payload.semanticEventFacts
            or payload.context and payload.context.semanticEventFacts
    )
    local reactions = PNC.Semantics and PNC.Semantics.SocialReactions
    if type(reactions) ~= "table"
        or type(reactions.Resolve) ~= "function"
    then
        return nil, "social_reactions_unavailable"
    end
    local realization, realizationReason = reactions.Resolve({
        eventType = eventType,
        eventID = eventRef,
        npcID = reactionContext.npcID,
        context = reactionContext,
        act = payload.act or "REACT",
        topic = payload.topic,
        groundedFactRefs = factRefs,
        salt = payload.salt or eventRef,
    })
    if type(realization) ~= "table" then
        return nil, realizationReason or "event_realization_unavailable"
    end
    local offerIDs = selectedOffers(realization)
    local beatID = payload.beatID or "beat:" .. eventRef
    local npcID = payload.npcID or defaultsValue.targetID
    local playerUUID = payload.playerUUID or defaultsValue.playerUUID
    local speech, speechReason = module.RecordNPCSpeech(store, {
        npcID = npcID,
        actorID = npcID,
        targetID = payload.targetID or playerUUID,
        playerUUID = playerUUID,
        act = realization.semanticAct or payload.act or "REACT",
        topic = realization.topic or eventType,
        eventType = eventType,
        eventRef = eventRef,
        factRefs = factRefs,
        beatID = beatID,
        responsePlanID = realization.responsePlanID,
        poolID = realization.responsePlanID,
        realizationFamily = realization.realizationFamily,
        realizationID = realization.realizationID,
        offerIDs = offerIDs,
        expectedReplies = payload.expectedReplies,
        meaningful = true,
        worldHour = payload.worldHour,
    })
    if type(speech) ~= "table" then return nil, speechReason end

    local window = module.ResponseWindow(store, playerUUID, npcID)
    local facts = boundedFacts(
        payload.semanticEventFacts or payload.facts,
        eventRef
    )
    if facts[eventRef] == nil and #factRefs > 0 then
        facts[eventRef] = {
            eventRef = eventRef,
            authoritative = true,
            disclosure = "player",
            factRefs = factRefs,
        }
    end
    local view = Runtime.view
    if view and view.session and view.spec then
        -- The response window is the existing player-scoped lifecycle
        -- projection. Facts are bounded authoritative inputs, never rendered
        -- prose or a second recent-event registry.
        view.session.semanticInteractionLifecycle = Values.copy(window)
        view.spec.context.interactionLifecycle = Values.copy(window)
        view.spec.context.semanticEventFacts = Values.copy(facts)
        view.spec.context.eventRef = eventRef
        view.spec.context.eventType = eventType
        view.spec.context.factRefs = Values.copy(factRefs)
        view.lastNPCSemanticInteraction = {
            eventRef = eventRef,
            eventType = eventType,
            provenance = {
                beatID = beatID,
                responsePlanID = realization.responsePlanID,
                poolID = realization.responsePlanID,
                realizationFamily = realization.realizationFamily,
                realizationID = realization.realizationID,
                eventRef = eventRef,
                factRefs = Values.copy(factRefs),
                offerIDs = Values.copy(offerIDs),
            },
        }
        context.Conversation.refreshViewContext(context)
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        if internal and type(internal.RefreshRootSuggestions) == "function" then
            internal.RefreshRootSuggestions(view)
        end
    end
    return {
        accepted = true,
        persisted = speech.persisted == true,
        eventRef = eventRef,
        eventType = eventType,
        factRefs = factRefs,
        facts = facts,
        realization = Values.copy(realization),
        speech = Values.copy(speech),
        responseWindow = Values.copy(window),
        suggestions = Values.copy(view and view.semanticSuggestions),
    }
end

function Handler.handle(context, command, payload)
    local module, store = lifecycle(context)
    if command == "INTERACTION_ENVELOPE" then
        local envelope, reason = buildEnvelope(context, payload)
        if not envelope then return nil, reason end
        return {
            ok = true,
            type = "interaction_envelope",
            envelope = envelope,
            meaningKey = module.Envelope.MeaningKey(envelope),
        }
    end
    if string.sub(command, 1, 12) ~= "INTERACTION_" then return false end
    if not module or not store then
        return nil, "interaction_lifecycle_unavailable"
    end
    payload = type(payload) == "table" and payload or {}
    if command == "INTERACTION_APPLY" then
        local envelope, reason = buildEnvelope(context, payload)
        if not envelope then return nil, reason end
        local value, applyReason = module.Apply(
            store, envelope, payload.options or {}
        )
        return result(context, "apply", value, applyReason)
    elseif command == "INTERACTION_NPC_SPEECH" then
        local spec = context.Values.copy(payload)
        local defaultsValue = defaults(context, payload)
        spec.npcID = spec.npcID or defaultsValue.targetID
        spec.playerUUID = spec.playerUUID or defaultsValue.playerUUID
        spec.targetID = spec.targetID or defaultsValue.playerUUID
        local value, speechReason = module.RecordNPCSpeech(store, spec)
        return result(context, "npc_speech", value, speechReason)
    elseif command == "INTERACTION_NPC_EVENT" then
        local value, eventReason = npcEvent(context, payload, module, store)
        if not value then return nil, eventReason end
        return {
            ok = true,
            type = "interaction_npc_event",
            operation = "npc_event",
            result = value,
            metrics = module.Metrics(store),
        }
    elseif command == "INTERACTION_CLOSE" then
        local d = defaults(context, payload)
        local value, closeReason = module.Close(
            store, d.playerUUID, d.targetID, payload.options or payload
        )
        return result(context, "close", value, closeReason)
    elseif command == "INTERACTION_RESUME" then
        local d = defaults(context, payload)
        local value, resumeReason = module.Resume(
            store, d.playerUUID, d.targetID, payload.options or payload
        )
        return result(context, "resume", value, resumeReason)
    elseif command == "INTERACTION_COMPACT" then
        local d = defaults(context, payload)
        local value, compactReason = module.Compact(
            store, d.playerUUID, d.targetID, payload.options or payload
        )
        return result(context, "compact", value, compactReason)
    elseif command == "INTERACTION_ADVANCE_TIME" then
        local value = module.Advance(store, payload.worldHour)
        return result(context, "advance_time", value)
    elseif command == "INTERACTION_MAINTENANCE" then
        local value = module.Maintenance(store, payload.limit)
        return result(context, "maintenance", value)
    elseif command == "INTERACTION_REGISTER_EVENT" then
        local value, eventReason = module.RegisterSharedEvent(
            store, payload.event or payload
        )
        return result(context, "register_event", value, eventReason)
    elseif command == "INTERACTION_PROJECT" then
        local d = defaults(context, payload)
        local value = module.Project(
            store, payload.playerUUID or d.playerUUID,
            payload.npcID or d.targetID
        )
        return result(context, "project", value)
    elseif command == "INTERACTION_RESPONSE_WINDOW" then
        local d = defaults(context, payload)
        local value = module.ResponseWindow(
            store,
            payload.playerUUID or d.playerUUID,
            payload.npcID or d.targetID
        )
        return result(context, "response_window", value)
    elseif command == "INTERACTION_METRICS" then
        return result(context, "metrics", module.Metrics(store))
    elseif command == "INTERACTION_EXPORT" then
        return result(context, "export", module.Export(store))
    elseif command == "INTERACTION_IMPORT" then
        local accepted, importReason = module.Import(store, payload.snapshot)
        return result(context, "import", { accepted = accepted }, importReason)
    end
    return false
end

return Handler
