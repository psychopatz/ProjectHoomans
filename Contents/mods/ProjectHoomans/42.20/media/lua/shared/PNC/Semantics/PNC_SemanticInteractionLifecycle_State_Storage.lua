PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
local Internal = Lifecycle.Internal or {}
Lifecycle.Internal = Internal

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
    return store.transient and store.transient[key]
        or store.active[key]
        or store.pairs[key]
end

local removePair
local removeTransient

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
    local transient = store.transient and store.transient[key] or nil
    if transient and transient.expiresHour
        and (tonumber(hour) or 0) > tonumber(transient.expiresHour)
    then
        removeTransient(store, key)
        store.metrics.expirations = store.metrics.expirations + 1
        transient = nil
    end
    local thread = transient or store.active[key] or store.pairs[key]
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

removeTransient = function(store, key)
    if store.transient then store.transient[key] = nil end
end

removePair = function(store, key)
    if store.pairs[key] then
        store.pairs[key] = nil
        store.metrics.pairRecordsDeleted = store.metrics.pairRecordsDeleted + 1
    end
    store.active[key] = nil
    removeTransient(store, key)
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
        transient = {},
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

Internal.PairKey = pairKey
Internal.AppendUnique = appendUnique
Internal.NewThread = newThread
Internal.CopyThread = copyThread
Internal.HasDurableMeaning = hasDurableMeaning
Internal.ActiveThread = activeThread
Internal.ExpireResidue = expireResidue
Internal.ExpireThreadIfNeeded = expireThreadIfNeeded
Internal.TopicStackIndex = topicStackIndex
Internal.RemovePair = removePair
Internal.RemoveTransient = removeTransient
Internal.CapThread = capThread

return Lifecycle
