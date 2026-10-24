-- Semantic Lab commands for the production interaction lifecycle.
-- Python transports requests and presents bounded results; Lua owns meaning,
-- provenance, compaction, persistence and authority decisions.

local Handler = {}

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
