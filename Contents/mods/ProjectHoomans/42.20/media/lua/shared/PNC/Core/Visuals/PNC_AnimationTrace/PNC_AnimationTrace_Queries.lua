local Trace = PNC.AnimationTrace
local Internal = Trace.Internal

function Trace.Get(body)
    return body and Internal.byBody[body] or nil
end

function Trace.GetOverlayLine(body)
    local trace = body and Internal.byBody[body] or nil
    local sample
    local age
    if not trace or #trace.samples == 0 then return nil end
    sample = trace.samples[#trace.samples]
    age = math.max(0,
        (tonumber(trace.endedAt) or Internal.NowMillis()) - trace.startedAt)
    return "TRACE #" .. tostring(trace.sequence)
        .. " age=" .. tostring(age) .. "ms"
        .. " last=" .. tostring(sample.event)
        .. " field/var=" .. tostring(sample.bump ~= ""
            and sample.bump or "-")
        .. "/" .. tostring(sample.bumpVariable ~= ""
            and sample.bumpVariable or "-")
        .. " bumped=" .. tostring(sample.bumped)
        .. "/" .. tostring(sample.bumpStaggered)
        .. " ctx=" .. tostring(sample.actionCurrent ~= ""
            and sample.actionCurrent
            or sample.action ~= "" and sample.action or "-")
        .. " java=" .. tostring(sample.javaState ~= ""
            and sample.javaState or "-")
        .. " anim=" .. tostring(sample.animationState ~= ""
            and sample.animationState or "-")
        .. " fail=" .. tostring(trace.failure or "-")
        .. (trace.failureEvent and "@" .. tostring(trace.failureEvent) or "")
end

function Trace.DumpBody(body)
    local lines = Internal.DumpLines(body and Internal.byBody[body] or nil)
    Internal.EmitLines(lines)
    return lines
end

function Trace.DumpNPC(npcId)
    local lines = Internal.DumpLines(
        Internal.byNPC[tostring(npcId or "")]
    )
    Internal.EmitLines(lines)
    return lines
end

function Trace.DumpAll()
    local traces = {}
    local seen = {}
    local lines = {}
    local _, trace
    local i
    local traceLines
    for _, trace in pairs(Internal.byNPC) do
        if trace and not seen[trace] then
            seen[trace] = true
            traces[#traces + 1] = trace
        end
    end
    table.sort(traces, function(left, right)
        return left.sequence < right.sequence
    end)
    for i = 1, #traces do
        traceLines = Internal.DumpLines(traces[i])
        for _, line in ipairs(traceLines) do
            lines[#lines + 1] = line
        end
    end
    if #lines == 0 then
        lines[1] = "[PNC][ANIMTRACE] no retained traces"
    end
    Internal.EmitLines(lines)
    return lines
end

function Trace.Reset()
    Internal.byBody = setmetatable({}, { __mode = "k" })
    Internal.byNPC = {}
    Internal.autoDumped = {}
end

function Trace.SetEnabled(enabled)
    Trace.forceEnabled = enabled == true
    return Trace.forceEnabled
end

return Trace
