local Trace = PNC.AnimationTrace
local Internal = Trace.Internal

local function clearBodyReference(trace)
    for body, candidate in pairs(Internal.byBody) do
        if candidate == trace then
            Internal.byBody[body] = nil
        end
    end
end

local function retainedTraceCount()
    local count = 0
    for _, trace in pairs(Internal.byNPC) do
        if trace then count = count + 1 end
    end
    return count
end

local function evictOldestTrace()
    local oldestId
    local oldestTrace
    for npcId, trace in pairs(Internal.byNPC) do
        if trace and (not oldestTrace
            or trace.sequence < oldestTrace.sequence)
        then
            oldestId = npcId
            oldestTrace = trace
        end
    end
    if not oldestTrace then return false end
    Internal.byNPC[oldestId] = nil
    clearBodyReference(oldestTrace)
    return true
end

local function retainByNPC(npcId, trace)
    local traceId = tostring(npcId or "unknown")
    local existing = Internal.byNPC[traceId]
    local count
    if existing == trace then return end
    if existing then
        clearBodyReference(existing)
    else
        count = retainedTraceCount()
        while count >= Internal.MAX_RETAINED_TRACES do
            if not evictOldestTrace() then break end
            count = count - 1
        end
    end
    Internal.byNPC[traceId] = trace
end

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
            local previousNpcId = current.npcId
            current.npcId = tostring(info.npcId)
            if previousNpcId ~= current.npcId
                and Internal.byNPC[previousNpcId] == current
            then
                Internal.byNPC[previousNpcId] = nil
            end
        end
        retainByNPC(current.npcId, current)
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
    sample = Internal.Capture(body, "trace_begin", now)
    trace.samples[1] = sample
    trace.lastSignature = Internal.StateSignature(sample)
    retainByNPC(trace.npcId, trace)
    return trace
end

function Trace.Ensure(body, info, now)
    local trace = body and Internal.byBody[body] or nil
    if trace and trace.finishing ~= true then return trace end
    return Trace.Begin(body, info, now)
end

function Trace.ExpectRearmSelectorClear(body)
    local trace = body and Internal.byBody[body] or nil
    if not trace or trace.finishing == true then return false end
    trace.expectedRearmSelectorClear = true
    return true
end

function Trace.Sample(body, event, now, force)
    local trace = body and Internal.byBody[body] or nil
    local sample
    local signature
    if not trace then return nil end
    now = Internal.NowMillis(now)
    sample = Internal.Capture(body, event, now)
    if trace.expectedRearmSelectorClear then
        trace.expectedRearmSelectorClear = nil
        if event == "setter_before" then
            sample.expectedRearmSelectorClear = true
        end
    end
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
