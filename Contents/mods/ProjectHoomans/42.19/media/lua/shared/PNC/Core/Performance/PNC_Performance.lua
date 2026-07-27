-- Lightweight, runtime-only performance counters. They never enter save data
-- and only collect timings while the global PNC debug switch is enabled.

PNC = PNC or {}
PNC.Performance = PNC.Performance or {}

local Performance = PNC.Performance
local Core = PNC.Core

Performance.Counters = Performance.Counters or {}
Performance.Gauges = Performance.Gauges or {}
Performance.Timings = Performance.Timings or {}
Performance.EnabledUntil = tonumber(Performance.EnabledUntil) or 0

function Performance.IsEnabled()
    return PNC.Runtime and (
        PNC.Runtime.debugEnabled == true
        or PNC.Runtime.performanceEnabled == true
    ) or Performance.EnabledUntil > 0
        and Core.Now() < Performance.EnabledUntil
end

function Performance.Enable(durationMs)
    local duration = math.max(1000, tonumber(durationMs) or 60000)
    Performance.EnabledUntil = Core.Now() + duration
    return Performance.EnabledUntil
end

function Performance.Disable()
    Performance.EnabledUntil = 0
    if PNC.Runtime then
        PNC.Runtime.performanceEnabled = false
    end
end

function Performance.Count(name, amount)
    if not Performance.IsEnabled() then return end
    name = tostring(name or "unknown")
    Performance.Counters[name] = (tonumber(Performance.Counters[name]) or 0)
        + (tonumber(amount) or 1)
end

function Performance.SetGauge(name, value)
    if not Performance.IsEnabled() then return end
    Performance.Gauges[tostring(name or "unknown")] = tonumber(value) or 0
end

function Performance.Begin()
    if not Performance.IsEnabled() then return nil end
    return Core.Now()
end

function Performance.Finish(name, startedAt)
    local elapsed
    local entry
    if startedAt == nil or not Performance.IsEnabled() then return end
    elapsed = math.max(0, Core.Now() - (tonumber(startedAt) or Core.Now()))
    name = tostring(name or "unknown")
    entry = Performance.Timings[name] or {
        calls = 0,
        totalMs = 0,
        maxMs = 0,
    }
    entry.calls = entry.calls + 1
    entry.totalMs = entry.totalMs + elapsed
    entry.maxMs = math.max(entry.maxMs, elapsed)
    Performance.Timings[name] = entry
end

function Performance.Snapshot(reset)
    local snapshot = {
        counters = {},
        gauges = {},
        timings = {},
    }
    local key
    local value
    for key, value in pairs(Performance.Counters) do
        snapshot.counters[key] = value
    end
    for key, value in pairs(Performance.Gauges) do
        snapshot.gauges[key] = value
    end
    for key, value in pairs(Performance.Timings) do
        snapshot.timings[key] = {
            calls = value.calls,
            totalMs = value.totalMs,
            maxMs = value.maxMs,
        }
    end
    if reset == true then
        Performance.Counters = {}
        Performance.Gauges = {}
        Performance.Timings = {}
    end
    return snapshot
end
