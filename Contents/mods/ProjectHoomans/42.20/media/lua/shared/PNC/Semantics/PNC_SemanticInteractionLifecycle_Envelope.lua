-- Pure semantic interaction envelope contract.
--
-- This spoke normalizes bounded meaning and provenance. It does not own
-- mutable lifecycle state, persistence, compaction, or authority decisions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
local Internal = Lifecycle.Internal or {}
Lifecycle.Internal = Internal

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
        responsePlanID = spec.responsePlanID,
        flowID = spec.flowID,
        poolID = spec.poolID,
        realizationFamily = spec.realizationFamily,
        realizationID = spec.realizationID,
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

Internal.Clean = clean
Internal.Finite = finite
Internal.BoundedCopy = boundedCopy
Internal.BoundedList = boundedList

return Lifecycle
