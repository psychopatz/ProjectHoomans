local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
    .. "Core/Visuals/PNC_AnimationTrace.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertContains(actual, expected, label)
    if not string.find(
        tostring(actual),
        tostring(expected),
        1,
        true
    ) then
        error((label or "assertContains")
            .. ": missing=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local logs = {}

PNC = {
    Core = {
        Now = function() return now end,
        Log = function(_, message)
            logs[#logs + 1] = message
        end,
    },
}

dofile(FILE)

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
assertEqual(trace.failure, nil, "valid action handoff")
assertEqual(
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
assertEqual(
    trace.failure,
    "bump_cleared_after_set",
    "cleared bump classified"
)
assertEqual(
    trace.failureEvent,
    "humanize_after",
    "first clearing stage retained"
)
assertEqual(
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
assertEqual(
    trace.failure,
    "action_handoff_missing",
    "unchanged action handoff classified"
)
local overlay = PNC.AnimationTrace.GetOverlayLine(body)
assertContains(
    overlay,
    "fail=action_handoff_missing@client_attack_observe",
    "overlay failure stage"
)
local dump = PNC.AnimationTrace.DumpNPC("stuck")
assertContains(
    dump[1],
    "npc=stuck",
    "manual NPC dump"
)
assertContains(
    dump[#dump],
    "event=client_attack_observe",
    "manual transition timeline"
)

print("pnc_animation_trace_smoke: ok")
