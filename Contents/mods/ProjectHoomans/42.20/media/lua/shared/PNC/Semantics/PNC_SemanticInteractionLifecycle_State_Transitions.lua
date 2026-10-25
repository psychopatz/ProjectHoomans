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
local appendUnique = Internal.AppendUnique
local pairKey = Internal.PairKey
local newThread = Internal.NewThread
local copyThread = Internal.CopyThread
local activeThread = Internal.ActiveThread
local expireResidue = Internal.ExpireResidue
local expireThreadIfNeeded = Internal.ExpireThreadIfNeeded
local topicStackIndex = Internal.TopicStackIndex
local removePair = Internal.RemovePair
local capThread = Internal.CapThread
local hasDurableMeaning = Internal.HasDurableMeaning

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

return Lifecycle
