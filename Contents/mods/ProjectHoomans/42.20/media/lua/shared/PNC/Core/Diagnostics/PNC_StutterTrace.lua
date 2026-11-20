-- Off-by-default, bounded, allocation-light stutter diagnostic ring for
-- native SP/MP correlation without deep profiler wrappers.
--
-- Observational only: when Enabled ~= true, callers pay only a boolean check.
-- When enabled, reuses pre-allocated ring slots to capture top-level per-tick
-- counters and retains short pre-spike -> spike -> post-spike windows whenever
-- a tick meets or exceeds ThresholdMs.

PNC = PNC or {}
PNC.StutterTrace = PNC.StutterTrace or {}

local Trace = PNC.StutterTrace

Trace.Enabled = Trace.Enabled == true
Trace.ThresholdMs = tonumber(Trace.ThresholdMs) or 16
Trace.RingCapacity = 32
Trace.PreWindowFrames = 3
Trace.PostWindowFrames = 3
Trace.MaxSpikeWindows = 8

local COUNTER_FIELDS = {
    "movingFollowers",
    "activePaths",
    "pathRequests",
    "replans",
    "materializations",
    "abstractions",
    "hitGates",
    "acceptedHits",
    "reactionOps",
    "woundMutations",
    "witnessScans",
    "factionSocialOps",
    "inventoryMutations",
    "inventorySerOps",
    "networkSends",
    "persistenceOps",
    "censusRefreshes",
}

local function newSlot()
    local slot = {
        at = 0,
        serverUpdateMs = 0,
    }
    for i = 1, #COUNTER_FIELDS do
        slot[COUNTER_FIELDS[i]] = 0
    end
    return slot
end

local function clearSlot(slot, now)
    slot.at = tonumber(now) or 0
    slot.serverUpdateMs = 0
    for i = 1, #COUNTER_FIELDS do
        slot[COUNTER_FIELDS[i]] = 0
    end
end

local function copySlot(src)
    local dst = {
        at = src.at,
        serverUpdateMs = src.serverUpdateMs,
    }
    for i = 1, #COUNTER_FIELDS do
        local k = COUNTER_FIELDS[i]
        dst[k] = src[k] or 0
    end
    return dst
end

local function ensureState()
    if Trace._ring then return end
    Trace._ring = {}
    for i = 1, Trace.RingCapacity do
        Trace._ring[i] = newSlot()
    end
    Trace._head = 0
    Trace._count = 0
    Trace._activeSlot = nil
    Trace._activeStartMs = 0
    Trace._prevCounters = {}
    Trace._spikeWindows = {}
    Trace._pendingPost = {}
end

local function clockMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.clock then return os.clock() * 1000 end
    return 0
end

local function readCumulativeCounters(out)
    local diag = PNC.PerformanceScalingDiagnostics
    local c = diag and diag.Counters or {}
    local pres = PNC.Presence and PNC.Presence.Metrics or {}
    local coord = PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Metrics or {}
    local reg = PNC.Registry and PNC.Registry.PersistenceMetrics or {}
    out.pathRequests = (tonumber(c["Pathing.EnginePathRequests"]) or 0)
        + (tonumber(c["Pathing.PathRequests"]) or 0)
    out.replans = tonumber(c["Pathing.Replans"]) or 0
    out.materializations = tonumber(pres.materializeSuccesses) or 0
    out.abstractions = tonumber(pres.abstractSuccesses) or 0
    out.networkSends = tonumber(c["Network.PayloadBudgetSends"]) or 0
    out.persistenceOps = (tonumber(coord.pumpRuns) or 0)
        + (tonumber(reg.written) or 0)
    out.censusRefreshes = tonumber(PNC.WorldCensus and PNC.WorldCensus.Generation) or 0
    out.inventoryMutations = tonumber(c["deltaInventoryMutations"]) or 0
end

function Trace.Reset()
    Trace._ring = nil
    ensureState()
end

function Trace.SetEnabled(enabled, thresholdMs)
    ensureState()
    Trace.Enabled = enabled == true
    if thresholdMs ~= nil then
        Trace.ThresholdMs = math.max(1, tonumber(thresholdMs) or Trace.ThresholdMs)
    end
    if Trace.Enabled then
        readCumulativeCounters(Trace._prevCounters)
    end
    return Trace.Enabled
end

function Trace.Record(field, amount)
    if Trace.Enabled ~= true then return end
    local slot = Trace._activeSlot
    if not slot then return end
    if slot[field] ~= nil then
        slot[field] = slot[field] + (tonumber(amount) or 1)
    end
end

function Trace.BeginTick(now)
    if Trace.Enabled ~= true then return end
    ensureState()
    Trace._head = (Trace._head % Trace.RingCapacity) + 1
    if Trace._count < Trace.RingCapacity then
        Trace._count = Trace._count + 1
    end
    local slot = Trace._ring[Trace._head]
    clearSlot(slot, now)
    Trace._activeSlot = slot
    Trace._activeStartMs = clockMs()
    readCumulativeCounters(Trace._prevCounters)
end

function Trace.EndTick(now, durationOverrideMs)
    if Trace.Enabled ~= true then return end
    local slot = Trace._activeSlot
    if not slot then return end
    Trace._activeSlot = nil

    local elapsed = durationOverrideMs ~= nil
        and (tonumber(durationOverrideMs) or 0)
        or math.max(0, clockMs() - (Trace._activeStartMs or 0))
    slot.serverUpdateMs = elapsed

    local cur = {}
    readCumulativeCounters(cur)
    local prev = Trace._prevCounters
    for k, v in pairs(cur) do
        local delta = v - (tonumber(prev[k]) or 0)
        if delta > 0 then
            slot[k] = (slot[k] or 0) + delta
        end
        prev[k] = v
    end

    -- Append post-spike frames to any open spike windows.
    local remaining = {}
    for i = 1, #Trace._pendingPost do
        local win = Trace._pendingPost[i]
        win.post[#win.post + 1] = copySlot(slot)
        if #win.post < Trace.PostWindowFrames then
            remaining[#remaining + 1] = win
        end
    end
    Trace._pendingPost = remaining

    -- Capture a new pre -> spike -> post window if threshold exceeded.
    if elapsed >= (tonumber(Trace.ThresholdMs) or 16) then
        local pre = {}
        local preCount = math.min(Trace.PreWindowFrames, Trace._count - 1)
        for back = preCount, 1, -1 do
            local idx = ((Trace._head - 1 - back) % Trace.RingCapacity) + 1
            pre[#pre + 1] = copySlot(Trace._ring[idx])
        end
        local win = {
            thresholdMs = Trace.ThresholdMs,
            pre = pre,
            spike = copySlot(slot),
            post = {},
        }
        Trace._spikeWindows[#Trace._spikeWindows + 1] = win
        while #Trace._spikeWindows > Trace.MaxSpikeWindows do
            table.remove(Trace._spikeWindows, 1)
        end
        if Trace.PostWindowFrames > 0 then
            Trace._pendingPost[#Trace._pendingPost + 1] = win
        end
    end
end

function Trace.GetRecentFrames(limit)
    ensureState()
    local n = math.min(tonumber(limit) or Trace._count, Trace._count)
    local out = {}
    for back = n - 1, 0, -1 do
        local idx = ((Trace._head - 1 - back) % Trace.RingCapacity) + 1
        out[#out + 1] = copySlot(Trace._ring[idx])
    end
    return out
end

function Trace.GetSpikeWindows()
    ensureState()
    return Trace._spikeWindows
end

function Trace.FormatRecentSpikes()
    ensureState()
    local lines = {}
    for i = 1, #Trace._spikeWindows do
        local w = Trace._spikeWindows[i]
        local s = w.spike
        lines[#lines + 1] = string.format(
            "spike#%d at=%d ms=%.2f pre=%d post=%d pathReq=%d replans=%d mat=%d abs=%d hits=%d wounds=%d wit=%d net=%d pers=%d census=%d",
            i, tonumber(s.at) or 0, tonumber(s.serverUpdateMs) or 0,
            #w.pre, #w.post,
            s.pathRequests or 0, s.replans or 0,
            s.materializations or 0, s.abstractions or 0,
            s.acceptedHits or 0, s.woundMutations or 0,
            s.witnessScans or 0, s.networkSends or 0,
            s.persistenceOps or 0, s.censusRefreshes or 0
        )
    end
    return table.concat(lines, "\n")
end

return Trace
