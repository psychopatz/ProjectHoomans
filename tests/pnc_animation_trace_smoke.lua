local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/")
    .. "Core/Visuals/PNC_AnimationTrace.lua"

local now = 1000
local logs = {}

PNC = {
    Core = {
        Now = function() return now end,
        Log = function(_, message)
            logs[#logs + 1] = message
        end,
    },
    ClientPresenceSync = { Internal = {
        LogClientMotionDebug = function() end,
    } },
}

T.load(FILE)
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local playBumpCalls = 0
PNC.Animation = {
    ResolveBumpType = function(animation)
        return tostring(animation or "")
    end,
    PlayBump = function(candidate, _, animation)
        playBumpCalls = playBumpCalls + 1
        PNC.AnimationTrace.Sample(
            candidate,
            "setter_before",
            now,
            true
        )
        candidate:setBumpType(animation)
        PNC.AnimationTrace.Sample(
            candidate,
            "setter_after",
            now,
            true
        )
    end,
}
T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Attack.lua")

local function makeBody()
    local state = {
        bump = "",
        bumpVariable = "",
        action = "idle",
        previousAction = "",
        javaState = "ZombieIdleState",
        animationState = "idle",
        staggered = false,
        modData = {},
    }
    local body = {
        getModData = function() return state.modData end,
        getBumpType = function() return state.bump end,
        setBumpType = function(_, value)
            state.bump = tostring(value or "")
            state.bumpVariable = state.bump
            state.staggered = state.bump ~= ""
        end,
        isBumped = function() return state.bump ~= "" end,
        isBumpStaggered = function()
            return state.staggered
        end,
        isBumpDone = function() return false end,
        getVariableString = function(_, name)
            if name == "BumpType" then
                return state.bumpVariable
            end
            return ""
        end,
        getVariableBoolean = function(_, name)
            return name == "PNCActor"
        end,
        getActionStateName = function()
            return state.action
        end,
        getCurrentActionContextStateName = function()
            return state.action
        end,
        getPreviousActionContextStateName = function()
            return state.previousAction
        end,
        getCurrentStateName = function()
            return state.javaState
        end,
        getAnimationStateName = function()
            return state.animationState
        end,
        isMoving = function() return false end,
        isSneaking = function() return false end,
        isUseless = function() return true end,
        isLocal = function() return true end,
        getPath2 = function() return nil end,
        getPrimaryHandItem = function() return nil end,
    }
    return body, state
end

local body, state = makeBody()
T.equal(PNC.AnimationTrace.Begin(body, {
    npcId = "disabled",
    requested = "Attack1H1",
    resolved = "Attack1H1",
    debugEnabled = false,
}, now), nil, "animation trace stays disabled by default")
T.equal(PNC.AnimationTrace.Get(body), nil,
    "disabled trace does not retain a body")
local trace = PNC.AnimationTrace.Begin(body, {
    npcId = "accepted",
    attackKey = "Attack1H1:1800",
    requested = "PNC_Attack1H1",
    resolved = "Attack1H1",
    debugEnabled = true,
}, now)
PNC.AnimationTrace.Sample(
    body,
    "setter_before",
    now,
    true
)
state.bump = "Attack1H1"
state.bumpVariable = "Attack1H1"
state.staggered = true
PNC.AnimationTrace.Sample(
    body,
    "setter_after",
    now,
    true
)
now = 1100
state.previousAction = "idle"
state.action = "bumped"
state.animationState = "bumped"
PNC.AnimationTrace.Sample(
    body,
    "client_pre_maintain",
    now
)
T.equal(trace.failure, nil, "valid action handoff")
T.equal(
    trace.acceptedEvent,
    "setter_after",
    "setter acceptance retained"
)

body, state = makeBody()
now = 2000
trace = PNC.AnimationTrace.Begin(body, {
    npcId = "cleared",
    attackKey = "Attack2H2:2800",
    requested = "PNC_Attack2H2",
    resolved = "Attack2H2",
    debugEnabled = true,
}, now)
state.bump = "Attack2H2"
state.bumpVariable = "Attack2H2"
state.staggered = true
PNC.AnimationTrace.Sample(
    body,
    "setter_after",
    now,
    true
)
now = 2030
state.bump = ""
state.bumpVariable = ""
state.staggered = false
PNC.AnimationTrace.Sample(
    body,
    "humanize_after",
    now
)
T.equal(
    trace.failure,
    "bump_cleared_after_set",
    "cleared bump classified"
)
T.equal(
    trace.failureEvent,
    "humanize_after",
    "first clearing stage retained"
)
T.equal(
    #logs > 0,
    true,
    "debug failure auto-dumped once"
)

body, state = makeBody()
now = 3000
PNC.AnimationTrace.SetEnabled(true)
trace = PNC.AnimationTrace.Begin(body, {
    npcId = "stuck",
    attackKey = "Attack1H2:3800",
    requested = "PNC_Attack1H2",
    resolved = "Attack1H2",
    debugEnabled = false,
}, now)
state.bump = "Attack1H2"
state.bumpVariable = "Attack1H2"
state.staggered = true
PNC.AnimationTrace.Sample(
    body,
    "setter_after",
    now,
    true
)
now = 3200
PNC.AnimationTrace.Sample(
    body,
    "client_attack_observe",
    now
)
T.equal(
    trace.failure,
    "action_handoff_missing",
    "unchanged action handoff classified"
)
local overlay = PNC.AnimationTrace.GetOverlayLine(body)
T.contains(
    overlay,
    "fail=action_handoff_missing@client_attack_observe",
    "overlay failure stage"
)
local dump = PNC.AnimationTrace.DumpNPC("stuck")
T.contains(
    dump[1],
    "npc=stuck",
    "manual NPC dump"
)
T.contains(
    dump[#dump],
    "event=client_attack_observe",
    "manual transition timeline"
)

body, state = makeBody()
now = 3300
state.action = "walktoward"
trace = PNC.AnimationTrace.Begin(body, {
    npcId = "rearm-trace",
    attackKey = "Attack1H1:3450",
    requested = "Attack1H1",
    resolved = "Attack1H1",
    debugEnabled = true,
}, now)
state.bump = "Attack1H1"
state.bumpVariable = "Attack1H1"
state.staggered = true
PNC.AnimationTrace.Sample(body, "setter_after", now, true)
local rearmModData = body.getModData()
rearmModData.PNC_ClientAttackLocalStartedAt = now - 150
rearmModData.PNC_ClientAttackRetries = 0
local rearmed = PNC.ClientPresenceSync.Internal.RearmDroppedClientAttackBump(
    { id = "rearm-trace", visualState = { attackFinishAt = now + 500 } },
    body,
    {},
    rearmModData,
    "Attack1H1:3450",
    "Attack1H1",
    now
)
T.truthy(rearmed, "dropped attack bump was not rearmed")
T.equal(playBumpCalls, 1, "attack bump rearm did not request the selector")
T.equal(state.bump, "Attack1H1", "attack bump rearm lost its selector")
T.equal(trace.failure, nil,
    "expected selector reset was classified as a bump failure")
local expectedResetSample
for i = 1, #trace.samples do
    if trace.samples[i].expectedRearmSelectorClear then
        expectedResetSample = trace.samples[i]
    end
end
T.truthy(expectedResetSample,
    "trace did not label the expected rearm selector reset")
local rearmDump = PNC.AnimationTrace.DumpNPC("rearm-trace")
T.contains(
    rearmDump[4],
    "expectedRearmSelectorClear=true",
    "diagnostic dump labels the intentional selector reset"
)
now = now + 200
state.bump = ""
state.bumpVariable = ""
state.staggered = false
PNC.AnimationTrace.Sample(body, "client_attack_observe", now, true)
T.equal(trace.failure, "bump_cleared_after_set",
    "later unexpected bump clear was not classified")

local retainedLimit = PNC.AnimationTrace.Internal.MAX_RETAINED_TRACES
local firstRetainedBody
local lastRetainedBody
local lastRetainedTrace
local retainedCount = 0
PNC.AnimationTrace.Reset()
for i = 1, retainedLimit + 5 do
    body = makeBody()
    now = now + 1
    trace = PNC.AnimationTrace.Begin(body, {
        npcId = "bounded-" .. tostring(i),
        requested = "Attack1H1",
        resolved = "Attack1H1",
        debugEnabled = false,
    }, now)
    PNC.AnimationTrace.End(body, "bounded_end", now)
    if i == 1 then firstRetainedBody = body end
    if i == retainedLimit + 5 then
        lastRetainedBody = body
        lastRetainedTrace = trace
    end
end
for _ in pairs(PNC.AnimationTrace.Internal.byNPC) do
    retainedCount = retainedCount + 1
end
T.equal(retainedCount, retainedLimit,
    "completed trace retention cap")
T.equal(PNC.AnimationTrace.Get(firstRetainedBody), nil,
    "evicted trace body lookup cleared")
T.equal(PNC.AnimationTrace.Get(lastRetainedBody), lastRetainedTrace,
    "newest trace body lookup retained")

local autoDumpLimit = PNC.AnimationTrace.Internal.MAX_AUTO_DUMP_KEYS
local firstFailureID
local lastFailureID
local dumpedFailureCount = 0
PNC.AnimationTrace.Reset()
for i = 1, autoDumpLimit + 5 do
    local failureID = "bounded-failure-" .. tostring(i)
    body = makeBody()
    now = now + 1
    PNC.AnimationTrace.Begin(body, {
        npcId = failureID,
        requested = "Attack1H1",
        resolved = "Attack1H1",
        debugEnabled = false,
    }, now)
    PNC.AnimationTrace.Sample(body, "setter_after", now, true)
    if i == 1 then firstFailureID = failureID end
    if i == autoDumpLimit + 5 then lastFailureID = failureID end
end
for _ in pairs(PNC.AnimationTrace.Internal.autoDumped) do
    dumpedFailureCount = dumpedFailureCount + 1
end
T.equal(dumpedFailureCount, autoDumpLimit,
    "automatic dump dedupe cap")
T.equal(PNC.AnimationTrace.Internal.autoDumped[
    firstFailureID .. "|setter_rejected"], nil,
    "old dedupe key evicted")
T.truthy(PNC.AnimationTrace.Internal.autoDumped[
    lastFailureID .. "|setter_rejected"],
    "new dedupe key retained")

T.finish("pnc_animation_trace_smoke")

T.finish("pnc_animation_trace_smoke")
