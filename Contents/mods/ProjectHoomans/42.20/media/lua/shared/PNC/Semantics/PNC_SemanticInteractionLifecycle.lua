-- One bounded semantic interaction contract and lifecycle state owner.
--
-- This module deliberately does not parse text, select responses, or grant
-- gameplay authority.  Existing NLU, suggestion, ConversationBlock and
-- domain services remain the owners of those concerns.  The lifecycle stores
-- semantic meaning and provenance, never rendered transcript text.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle

Lifecycle.VERSION = 1
Lifecycle.SCHEMA = "semantic.interaction.lifecycle.v1"
Lifecycle.ENVELOPE_SCHEMA = "semantic.interaction.envelope.v1"
Lifecycle.LIMITS = {
    factRefs = 8,
    modifiers = 12,
    topicStack = 4,
    turns = 12,
    openQuestions = 8,
    commitments = 8,
    eventRefs = 16,
    realizations = 8,
    sharedEvents = 64,
    pairs = 4096,
}

local Envelope = Lifecycle.Envelope or {}
Lifecycle.Envelope = Envelope

local VALID_SOURCES = {
    typed_text = true,
    semantic_choice = true,
    emote = true,
    conversation_lifecycle = true,
    world_event = true,
    npc_speech = true,
}

local SOURCE_ALIASES = {
    typed = "typed_text",
    headless = "typed_text",
    button = "semantic_choice",
    choice = "semantic_choice",
    lifecycle = "conversation_lifecycle",
    event = "world_event",
    npc = "npc_speech",
}

local ACT_ALIASES = {
    GREETING = "GREET",
    HELLO = "GREET",
    GOODBYE = "FAREWELL",
    FAREWELLING = "FAREWELL",
    THANKS = "THANK",
    THANKYOU = "THANK",
    ACKNOWLEDGEMENT = "ACK",
    ACKNOWLEDGMENT = "ACK",
    REACTION = "REACT",
}

local EMOTE_ACTS = {
    wavehi = "GREET",
    wavebye = "FAREWELL",
    thankyou = "THANK",
    thumbsup = "ACK",
    thumbsdown = "DISAPPROVE",
    insult = "INSULT",
    clap = "PRAISE",
    salute = "ACK",
}

local function clean(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, maximum or 96)
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function boundedCopy(value, depth, budget)
    local kind = type(value)
    if kind ~= "table" then
        if kind == "string" then return string.sub(value, 1, 160) end
        if kind == "number" or kind == "boolean" then return value end
        return nil
    end
    depth = tonumber(depth) or 0
    budget = budget or { count = 0, limit = 64 }
    budget.limit = tonumber(budget.limit) or 64
    if depth >= 3 then return nil end
    local result = {}
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > budget.limit then break end
        if type(key) == "string" or type(key) == "number" then
            local copied = boundedCopy(item, depth + 1, budget)
            if copied ~= nil then result[key] = copied end
        end
    end
    return result
end

local function boundedList(value, limit)
    local result = {}
    if type(value) ~= "table" then return result end
    limit = tonumber(limit) or 8
    for index = 1, math.min(#value, limit) do
        local item = clean(value[index], 128)
        if item then result[#result + 1] = item end
    end
    return result
end

local function normalizeSource(value)
    local source = string.lower(clean(value, 48) or "")
    source = SOURCE_ALIASES[source] or source
    return VALID_SOURCES[source] and source or nil
end

local function normalizeAct(value)
    local act = string.upper(clean(value, 48) or "")
    act = string.gsub(act, "[%s%-]+", "_")
    return ACT_ALIASES[act] or act
end

local function sourceField(input, semantic, ir, key)
    return input[key]
        or semantic and semantic[key]
        or ir and ir[key]
end

local function provenance(input, act, topic, factRefs)
    local source = type(input.provenance) == "table"
        and input.provenance or {}
    local result = {
        act = act,
        topic = topic,
        beatID = clean(source.beatID or input.beatID, 96),
        responsePlanID = clean(
            source.responsePlanID or input.responsePlanID, 128
        ),
        flowID = clean(source.flowID or input.flowID, 128),
        poolID = clean(source.poolID or input.poolID, 128),
        realizationFamily = clean(
            source.realizationFamily or input.realizationFamily,
            128
        ),
        realizationID = clean(
            source.realizationID or input.realizationID,
            128
        ),
        factRefs = factRefs,
    }
    if not result.beatID then result.beatID = nil end
    if not result.responsePlanID then result.responsePlanID = nil end
    if not result.flowID then result.flowID = nil end
    if not result.poolID then result.poolID = nil end
    return result
end

function Envelope.Build(input)
    input = type(input) == "table" and input or {}
    local semantic = type(input.semantic) == "table" and input.semantic or {}
    local ir = type(input.ir) == "table" and input.ir or {}
    local source = normalizeSource(input.source or input.kind)
    local act = normalizeAct(sourceField(input, semantic, ir, "act")
        or sourceField(input, semantic, ir, "speechAct")
        or sourceField(input, semantic, ir, "intent")
        or sourceField(input, semantic, ir, "action"))
    local gesture = clean(
        input.gesture or semantic.gesture or input.emoteID, 64
    )
    local eventType = clean(
        input.eventType or semantic.eventType or input.event and input.event.type,
        96
    )
    local topic = clean(
        input.topic or semantic.topic or ir.topic or ir.subject, 96
    )
    local factRefs = boundedList(
        input.factRefs or semantic.factRefs or input.event and input.event.factRefs,
        Lifecycle.LIMITS.factRefs
    )
    local modifiers = boundedCopy(
        input.modifiers or semantic.modifiers or {}, 0
    )
    if not source then return nil, "interaction_source_required" end
    if act == "" then
        if gesture then act = EMOTE_ACTS[string.lower(gesture)] end
        if eventType == "conversation_open" then act = "GREET" end
        if eventType == "conversation_close" then act = "FAREWELL" end
        if source == "world_event" then act = "REACT" end
    end
    if not act or act == "" then return nil, "interaction_act_required" end
    local envelope = {
        schema = Envelope.SCHEMA or Lifecycle.ENVELOPE_SCHEMA,
        schemaVersion = Lifecycle.VERSION,
        source = source,
        actorID = clean(input.actorID or input.actor or semantic.actorID, 96),
        targetID = clean(input.targetID or input.target or semantic.targetID, 96),
        playerUUID = clean(input.playerUUID or semantic.playerUUID, 96),
        act = act,
        topic = topic,
        gesture = gesture,
        eventType = eventType,
        eventRef = clean(
            input.eventRef or input.eventID or input.event and input.event.id,
            128
        ),
        factRefs = factRefs,
        modifiers = modifiers,
        worldHour = finite(input.worldHour or input.occurredAt),
        provenance = provenance(input, act, topic, factRefs),
    }
    return envelope
end

Envelope.SCHEMA = Lifecycle.ENVELOPE_SCHEMA

function Envelope.TypedText(ir, context)
    ir = type(ir) == "table" and ir or {}
    context = type(context) == "table" and context or {}
    return Envelope.Build({
        source = "typed_text",
        ir = ir,
        actorID = context.actorID,
        targetID = context.targetID,
        playerUUID = context.playerUUID,
        topic = ir.topic or context.topic,
        eventType = ir.eventType,
        eventRef = ir.eventRef or ir.eventID,
        factRefs = ir.factRefs,
        modifiers = ir.modifiers,
        worldHour = context.worldHour,
        provenance = context.provenance,
    })
end

function Envelope.SemanticChoice(frame, context)
    frame = type(frame) == "table" and frame or {}
    context = type(context) == "table" and context or {}
    local semantic = type(frame.semantic) == "table" and frame.semantic or {}
    return Envelope.Build({
        source = "semantic_choice",
        semantic = semantic,
        act = frame.act or frame.speechAct,
        topic = frame.topic,
        eventType = frame.eventType or semantic.eventType,
        eventRef = frame.eventRef or frame.eventID,
        actorID = context.actorID,
        targetID = context.targetID,
        playerUUID = context.playerUUID,
        worldHour = context.worldHour,
        provenance = frame.provenance or frame.origin,
    })
end

function Envelope.Emote(emote, context)
    emote = type(emote) == "table" and emote or { gesture = emote }
    context = type(context) == "table" and context or {}
    local gesture = emote.gesture or emote.id or emote.emoteID
    return Envelope.Build({
        source = "emote",
        gesture = gesture,
        act = emote.act or EMOTE_ACTS[string.lower(tostring(gesture or ""))],
        eventType = emote.eventType,
        actorID = context.actorID or emote.actorID,
        targetID = context.targetID or emote.targetID,
        playerUUID = context.playerUUID or emote.playerUUID,
        topic = context.topic,
        eventRef = context.eventRef or emote.eventRef or emote.eventID,
        worldHour = context.worldHour,
        factRefs = emote.factRefs,
        modifiers = emote.modifiers,
    })
end

function Envelope.Lifecycle(eventType, context)
    context = type(context) == "table" and context or {}
    return Envelope.Build({
        source = "conversation_lifecycle",
        eventType = eventType,
        act = context.act,
        actorID = context.actorID,
        targetID = context.targetID,
        playerUUID = context.playerUUID,
        topic = context.topic,
        worldHour = context.worldHour,
        provenance = context.provenance,
    })
end

function Envelope.WorldEvent(event, context)
    event = type(event) == "table" and event or {}
    context = type(context) == "table" and context or {}
    return Envelope.Build({
        source = "world_event",
        act = event.act or "REACT",
        event = event,
        eventType = event.eventType or event.type,
        eventRef = event.eventRef or event.id,
        actorID = context.actorID or event.actorID,
        targetID = context.targetID or event.targetID,
        playerUUID = context.playerUUID or event.playerUUID,
        topic = event.topic or context.topic,
        worldHour = event.occurredAt or context.worldHour,
        factRefs = event.factRefs,
        modifiers = event.modifiers,
    })
end

function Envelope.NPCSpeech(spec)
    spec = type(spec) == "table" and spec or {}
    return Envelope.Build({
        source = "npc_speech",
        act = spec.act or spec.speechAct,
        actorID = spec.actorID or spec.npcID,
        targetID = spec.targetID,
        playerUUID = spec.playerUUID,
        topic = spec.topic,
        beatID = spec.beatID or spec.activeBeat,
        responsePlanID = spec.responsePlanID,
        flowID = spec.flowID,
        poolID = spec.poolID,
        factRefs = spec.factRefs,
        eventType = spec.eventType,
        eventRef = spec.eventRef,
        worldHour = spec.worldHour,
        provenance = spec.provenance,
    })
end

function Envelope.MeaningKey(value)
    local envelope = value
    if type(value) == "table" and value.schema ~= Envelope.SCHEMA then
        envelope = Envelope.Build(value)
    end
    if type(envelope) ~= "table" then return nil end
    local eventType = envelope.source == "world_event"
        and envelope.eventType or ""
    return table.concat({
        tostring(envelope.act or ""),
        tostring(envelope.topic or ""),
        tostring(eventType or ""),
        tostring(envelope.eventRef or ""),
    }, "|")
end

function Envelope.Equivalent(left, right)
    return Envelope.MeaningKey(left) == Envelope.MeaningKey(right)
end

local function pairKey(playerUUID, npcID)
    playerUUID = clean(playerUUID, 96)
    npcID = clean(npcID, 96)
    if not playerUUID or not npcID then return nil end
    return playerUUID .. "|" .. npcID
end

local function listContains(list, value)
    for index = 1, #(list or {}) do
        if list[index] == value then return true end
    end
    return false
end

local function appendUnique(list, value, limit)
    value = clean(value, 128)
    if not value or listContains(list, value) then return false end
    if #list >= limit then table.remove(list, 1) end
    list[#list + 1] = value
    return true
end

local function newThread(playerUUID, npcID, hour)
    local key = pairKey(playerUUID, npcID)
    return {
        id = key,
        playerUUID = playerUUID,
        npcID = npcID,
        status = "ACTIVE",
        topic = nil,
        topicStack = {},
        activeBeat = nil,
        openQuestions = {},
        openCommitments = {},
        recentTurns = {},
        residue = {},
        eventRefs = {},
        memories = {},
        recentRealizations = {},
        startedHour = hour,
        lastHour = hour,
        expiresHour = hour + 72,
        revision = 0,
    }
end

local function copyThread(thread)
    if type(thread) ~= "table" then return nil end
    local result = {
        id = clean(thread.id, 192),
        playerUUID = clean(thread.playerUUID, 96),
        npcID = clean(thread.npcID, 96),
        status = clean(thread.status, 24),
        topic = clean(thread.topic, 96),
        startedHour = finite(thread.startedHour),
        lastHour = finite(thread.lastHour),
        expiresHour = finite(thread.expiresHour),
        residueExpiresHour = finite(thread.residueExpiresHour),
        revision = finite(thread.revision) or 0,
        topicStack = boundedCopy(thread.topicStack or {}, 0, { count = 0 }),
        activeBeat = boundedCopy(thread.activeBeat, 0, { count = 0 }),
        openQuestions = boundedCopy(
            thread.openQuestions or {}, 0, { count = 0 }
        ),
        openCommitments = boundedCopy(
            thread.openCommitments or {}, 0, { count = 0 }
        ),
        recentTurns = boundedCopy(
            thread.recentTurns or {}, 0, { count = 0, limit = 512 }
        ),
        residue = boundedCopy(thread.residue or {}, 0, { count = 0 }),
        eventRefs = boundedCopy(thread.eventRefs or {}, 0, { count = 0 }),
        memories = boundedCopy(thread.memories or {}, 0, { count = 0 }),
        recentRealizations = boundedCopy(
            thread.recentRealizations or {}, 0, { count = 0 }
        ),
    }
    return result
end

local function hasDurableMeaning(thread)
    return thread and (
        thread.activeBeat ~= nil
        or #(thread.topicStack or {}) > 0
        or #(thread.openQuestions or {}) > 0
        or #(thread.openCommitments or {}) > 0
        or #(thread.residue or {}) > 0
        or #(thread.eventRefs or {}) > 0
        or #(thread.memories or {}) > 0
    )
end

local function activeThread(store, key)
    return store.active[key] or store.pairs[key]
end

local removePair

local function expireResidue(thread, hour)
    if not thread or not thread.residueExpiresHour then return false end
    if (tonumber(hour) or 0) <= tonumber(thread.residueExpiresHour) then
        return false
    end
    thread.residue = {}
    thread.residueExpiresHour = nil
    return true
end

local function expireThreadIfNeeded(store, key, hour)
    local thread = activeThread(store, key)
    if thread and thread.expiresHour
        and (tonumber(hour) or 0) > tonumber(thread.expiresHour)
    then
        removePair(store, key)
        store.metrics.expirations = store.metrics.expirations + 1
        return nil
    end
    if thread and expireResidue(thread, hour)
        and store.pairs[key] and store.pairs[key] ~= thread
    then
        store.pairs[key].residue = {}
        store.pairs[key].residueExpiresHour = nil
    end
    return thread
end

local function topicStackIndex(thread, topic)
    if not thread or not topic then return nil end
    for index = #thread.topicStack, 1, -1 do
        local beat = thread.topicStack[index]
        if type(beat) == "table" and beat.topic == topic then
            return index
        end
    end
    return nil
end

removePair = function(store, key)
    if store.pairs[key] then
        store.pairs[key] = nil
        store.metrics.pairRecordsDeleted = store.metrics.pairRecordsDeleted + 1
    end
    store.active[key] = nil
end

local function capThread(thread, store)
    thread.topicStack = type(thread.topicStack) == "table"
        and thread.topicStack or {}
    thread.recentTurns = type(thread.recentTurns) == "table"
        and thread.recentTurns or {}
    thread.openQuestions = type(thread.openQuestions) == "table"
        and thread.openQuestions or {}
    thread.openCommitments = type(thread.openCommitments) == "table"
        and thread.openCommitments or {}
    thread.eventRefs = type(thread.eventRefs) == "table"
        and thread.eventRefs or {}
    thread.memories = type(thread.memories) == "table"
        and thread.memories or {}
    thread.recentRealizations = type(thread.recentRealizations) == "table"
        and thread.recentRealizations or {}
    thread.residue = type(thread.residue) == "table"
        and thread.residue or {}
    local limits = store.limits
    while #thread.topicStack > limits.topicStack do table.remove(thread.topicStack, 1) end
    while #thread.recentTurns > limits.turns do
        table.remove(thread.recentTurns, 1)
        store.metrics.trivialTurnsDiscarded = store.metrics.trivialTurnsDiscarded + 1
    end
    while #thread.openQuestions > limits.openQuestions do table.remove(thread.openQuestions, 1) end
    while #thread.openCommitments > limits.commitments do table.remove(thread.openCommitments, 1) end
    while #thread.eventRefs > limits.eventRefs do table.remove(thread.eventRefs, 1) end
    while #thread.memories > limits.eventRefs do table.remove(thread.memories, 1) end
    while #thread.recentRealizations > limits.realizations do
        table.remove(thread.recentRealizations, 1)
    end
end

function Lifecycle.New(options)
    options = type(options) == "table" and options or {}
    return {
        schema = Lifecycle.SCHEMA,
        schemaVersion = Lifecycle.VERSION,
        authoritative = options.authoritative ~= false,
        worldHour = finite(options.worldHour) or 0,
        limits = boundedCopy(options.limits or Lifecycle.LIMITS, 0),
        active = {},
        pairs = {},
        sharedEvents = {},
        metrics = {
            applied = 0,
            compactions = 0,
            promotions = 0,
            trivialTurnsDiscarded = 0,
            pairRecordsDeleted = 0,
            expirations = 0,
            hydrationCount = 0,
            dormantTickWork = 0,
        },
    }
end

function Lifecycle.RegisterSharedEvent(store, event)
    if type(store) ~= "table" or type(event) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    local eventID = clean(event.eventRef or event.eventID or event.id, 128)
    if not eventID then return nil, "event_reference_required" end
    if not store.sharedEvents[eventID] then
        local count = 0
        for _ in pairs(store.sharedEvents) do count = count + 1 end
        if count >= store.limits.sharedEvents then
            return nil, "shared_event_budget_exhausted"
        end
        store.sharedEvents[eventID] = {
            id = eventID,
            type = clean(event.eventType or event.type, 96),
            topic = clean(event.topic, 96),
            occurredAt = finite(event.occurredAt or event.worldHour),
            source = clean(event.source, 64),
        }
    end
    return eventID, store.sharedEvents[eventID]
end

local function threadTurn(envelope, options, hour)
    return {
        source = envelope.source,
        act = envelope.act,
        topic = envelope.topic,
        gesture = envelope.gesture,
        eventType = envelope.eventType,
        eventRef = envelope.eventRef,
        factRefs = boundedList(envelope.factRefs, Lifecycle.LIMITS.factRefs),
        beatID = clean(
            options and options.beatID or envelope.provenance.beatID,
            96
        ),
        provenance = boundedCopy(envelope.provenance, 0),
        worldHour = hour,
    }
end

local function recordRealization(thread, realizationID, limit)
    realizationID = clean(realizationID, 128)
    if not realizationID then return false end
    return appendUnique(
        thread.recentRealizations,
        realizationID,
        limit
    )
end

function Lifecycle.Apply(store, rawEnvelope, options)
    options = type(options) == "table" and options or {}
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    local envelope, reason = Envelope.Build(rawEnvelope)
    if not envelope then return nil, reason end
    if not envelope.eventRef and options.eventRef then
        envelope.eventRef = clean(options.eventRef, 128)
    end
    local hour = finite(options.worldHour or envelope.worldHour)
        or finite(store.worldHour) or 0
    store.worldHour = math.max(store.worldHour or 0, hour)
    local npcID = envelope.source == "npc_speech"
        and envelope.actorID or envelope.targetID
    local key = pairKey(envelope.playerUUID, npcID)
    if not key then return nil, "pair_identity_required" end
    local thread = expireThreadIfNeeded(store, key, hour)
    if not thread then
        thread = newThread(envelope.playerUUID, npcID, hour)
    end
    expireResidue(thread, hour)
    local previousTopic = thread.topic
    local topic = envelope.topic or options.topic
    local resumeIndex = options.resumeTopic == true
        and topicStackIndex(thread, topic) or nil
    if topic and previousTopic and topic ~= previousTopic
        and thread.activeBeat and not resumeIndex
    then
        if #thread.topicStack >= store.limits.topicStack then
            table.remove(thread.topicStack, 1)
        end
        thread.topicStack[#thread.topicStack + 1] = thread.activeBeat
        thread.activeBeat = nil
        thread.status = "ACTIVE"
    end
    thread.topic = topic or previousTopic
    thread.lastHour = hour
    thread.expiresHour = hour + (finite(options.ttlHours) or 72)
    thread.revision = (tonumber(thread.revision) or 0) + 1
    thread.recentTurns[#thread.recentTurns + 1] = threadTurn(
        envelope, options, hour
    )
    if envelope.eventRef then
        Lifecycle.RegisterSharedEvent(store, {
            id = envelope.eventRef,
            type = envelope.eventType,
            occurredAt = envelope.worldHour,
        })
        appendUnique(thread.eventRefs, envelope.eventRef, store.limits.eventRefs)
    end
    for index = 1, #(envelope.factRefs or {}) do
        appendUnique(thread.memories, envelope.factRefs[index], store.limits.eventRefs)
    end
    if options.openQuestion then
        appendUnique(thread.openQuestions, options.openQuestion, store.limits.openQuestions)
    end
    if options.commitment then
        appendUnique(thread.openCommitments, options.commitment, store.limits.commitments)
    end
    if options.memory then
        appendUnique(thread.memories, options.memory, store.limits.eventRefs)
        store.metrics.promotions = store.metrics.promotions + 1
    end
    if options.residue and type(options.residue) == "table" then
        thread.residue = boundedCopy(options.residue, 0)
        thread.residueExpiresHour = hour
            + (finite(options.residueTTLHours) or 72)
    end
    recordRealization(
        thread,
        options.realizationID or envelope.provenance.poolID,
        store.limits.realizations
    )
    local beatID = clean(options.beatID or envelope.provenance.beatID, 96)
    if beatID then
        thread.activeBeat = {
            id = beatID,
            topic = thread.topic,
            act = envelope.act,
            responsePlanID = envelope.provenance.responsePlanID,
            flowID = envelope.provenance.flowID,
            poolID = envelope.provenance.poolID,
            factRefs = boundedList(envelope.factRefs, store.limits.factRefs),
            expectedReplies = boundedList(options.expectedReplies, 6),
        }
    end
    if options.resolveBeat == true then
        thread.activeBeat = nil
    end
    if resumeIndex then
        thread.activeBeat = table.remove(thread.topicStack, resumeIndex)
        thread.topic = thread.activeBeat.topic or thread.topic
    elseif options.resumeTopic == true and #thread.topicStack > 0
        and not thread.activeBeat
    then
        thread.activeBeat = table.remove(thread.topicStack)
        thread.topic = thread.activeBeat.topic or thread.topic
    end
    capThread(thread, store)
    store.metrics.applied = store.metrics.applied + 1
    local durable = options.meaningful == true or hasDurableMeaning(thread)
    if not durable and options.resolveBeat ~= true then
        removePair(store, key)
        return {
            accepted = true,
            persisted = false,
            reason = "trivial_resolved",
            envelope = envelope,
            thread = nil,
        }
    end
    store.active[key] = thread
    store.pairs[key] = copyThread(thread)
    store.pairs[key].status = thread.status
    return {
        accepted = true,
        persisted = true,
        reason = "meaningful_state",
        envelope = envelope,
        thread = copyThread(thread),
    }
end

function Lifecycle.RecordNPCSpeech(store, spec)
    spec = type(spec) == "table" and spec or {}
    local envelope, reason = Envelope.NPCSpeech(spec)
    if not envelope then return nil, reason end
    local options = boundedCopy(spec, 0) or {}
    options.beatID = spec.beatID or spec.activeBeat
    options.meaningful = spec.meaningful ~= false
    options.expectedReplies = spec.expectedReplies
    options.realizationID = spec.realizationID
    options.worldHour = spec.worldHour
    options.preview = spec.preview
    return Lifecycle.Apply(store, envelope, options)
end

function Lifecycle.Close(store, playerUUID, npcID, options)
    options = type(options) == "table" and options or {}
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    local key = pairKey(playerUUID, npcID)
    local hour = finite(options.worldHour) or store.worldHour or 0
    local thread = key and expireThreadIfNeeded(store, key, hour) or nil
    if not thread then return { accepted = true, persisted = false, reason = "no_thread" } end
    thread.lastHour = hour
    expireResidue(thread, hour)
    if hasDurableMeaning(thread) and options.destroy ~= true then
        thread.status = "SUSPENDED"
        thread.expiresHour = thread.lastHour + (finite(options.ttlHours) or 72)
        capThread(thread, store)
        store.active[key] = thread
        store.pairs[key] = copyThread(thread)
        return { accepted = true, persisted = true, reason = "suspended", thread = copyThread(thread) }
    end
    removePair(store, key)
    return { accepted = true, persisted = false, reason = "trivial_closed" }
end

function Lifecycle.Resume(store, playerUUID, npcID, options)
    options = type(options) == "table" and options or {}
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    local key = pairKey(playerUUID, npcID)
    if not key then return nil, "pair_identity_required" end
    local thread = activeThread(store, key)
    if not thread then return nil, "thread_unavailable" end
    local hour = finite(options.worldHour) or store.worldHour or 0
    if thread.expiresHour and hour > thread.expiresHour then
        removePair(store, key)
        store.metrics.expirations = store.metrics.expirations + 1
        return nil, "thread_expired"
    end
    expireResidue(thread, hour)
    if not hasDurableMeaning(thread) then
        removePair(store, key)
        return nil, "thread_expired"
    end
    thread.status = "ACTIVE"
    thread.lastHour = hour
    thread.revision = (tonumber(thread.revision) or 0) + 1
    store.active[key] = thread
    store.pairs[key] = copyThread(thread)
    store.metrics.hydrationCount = store.metrics.hydrationCount + 1
    return { accepted = true, persisted = true, reason = "resumed", thread = copyThread(thread) }
end

function Lifecycle.Compact(store, playerUUID, npcID, options)
    options = type(options) == "table" and options or {}
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    local key = pairKey(playerUUID, npcID)
    local thread = key and expireThreadIfNeeded(
        store,
        key,
        finite(options.worldHour) or store.worldHour or 0
    ) or nil
    if not thread then return { accepted = true, persisted = false, reason = "no_thread" } end
    local before = #thread.recentTurns
    capThread(thread, store)
    if options.resolveBeat == true then thread.activeBeat = nil end
    if options.clearTrivial == true and not hasDurableMeaning(thread) then
        removePair(store, key)
        store.metrics.compactions = store.metrics.compactions + 1
        return { accepted = true, persisted = false, reason = "empty_after_compaction" }
    end
    store.pairs[key] = copyThread(thread)
    store.metrics.compactions = store.metrics.compactions + 1
    return { accepted = true, persisted = true, reason = "compacted", thread = copyThread(thread) }
end

function Lifecycle.Advance(store, worldHour)
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    worldHour = finite(worldHour)
    if worldHour and worldHour > (store.worldHour or 0) then
        store.worldHour = worldHour
    end
    -- Deliberately no scan. Expiry and residue are derived lazily by Resume,
    -- Apply, Compact or an explicit bounded Maintenance call.
    return { accepted = true, worldHour = store.worldHour, dormantTickWork = 0 }
end

function Lifecycle.Maintenance(store, limit)
    if type(store) ~= "table" then
        return nil, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return nil, "lifecycle_not_authoritative"
    end
    limit = math.max(0, math.floor(tonumber(limit) or 8))
    local inspected = 0
    local expired = 0
    for key, thread in pairs(store.pairs) do
        if inspected >= limit then break end
        inspected = inspected + 1
        if thread.expiresHour and store.worldHour > thread.expiresHour then
            removePair(store, key)
            expired = expired + 1
        end
    end
    store.metrics.expirations = store.metrics.expirations + expired
    return { inspected = inspected, expired = expired, bounded = true }
end

local function approximateSize(value, depth)
    if value == nil then return 0 end
    if type(value) == "string" then return #value end
    if type(value) ~= "table" then return 8 end
    depth = tonumber(depth) or 0
    if depth >= 5 then return 8 end
    local size = 8
    for key, item in pairs(value) do
        size = size + approximateSize(key, depth + 1)
            + approximateSize(item, depth + 1)
    end
    return size
end

function Lifecycle.Metrics(store)
    local active = 0
    local suspended = 0
    local turnCount = 0
    local maximumTurns = 0
    local realizationCount = 0
    local memoryRefCount = 0
    local eventRefCount = 0
    for _, thread in pairs(store.active) do
        active = active + 1
        if thread.status == "SUSPENDED" then suspended = suspended + 1 end
        local count = #(thread.recentTurns or {})
        turnCount = turnCount + count
        maximumTurns = math.max(maximumTurns, count)
        realizationCount = realizationCount
            + #(thread.recentRealizations or {})
        memoryRefCount = memoryRefCount + #(thread.memories or {})
        eventRefCount = eventRefCount + #(thread.eventRefs or {})
    end
    local output = boundedCopy(store.metrics, 0)
    output.activeThreads = active
    output.suspendedThreads = suspended
    output.pairRecords = 0
    for _ in pairs(store.pairs) do output.pairRecords = output.pairRecords + 1 end
    output.recentTurnCount = turnCount
    output.maxRecentTurns = maximumTurns
    output.recentRealizationCount = realizationCount
    output.memoryRefCount = memoryRefCount
    output.eventRefCount = eventRefCount
    output.pairCapsuleBytes = approximateSize(store.pairs)
    output.sharedEventRefs = 0
    for _ in pairs(store.sharedEvents) do output.sharedEventRefs = output.sharedEventRefs + 1 end
    output.dormantTickWork = 0
    output.limits = boundedCopy(store.limits, 0)
    return output
end

function Lifecycle.Project(store, playerUUID, npcID)
    local key = pairKey(playerUUID, npcID)
    local thread = key and expireThreadIfNeeded(store, key, store.worldHour) or nil
    return {
        schema = Lifecycle.SCHEMA,
        playerUUID = clean(playerUUID, 96),
        npcID = clean(npcID, 96),
        thread = thread and copyThread(thread) or nil,
        metrics = Lifecycle.Metrics(store),
    }
end

function Lifecycle.ResponseWindow(store, playerUUID, npcID)
    local key = pairKey(playerUUID, npcID)
    local thread = key and expireThreadIfNeeded(store, key, store.worldHour) or nil
    if not thread then
        return {
            schema = Lifecycle.SCHEMA,
            status = "EMPTY",
            topic = nil,
            activeBeat = nil,
            openQuestions = {},
            commitments = {},
        }
    end
    return {
        schema = Lifecycle.SCHEMA,
        status = thread.status,
        topic = thread.topic,
        activeBeat = thread.activeBeat and boundedCopy(
            thread.activeBeat, 0
        ) or nil,
        openQuestions = boundedCopy(thread.openQuestions or {}, 0),
        commitments = boundedCopy(thread.openCommitments or {}, 0),
        topicStack = boundedCopy(thread.topicStack or {}, 0),
        residue = boundedCopy(thread.residue or {}, 0),
        eventRefs = boundedCopy(thread.eventRefs or {}, 0),
        memories = boundedCopy(thread.memories or {}, 0),
        recentTurns = boundedCopy(
            thread.recentTurns or {}, 0, { count = 0, limit = 512 }
        ),
        recentRealizations = boundedCopy(thread.recentRealizations or {}, 0),
    }
end

function Lifecycle.Export(store)
    local pairCapsules = {}
    local sharedEventCapsules = {}
    local pairCount = 0
    local sharedEventCount = 0
    for key, thread in pairs(store.pairs) do
        if pairCount >= store.limits.pairs then break end
        pairCapsules[key] = copyThread(thread)
        pairCount = pairCount + 1
    end
    for key, event in pairs(store.sharedEvents) do
        if sharedEventCount >= store.limits.sharedEvents then break end
        sharedEventCapsules[key] = boundedCopy(event, 0, { count = 0 })
        sharedEventCount = sharedEventCount + 1
    end
    return {
        schema = Lifecycle.SCHEMA,
        schemaVersion = Lifecycle.VERSION,
        worldHour = store.worldHour,
        pairs = pairCapsules,
        sharedEvents = sharedEventCapsules,
        metrics = Lifecycle.Metrics(store),
    }
end

function Lifecycle.Import(store, payload)
    if type(store) ~= "table" then
        return false, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return false, "lifecycle_not_authoritative"
    end
    if type(payload) ~= "table" or payload.schema ~= Lifecycle.SCHEMA then
        return false, "lifecycle_snapshot_invalid"
    end
    if type(payload.pairs) == "table" then
        store.pairs = {}
        local pairCount = 0
        for key, thread in pairs(payload.pairs) do
            if pairCount >= store.limits.pairs then break end
            if type(thread) == "table"
                and type(thread.playerUUID) == "string"
                and type(thread.npcID) == "string"
            then
                local imported = copyThread(thread)
                capThread(imported, store)
                store.pairs[key] = imported
                pairCount = pairCount + 1
            end
        end
    end
    if type(payload.sharedEvents) == "table" then
        store.sharedEvents = {}
        local eventCount = 0
        for key, event in pairs(payload.sharedEvents) do
            if eventCount >= store.limits.sharedEvents then break end
            if type(event) == "table" then
                store.sharedEvents[key] = boundedCopy(event, 0)
                eventCount = eventCount + 1
            end
        end
    end
    store.worldHour = finite(payload.worldHour) or store.worldHour
    store.active = {}
    for key, thread in pairs(store.pairs) do
        if thread.status ~= "ARCHIVED" then store.active[key] = thread end
    end
    return true
end

Lifecycle.Internal = Lifecycle.Internal or {}
Lifecycle.Internal.PairKey = pairKey
Lifecycle.Internal.HasDurableMeaning = hasDurableMeaning
Lifecycle.Internal.ApproximateSize = approximateSize

return Lifecycle
