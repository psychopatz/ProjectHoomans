-- Observation-only counters for L6 simulator workloads.
--
-- Counters are taken from exercised production seams: production
-- PerformanceScalingDiagnostics increments and transparent call-count wrappers
-- around production functions. Wrappers always forward arguments and results
-- unchanged, so they never alter the measured runtime path.

local Probe = {}
Probe.__index = Probe

function Probe.New()
    return setmetatable({
        totals = {},
        frame = {},
        maxFrame = {},
        wrapped = {},
        missing = {},
        enabled = false,
    }, Probe)
end

function Probe:Add(name, amount)
    if not self.enabled then return end
    amount = amount or 1
    self.totals[name] = (self.totals[name] or 0) + amount
    self.frame[name] = (self.frame[name] or 0) + amount
end

function Probe:Get(name)
    return self.totals[name] or 0
end

function Probe:MaxFrame(name)
    return self.maxFrame[name] or 0
end

-- Count every production diagnostics increment (path requests, replans,
-- retries, timeouts, stall backoffs, traversal escapes, ...).
function Probe:AttachDiagnostics(diagnostics)
    if not diagnostics or type(diagnostics.Increment) ~= "function" then return end
    local probe = self
    local original = diagnostics.Increment
    diagnostics.Increment = function(name, amount)
        probe:Add("D:" .. tostring(name), tonumber(amount) or 1)
        return original(name, amount)
    end
end

-- Wrap owner[key]; `classify(result...)` may return an extra label suffix.
function Probe:Wrap(owner, key, label, classify)
    local original = owner and owner[key]
    if type(original) ~= "function" then
        self.missing[#self.missing + 1] = label
        return false
    end
    local probe = self
    owner[key] = function(...)
        probe:Add(label)
        if not classify then return original(...) end
        local a, b, c, d = original(...)
        local suffix = classify(a, b, c, d, ...)
        if suffix then probe:Add(label .. "." .. suffix) end
        return a, b, c, d
    end
    self.wrapped[#self.wrapped + 1] = label
    return true
end

-- Count owner[key] calls bucketed by a label derived from the arguments.
function Probe:WrapByArg(owner, key, label, argLabel)
    local original = owner and owner[key]
    if type(original) ~= "function" then
        self.missing[#self.missing + 1] = label
        return false
    end
    local probe = self
    owner[key] = function(...)
        probe:Add(label)
        probe:Add(label .. "." .. tostring(argLabel(...)))
        return original(...)
    end
    return true
end

function Probe:EndFrame()
    for name, value in pairs(self.frame) do
        if value > (self.maxFrame[name] or 0) then self.maxFrame[name] = value end
        self.frame[name] = nil
    end
end

function Probe:Reset()
    self.totals, self.frame, self.maxFrame = {}, {}, {}
end

function Probe.Percentiles(samples)
    local sorted = {}
    local total = 0
    for i = 1, #samples do
        sorted[i] = samples[i]
        total = total + samples[i]
    end
    table.sort(sorted)
    local n = #sorted
    if n == 0 then return { avg = 0, p50 = 0, p95 = 0, max = 0, n = 0 } end
    return {
        avg = total / n,
        p50 = sorted[math.max(1, math.ceil(n * 0.5))],
        p95 = sorted[math.max(1, math.ceil(n * 0.95))],
        max = sorted[n],
        n = n,
        total = total,
    }
end

return Probe
