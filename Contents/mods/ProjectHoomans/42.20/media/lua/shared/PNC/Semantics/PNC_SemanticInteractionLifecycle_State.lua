-- Mutable semantic interaction lifecycle state owner.
--
-- This spoke owns thread state, bounded retention, compaction, metrics and
-- snapshot import/export. Envelope construction remains in the preceding
-- envelope spoke and all public methods stay attached to Lifecycle.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
local Internal = Lifecycle.Internal or {}
Lifecycle.Internal = Internal

local Envelope = Lifecycle.Envelope or {}
local clean = Internal.Clean
local finite = Internal.Finite
local boundedCopy = Internal.BoundedCopy
local boundedList = Internal.BoundedList

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
