PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
local Internal = Lifecycle.Internal or {}
Lifecycle.Internal = Internal

local boundedCopy = Internal.BoundedCopy
local clean = Internal.Clean
local pairKey = Internal.PairKey
local expireThreadIfNeeded = Internal.ExpireThreadIfNeeded
local copyThread = Internal.CopyThread

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


return Lifecycle
