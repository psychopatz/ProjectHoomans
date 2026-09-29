-- Build pipeline tracing facade.
--
-- The authoritative gate, counters, and console sink live in
-- PNC.PerformanceScalingDiagnostics (registered with PsychopatzCore's central
-- DebugSettings as "Project Hoomans -> Build pipeline audit"). This module is
-- the single entry point build code uses so the disabled path stays a cheap
-- boolean read and every stage shares one correlation id and clock.
--
-- Usage:
--   if BuildAudit.Enabled() then
--       BuildAudit.Log("placement_cancel", { "reason=" .. tostring(reason) })
--   end
--
-- Never assemble fields outside the guard: the whole point of the gate is that
-- a normal session pays nothing for it.

PNC = PNC or {}
PNC.BuildAudit = PNC.BuildAudit or {}

local BuildAudit = PNC.BuildAudit

local function diagnostics()
    return PNC.PerformanceScalingDiagnostics
end

function BuildAudit.Enabled()
    local channel = diagnostics()
    return channel ~= nil and channel.BuildAuditEnabled == true
end

function BuildAudit.Log(stage, fields)
    local channel = diagnostics()
    if not channel or channel.BuildAuditEnabled ~= true then return false end
    if type(channel.LogBuildAudit) ~= "function" then return false end
    return channel.LogBuildAudit(stage, fields)
end

--[[
    Always-available one-line lifecycle trace.

    The CommandHub trace sink is already on and already carries Base-window
    events (pnc_base_open_*), so user-triggered build lifecycle transitions go
    there: a handful of lines per click, never per frame.

    Resolve the sink defensively. PNC.CommandHub is Project Hoomans' own table
    and does NOT expose Trace - only PsychopatzCore's hub does - so looking up
    the wrong table silently discarded every line, which is worse than not
    tracing at all. Fall back to print() so a trace is never swallowed.
]]
local function traceSink()
    local core = PsychopatzCore
    local hub = core and core.CommandHub or nil
    if type(hub) ~= "table" or type(hub.Trace) ~= "function" then
        hub = core and core.UI and core.UI.CommandHub or nil
    end
    if type(hub) == "table" and type(hub.Trace) == "function" then
        return hub
    end
    if type(print) == "function" then
        return { Trace = function(event, message)
            print("[PNC][BUILD] " .. tostring(event)
                .. (message and " | " .. tostring(message) or ""))
            return true
        end }
    end
    return nil
end

function BuildAudit.Trace(event, message)
    local hub = traceSink()
    if not hub then return false end
    return hub.Trace(event, message) and true or false
end

function BuildAudit.TracePlacement(event, fields)
    local parts = {}
    for _, field in ipairs(fields or {}) do
        parts[#parts + 1] = tostring(field)
    end
    return BuildAudit.Trace(event,
        #parts > 0 and table.concat(parts, " ") or nil)
end

-- Monotonic millisecond clock that stays 0 when the engine global is absent
-- (isolated smoke tests), so a trace line never fails to render.
function BuildAudit.NowMs()
    local channel = diagnostics()
    if channel and type(channel.BuildAuditNowMs) == "function" then
        return channel.BuildAuditNowMs()
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

function BuildAudit.TraceId()
    local channel = diagnostics()
    if channel and type(channel.NextBuildTraceId) == "function" then
        return channel.NextBuildTraceId()
    end
    return "build?"
end

function BuildAudit.MarkSent(requestId)
    local channel = diagnostics()
    if not channel or channel.BuildAuditEnabled ~= true then return false end
    if type(channel.MarkBuildRequestSent) ~= "function" then return false end
    return channel.MarkBuildRequestSent(requestId)
end

function BuildAudit.ElapsedMs(requestId)
    local channel = diagnostics()
    if not channel or type(channel.BuildRequestElapsedMs) ~= "function" then
        return nil
    end
    return channel.BuildRequestElapsedMs(requestId)
end

-- Shared field builders keep the line format stable across the client and the
-- server halves of the same trace.
function BuildAudit.RequestField(traceId)
    return "req=" .. tostring(traceId or "?")
end

function BuildAudit.ElapsedField(requestId, label)
    local elapsed = BuildAudit.ElapsedMs(requestId)
    if elapsed == nil then return tostring(label or "ms") .. "=?" end
    return tostring(label or "ms") .. "=" .. tostring(math.floor(elapsed))
end

return BuildAudit
