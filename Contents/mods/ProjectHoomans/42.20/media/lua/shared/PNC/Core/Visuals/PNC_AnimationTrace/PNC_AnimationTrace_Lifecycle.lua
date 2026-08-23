local Trace = PNC.AnimationTrace
local Internal = Trace.Internal

function Trace.Begin(body, info, now)
    local current
    local trace
    local sample
    if not body then return nil end
    info = type(info) == "table" and info or {}
    if info.debugEnabled ~= true and Trace.forceEnabled ~= true then
        return nil
    end
    now = Internal.NowMillis(now)
    current = Internal.byBody[body]
    if current and current.finishing ~= true
        and (info.attackKey ~= nil
            and tostring(current.attackKey or "") == tostring(info.attackKey)
            or info.attackKey == nil
                and tostring(current.requested or "")
                    == tostring(info.requested or "")
                and (now - current.startedAt) <= 50)
    then
        if info.npcId ~= nil then
            current.npcId = tostring(info.npcId)
            Internal.byNPC[current.npcId] = current
        end
        if info.debugEnabled ~= nil then
            current.debugEnabled = info.debugEnabled == true
        end
        return current
    end
    Internal.sequence = Internal.sequence + 1
    trace = {
        sequence = Internal.sequence,
        npcId = info.npcId ~= nil and tostring(info.npcId) or "unknown",
        attackKey = info.attackKey ~= nil and tostring(info.attackKey) or nil,
        requested = tostring(info.requested or ""),
        resolved = tostring(info.resolved or info.requested or ""),
        topology = tostring(info.topology or Internal.TopologyName()),
        debugEnabled = info.debugEnabled == true or Trace.forceEnabled == true,
        startedAt = now,
        samples = {},
    }
    Internal.byBody[body] = trace
    Internal.byNPC[trace.npcId] = trace
    sample = Internal.Capture(body, "trace_begin", now)
    trace.samples[1] = sample
    trace.lastSignature = Internal.StateSignature(sample)
    return trace
end

function Trace.Ensure(body, info, now)
    local trace = body and Internal.byBody[body] or nil
    if trace and trace.finishing ~= true then return trace end
    return Trace.Begin(body, info, now)
end

function Trace.Sample(body, event, now, force)
    local trace = body and Internal.byBody[body] or nil
    local sample
    local signature
    if not trace then return nil end
    now = Internal.NowMillis(now)
    sample = Internal.Capture(body, event, now)
    signature = Internal.StateSignature(sample)
    if force ~= true and signature == trace.lastSignature then
        -- Keep the first unchanged sample crossing the handoff grace period.
        if trace.failure ~= nil or trace.finishing == true
            or trace.acceptedAt == nil
            or (now - trace.startedAt) < Internal.ACTION_HANDOFF_GRACE_MS
            or Internal.ActionIsBumped(sample)
        then
            return trace
        end
    end
    trace.lastSignature = signature
    trace.samples[#trace.samples + 1] = sample
    if #trace.samples > Internal.MAX_SAMPLES then
        table.remove(trace.samples, 1)
    end
    Internal.Classify(trace, sample)
    return trace
end

function Trace.MarkFinishing(body, event, now)
    local trace = body and Internal.byBody[body] or nil
    if not trace then return nil end
    trace.finishing = true
    return Trace.Sample(body, event or "finish_before", now, true)
end

function Trace.End(body, event, now)
    local trace = body and Internal.byBody[body] or nil
    if not trace then return nil end
    Trace.Sample(body, event or "trace_end", now, true)
    trace.endedAt = Internal.NowMillis(now)
    trace.finishing = true
    return trace
end

return Trace
