--[[
    PNC Animation Trace
    Retained, transition-only diagnostics for the IsoZombie bump/action graph.

    This deliberately does not repair or replay animations. Its job is to show
    whether a request failed at the Java BumpType setter, the ActionContext
    transition into "bumped", or the animation-node selection that follows.
]]

PNC = PNC or {}
PNC.AnimationTrace = PNC.AnimationTrace or {}

local Trace = PNC.AnimationTrace
local Core = PNC.Core

local MAX_SAMPLES = 48
local ACTION_HANDOFF_GRACE_MS = 180
local AUTO_DUMPED = {}
local BY_BODY = setmetatable({}, { __mode = "k" })
local BY_NPC = {}
local sequence = 0
Trace.forceEnabled = Trace.forceEnabled == true

local function nowMillis(now)
    return tonumber(now)
        or Core and Core.Now and Core.Now()
        or 0
end

local function textMethod(object, methodName)
    local method = object and object[methodName] or nil
    if not method then return "" end
    return tostring(method(object) or "")
end

local function boolMethod(object, methodName)
    local method = object and object[methodName] or nil
    return method and method(object) == true or false
end

local function variableText(body, name)
    if body and body.getVariableString then
        return tostring(body:getVariableString(name) or "")
    end
    return ""
end

local function variableBoolean(body, name)
    return body
        and body.getVariableBoolean
        and body:getVariableBoolean(name) == true
        or false
end

local function primaryItemType(body)
    local item = body
        and body.getPrimaryHandItem
        and body:getPrimaryHandItem()
        or nil
    if not item then return "" end
    if item.getFullType then
        return tostring(item:getFullType() or "")
    end
    if item.getType then
        return tostring(item:getType() or "")
    end
    return tostring(item)
end

local function topologyName()
    if isClient and isClient() == true then return "client" end
    if isServer and isServer() == true then return "server" end
    return "singleplayer"
end

local function capture(body, event, now)
    local modData = body
        and body.getModData
        and body:getModData()
        or nil
    return {
        at = now,
        event = tostring(event or "sample"),
        bump = textMethod(body, "getBumpType"),
        bumpVariable = variableText(body, "BumpType"),
        bumped = boolMethod(body, "isBumped"),
        bumpStaggered = boolMethod(body, "isBumpStaggered"),
        bumpDone = boolMethod(body, "isBumpDone"),
        bumpDoneVariable = variableBoolean(body, "BumpDone"),
        animFinished = variableBoolean(
            body,
            "BumpAnimFinished"
        ),
        action = textMethod(body, "getActionStateName"),
        actionCurrent = textMethod(
            body,
            "getCurrentActionContextStateName"
        ),
        actionPrevious = textMethod(
            body,
            "getPreviousActionContextStateName"
        ),
        javaState = textMethod(body, "getCurrentStateName"),
        animationState = textMethod(
            body,
            "getAnimationStateName"
        ),
        pncActor = variableBoolean(body, "PNCActor"),
        moving = boolMethod(body, "isMoving"),
        sneaking = boolMethod(body, "isSneaking"),
        useless = boolMethod(body, "isUseless"),
        localBody = boolMethod(body, "isLocal"),
        path2 = body and body.getPath2
            and body:getPath2() ~= nil
            or false,
        primary = primaryItemType(body),
        lease = modData
            and modData.PNC_BumpActionLease == true
            or false,
        releasePending = modData
            and modData.PNC_BumpReleasePending == true
            or false,
    }
end

local function stateSignature(sample)
    return table.concat({
        sample.bump,
        sample.bumpVariable,
        tostring(sample.bumped),
        tostring(sample.bumpStaggered),
        tostring(sample.bumpDone),
        tostring(sample.bumpDoneVariable),
        tostring(sample.animFinished),
        sample.action,
        sample.actionCurrent,
        sample.actionPrevious,
        sample.javaState,
        sample.animationState,
        tostring(sample.pncActor),
        tostring(sample.moving),
        tostring(sample.sneaking),
        tostring(sample.useless),
        tostring(sample.localBody),
        tostring(sample.path2),
        sample.primary,
        tostring(sample.lease),
        tostring(sample.releasePending),
    }, "|")
end

local function hasRequestedBump(trace, sample)
    local requested = tostring(trace.resolved or "")
    if requested == "" then return sample.bumped == true end
    return sample.bump == requested
        or sample.bumpVariable == requested
        or sample.bumped == true
end

local function actionIsBumped(sample)
    return string.lower(tostring(
        sample.actionCurrent ~= ""
            and sample.actionCurrent
            or sample.action
            or ""
    )) == "bumped"
end

local function formatSample(trace, sample)
    return "t+" .. tostring(
        math.max(0, (tonumber(sample.at) or 0) - trace.startedAt)
    ) .. "ms"
        .. " event=" .. tostring(sample.event)
        .. " field=" .. tostring(
            sample.bump ~= "" and sample.bump or "-"
        )
        .. " var=" .. tostring(
            sample.bumpVariable ~= ""
                and sample.bumpVariable
                or "-"
        )
        .. " bumped=" .. tostring(sample.bumped)
        .. "/" .. tostring(sample.bumpStaggered)
        .. " action=" .. tostring(
            sample.action ~= "" and sample.action or "-"
        )
        .. " ctx=" .. tostring(
            sample.actionCurrent ~= ""
                and sample.actionCurrent
                or "-"
        )
        .. "<-" .. tostring(
            sample.actionPrevious ~= ""
                and sample.actionPrevious
                or "-"
        )
        .. " java=" .. tostring(
            sample.javaState ~= "" and sample.javaState or "-"
        )
        .. " animState=" .. tostring(
            sample.animationState ~= ""
                and sample.animationState
                or "-"
        )
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

local function dumpLines(trace)
    local lines = {}
    local i
    if not trace then
        return { "[PNC][ANIMTRACE] no retained trace" }
    end
    lines[1] = "[PNC][ANIMTRACE] #"
        .. tostring(trace.sequence)
        .. " npc=" .. tostring(trace.npcId or "unknown")
        .. " topology=" .. tostring(trace.topology)
        .. " key=" .. tostring(trace.attackKey or "-")
        .. " req=" .. tostring(trace.requested or "-")
        .. " resolved=" .. tostring(trace.resolved or "-")
        .. " accepted=" .. tostring(trace.acceptedAt ~= nil)
        .. " failure=" .. tostring(trace.failure or "-")
        .. " failureEvent=" .. tostring(
            trace.failureEvent or "-"
        )
    for i = 1, #trace.samples do
        lines[#lines + 1] =
            "[PNC][ANIMTRACE] " .. formatSample(
                trace,
                trace.samples[i]
            )
    end
    return lines
end

local function emitLines(lines)
    local i
    for i = 1, #lines do
        if Core and Core.Log then
            Core.Log("WARN", lines[i])
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
    key = tostring(trace.npcId or "unknown")
        .. "|" .. trace.failure
    if AUTO_DUMPED[key] then return end
    AUTO_DUMPED[key] = true
    emitLines(dumpLines(trace))
end

local function classify(trace, sample)
    local age
    local acceptedNow
    if trace.finishing == true then return end
    acceptedNow = hasRequestedBump(trace, sample)
    if acceptedNow and trace.acceptedAt == nil then
        trace.acceptedAt = sample.at
        trace.acceptedEvent = sample.event
    end
    if sample.event == "setter_after"
        and not acceptedNow
    then
        setFailure(trace, "setter_rejected", sample)
        return
    end
    if trace.acceptedAt ~= nil
        and not acceptedNow
        and not actionIsBumped(sample)
    then
        setFailure(trace, "bump_cleared_after_set", sample)
        return
    end
    age = sample.at - trace.startedAt
    if trace.acceptedAt ~= nil
        and age >= ACTION_HANDOFF_GRACE_MS
        and not actionIsBumped(sample)
    then
        setFailure(trace, "action_handoff_missing", sample)
    end
end

function Trace.Begin(body, info, now)
    local current
    local trace
    local sample
    if not body then return nil end
    info = type(info) == "table" and info or {}
    if info.debugEnabled ~= true
        and Trace.forceEnabled ~= true
    then
        return nil
    end
    now = nowMillis(now)
    current = BY_BODY[body]
    if current
        and current.finishing ~= true
        and (
            info.attackKey ~= nil
                and tostring(current.attackKey or "")
                    == tostring(info.attackKey)
            or info.attackKey == nil
                and tostring(current.requested or "")
                    == tostring(info.requested or "")
                and (now - current.startedAt) <= 50
        )
    then
        if info.npcId ~= nil then
            current.npcId = tostring(info.npcId)
            BY_NPC[current.npcId] = current
        end
        if info.debugEnabled ~= nil then
            current.debugEnabled =
                info.debugEnabled == true
        end
        return current
    end
    sequence = sequence + 1
    trace = {
        sequence = sequence,
        npcId = info.npcId ~= nil
            and tostring(info.npcId)
            or "unknown",
        attackKey = info.attackKey ~= nil
            and tostring(info.attackKey)
            or nil,
        requested = tostring(info.requested or ""),
        resolved = tostring(
            info.resolved or info.requested or ""
        ),
        topology = tostring(
            info.topology or topologyName()
        ),
        debugEnabled = info.debugEnabled == true
            or Trace.forceEnabled == true,
        startedAt = now,
        samples = {},
    }
    BY_BODY[body] = trace
    BY_NPC[trace.npcId] = trace
    sample = capture(body, "trace_begin", now)
    trace.samples[1] = sample
    trace.lastSignature = stateSignature(sample)
    return trace
end

function Trace.Ensure(body, info, now)
    local trace = body and BY_BODY[body] or nil
    if trace and trace.finishing ~= true then
        return trace
    end
    return Trace.Begin(body, info, now)
end

function Trace.Sample(body, event, now, force)
    local trace = body and BY_BODY[body] or nil
    local sample
    local signature
    if not trace then return nil end
    now = nowMillis(now)
    sample = capture(body, event, now)
    signature = stateSignature(sample)
    if force ~= true
        and signature == trace.lastSignature
    then
        -- A missing ActionContext handoff is a lack of change, so signature
        -- deduplication must still retain the first sample that crosses the
        -- grace period. Otherwise the most important failure mode would be
        -- invisible precisely because the body remained stuck.
        if trace.failure ~= nil
            or trace.finishing == true
            or trace.acceptedAt == nil
            or (now - trace.startedAt)
                < ACTION_HANDOFF_GRACE_MS
            or actionIsBumped(sample)
        then
            return trace
        end
    end
    trace.lastSignature = signature
    trace.samples[#trace.samples + 1] = sample
    if #trace.samples > MAX_SAMPLES then
        table.remove(trace.samples, 1)
    end
    classify(trace, sample)
    return trace
end

function Trace.MarkFinishing(body, event, now)
    local trace = body and BY_BODY[body] or nil
    if not trace then return nil end
    trace.finishing = true
    return Trace.Sample(
        body,
        event or "finish_before",
        now,
        true
    )
end

function Trace.End(body, event, now)
    local trace = body and BY_BODY[body] or nil
    if not trace then return nil end
    Trace.Sample(
        body,
        event or "trace_end",
        now,
        true
    )
    trace.endedAt = nowMillis(now)
    trace.finishing = true
    return trace
end

function Trace.Get(body)
    return body and BY_BODY[body] or nil
end

function Trace.GetOverlayLine(body)
    local trace = body and BY_BODY[body] or nil
    local sample
    local age
    if not trace or #trace.samples == 0 then
        return nil
    end
    sample = trace.samples[#trace.samples]
    age = math.max(
        0,
        (
            tonumber(trace.endedAt)
                or nowMillis()
        ) - trace.startedAt
    )
    return "TRACE #" .. tostring(trace.sequence)
        .. " age=" .. tostring(age) .. "ms"
        .. " last=" .. tostring(sample.event)
        .. " field/var=" .. tostring(
            sample.bump ~= "" and sample.bump or "-"
        ) .. "/" .. tostring(
            sample.bumpVariable ~= ""
                and sample.bumpVariable
                or "-"
        )
        .. " bumped=" .. tostring(sample.bumped)
        .. "/" .. tostring(sample.bumpStaggered)
        .. " ctx=" .. tostring(
            sample.actionCurrent ~= ""
                and sample.actionCurrent
                or sample.action ~= ""
                    and sample.action
                    or "-"
        )
        .. " java=" .. tostring(
            sample.javaState ~= "" and sample.javaState or "-"
        )
        .. " anim=" .. tostring(
            sample.animationState ~= ""
                and sample.animationState
                or "-"
        )
        .. " fail=" .. tostring(trace.failure or "-")
        .. (
            trace.failureEvent
                and "@" .. tostring(trace.failureEvent)
                or ""
        )
end

function Trace.DumpBody(body)
    local lines = dumpLines(body and BY_BODY[body] or nil)
    emitLines(lines)
    return lines
end

function Trace.DumpNPC(npcId)
    local lines = dumpLines(
        BY_NPC[tostring(npcId or "")]
    )
    emitLines(lines)
    return lines
end

function Trace.DumpAll()
    local traces = {}
    local seen = {}
    local lines = {}
    local _, trace
    local i
    local traceLines
    for _, trace in pairs(BY_NPC) do
        if trace and not seen[trace] then
            seen[trace] = true
            traces[#traces + 1] = trace
        end
    end
    table.sort(traces, function(left, right)
        return left.sequence < right.sequence
    end)
    for i = 1, #traces do
        traceLines = dumpLines(traces[i])
        for _, line in ipairs(traceLines) do
            lines[#lines + 1] = line
        end
    end
    if #lines == 0 then
        lines[1] = "[PNC][ANIMTRACE] no retained traces"
    end
    emitLines(lines)
    return lines
end

function Trace.Reset()
    BY_BODY = setmetatable({}, { __mode = "k" })
    BY_NPC = {}
    AUTO_DUMPED = {}
end

function Trace.SetEnabled(enabled)
    Trace.forceEnabled = enabled == true
    return Trace.forceEnabled
end
