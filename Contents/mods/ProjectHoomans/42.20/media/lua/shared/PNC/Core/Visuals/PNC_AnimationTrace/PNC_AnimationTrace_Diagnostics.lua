local Trace = PNC.AnimationTrace
local Internal = Trace.Internal

local function hasRequestedBump(trace, sample)
    local requested = tostring(trace.resolved or "")
    if requested == "" then return sample.bumped == true end
    return sample.bump == requested
        or sample.bumpVariable == requested
        or sample.bumped == true
end

function Internal.ActionIsBumped(sample)
    return string.lower(tostring(sample.actionCurrent ~= ""
        and sample.actionCurrent or sample.action or "")) == "bumped"
end

local function formatSample(trace, sample)
    return "t+" .. tostring(math.max(0,
        (tonumber(sample.at) or 0) - trace.startedAt)) .. "ms"
        .. " event=" .. tostring(sample.event)
        .. " field=" .. tostring(sample.bump ~= "" and sample.bump or "-")
        .. " var=" .. tostring(sample.bumpVariable ~= ""
            and sample.bumpVariable or "-")
        .. " bumped=" .. tostring(sample.bumped)
        .. "/" .. tostring(sample.bumpStaggered)
        .. " action=" .. tostring(sample.action ~= "" and sample.action or "-")
        .. " ctx=" .. tostring(sample.actionCurrent ~= ""
            and sample.actionCurrent or "-")
        .. "<-" .. tostring(sample.actionPrevious ~= ""
            and sample.actionPrevious or "-")
        .. " java=" .. tostring(sample.javaState ~= ""
            and sample.javaState or "-")
        .. " animState=" .. tostring(sample.animationState ~= ""
            and sample.animationState or "-")
        .. " done=" .. tostring(sample.bumpDone)
        .. "/" .. tostring(sample.bumpDoneVariable)
        .. "/" .. tostring(sample.animFinished)
        .. " useless=" .. tostring(sample.useless)
        .. " move=" .. tostring(sample.moving)
        .. " sneak=" .. tostring(sample.sneaking)
        .. " path2=" .. tostring(sample.path2)
        .. " local=" .. tostring(sample.localBody)
        .. " lease=" .. tostring(sample.lease)
        .. " release=" .. tostring(sample.releasePending)
end

function Internal.DumpLines(trace)
    local lines = {}
    local i
    if not trace then return { "[PNC][ANIMTRACE] no retained trace" } end
    lines[1] = "[PNC][ANIMTRACE] #" .. tostring(trace.sequence)
        .. " npc=" .. tostring(trace.npcId or "unknown")
        .. " topology=" .. tostring(trace.topology)
        .. " key=" .. tostring(trace.attackKey or "-")
        .. " req=" .. tostring(trace.requested or "-")
        .. " resolved=" .. tostring(trace.resolved or "-")
        .. " accepted=" .. tostring(trace.acceptedAt ~= nil)
        .. " failure=" .. tostring(trace.failure or "-")
        .. " failureEvent=" .. tostring(trace.failureEvent or "-")
    for i = 1, #trace.samples do
        lines[#lines + 1] = "[PNC][ANIMTRACE] "
            .. formatSample(trace, trace.samples[i])
    end
    return lines
end

function Internal.EmitLines(lines)
    local i
    for i = 1, #lines do
        if PNC.Core and PNC.Core.Log then
            PNC.Core.Log("WARN", lines[i])
        else
            print(lines[i])
        end
    end
end

local function setFailure(trace, kind, sample)
    local key
    if trace.failure then return end
    trace.failure = tostring(kind)
    trace.failureAt = sample.at
    trace.failureEvent = sample.event
    if trace.debugEnabled ~= true then return end
    key = tostring(trace.npcId or "unknown") .. "|" .. trace.failure
    if Internal.autoDumped[key] then return end
    Internal.autoDumped[key] = true
    Internal.EmitLines(Internal.DumpLines(trace))
end

function Internal.Classify(trace, sample)
    local age
    local acceptedNow
    if trace.finishing == true then return end
    acceptedNow = hasRequestedBump(trace, sample)
    if acceptedNow and trace.acceptedAt == nil then
        trace.acceptedAt = sample.at
        trace.acceptedEvent = sample.event
    end
    if sample.event == "setter_after" and not acceptedNow then
        setFailure(trace, "setter_rejected", sample)
        return
    end
    if trace.acceptedAt ~= nil and not acceptedNow
        and not Internal.ActionIsBumped(sample)
    then
        setFailure(trace, "bump_cleared_after_set", sample)
        return
    end
    age = sample.at - trace.startedAt
    if trace.acceptedAt ~= nil
        and age >= Internal.ACTION_HANDOFF_GRACE_MS
        and not Internal.ActionIsBumped(sample)
    then
        setFailure(trace, "action_handoff_missing", sample)
    end
end

return Trace
