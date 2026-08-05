local PLAYER_FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Debug/"
        .. "PNC_AnimationDebugPlayer.lua"

local now = 1000
local pipelineCalls = {}
local finishCalls = 0
local traceEvents = {}
local state = {
    variables = {
        PNCActor = true,
        BumpType = "before",
    },
    useless = true,
    raw = nil,
    advancedState = "idle",
    targetSeenTime = 3.0,
    hitForce = 0,
    modData = { PNC_UUID = "npc-1" },
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    AnimationDebugCatalog = {
        entries = {},
        stateCounts = {},
    },
    Animation = {
        PlayBump = function(_, _, bumpType, options)
            pipelineCalls[#pipelineCalls + 1] = {
                bumpType = bumpType,
                keepManagedUseless = options
                    and options.keepManagedUseless
                    or nil,
            }
            return true, "bump_type_setter"
        end,
        FinishBump = function()
            finishCalls = finishCalls + 1
        end,
        PumpBumpRelease = function() return false end,
    },
    AnimationTrace = {
        Sample = function(_, event)
            traceEvents[#traceEvents + 1] = event
        end,
        DumpBody = function() end,
    },
}

local strictJavaAnimator = setmetatable({}, {
    __index = function(_, key)
        error("attempted index: " .. tostring(key)
            .. " of non-table: AdvancedAnimator")
    end,
})

local body = {
    getModData = function() return state.modData end,
    isDead = function() return false end,
    isUseless = function() return state.useless end,
    setUseless = function(_, value) state.useless = value end,
    getVariableString = function(_, name)
        return tostring(state.variables[name] or "")
    end,
    getVariableBoolean = function(_, name)
        return state.variables[name] == true
    end,
    getVariableFloat = function(_, name)
        return tonumber(state.variables[name]) or 0
    end,
    setVariable = function(_, name, value)
        assert(
            name ~= "targetSeenTime" and name ~= "hitforce",
            "callback-backed selector was written through setVariable"
        )
        state.variables[name] = value
    end,
    clearVariable = function(_, name)
        state.variables[name] = nil
    end,
    getAdvancedAnimator = function() return strictJavaAnimator end,
    getTargetSeenTime = function() return state.targetSeenTime end,
    setTargetSeenTime = function(_, value)
        state.targetSeenTime = value
    end,
    getHitForce = function() return state.hitForce end,
    setHitForce = function(_, value) state.hitForce = value end,
    PlayAnimUnlooped = function(_, clip)
        state.raw = clip
    end,
    reportEvent = function(_, event)
        state.reported = event
    end,
    getCurrentActionContextStateName = function() return "idle" end,
    getPreviousActionContextStateName = function() return "walktoward" end,
    getAnimationStateName = function() return state.advancedState end,
    getBumpType = function()
        return tostring(state.variables.BumpType or "")
    end,
    dbgGetAnimTrackName = function() return "Bob_TestTrack" end,
    dbgGetAnimTrackTime = function() return 0.25 end,
    dbgGetAnimTrackWeight = function() return 1.0 end,
}

function require() return true end
dofile(PLAYER_FILE)

local player = PNC.AnimationDebugPlayer
local xmlEntry = {
    state = "idle",
    folder = "idle",
    file = "PNC_DebugIdle.xml",
    node = "PNC_DebugIdle",
    anim = "Bob_Idle",
    speed = 1.0,
    looped = false,
    playable = true,
    conditions = {
        { name = "PNCActor", kind = "BOOL", value = "true" },
        { name = "DebugSelector", kind = "STRING", value = "chosen" },
        { name = "hitforce", kind = "GTR", value = "1.0" },
        { name = "targetSeenTime", kind = "LESS", value = "0.5" },
        { name = "bHasTarget", kind = "BOOL", value = "true" },
    },
}
local entry = {
    state = "bumped",
    folder = "bumped",
    file = "PNC_Anim_Attack2H2.xml",
    node = "PNC_Anim_Attack2H2",
    anim = "Bob_AttackBat01_HitB",
    speed = 0.9,
    looped = false,
    playable = true,
    conditions = {
        { name = "PNCActor", kind = "BOOL", value = "true" },
        {
            name = "BumpType",
            kind = "STRING",
            value = "PNC_Legacy_Attack2H2",
        },
        { name = "hitforce", kind = "GTR", value = "1.0" },
    },
}

local ok, reason = player.PlayXML(xmlEntry, "npc-1", body)
assert(
    ok and reason == "xml_selectors_clip_started",
    "XML preview did not start"
)
assert(state.raw == "Bob_Idle", "XML clip was not started")
assert(state.variables.DebugSelector == "chosen", "XML selector was not applied")
assert(state.hitForce == 1.01, "GTR selector value was not satisfied")
assert(
    state.targetSeenTime == 0.49,
    "targetSeenTime adapter did not satisfy LESS selector"
)
assert(
    state.variables.bHasTarget == nil,
    "read-only derived selector was written"
)
assert(
    player.active.skippedSelectors[1] == "bHasTarget",
    "read-only selector was not reported"
)
assert(state.useless == false, "preview body must be engine-active")
assert(player.IsPreviewing(body), "preview body ownership missing")
assert(traceEvents[#traceEvents] == "debug_xml_play", "XML trace stage missing")

player.Stop("test_xml_stop")
assert(state.variables.DebugSelector == "", "selector was not restored")
assert(state.hitForce == 0, "numeric selector was not restored")
assert(state.targetSeenTime == 3.0, "callback selector was not restored")
assert(state.useless == true, "managed useless state was not restored")
assert(not player.IsPreviewing(body), "preview ownership survived stop")

ok, reason = player.PlayPipeline(entry, "npc-1", body)
assert(ok and reason == "bump_type_setter", "pipeline preview failed")
assert(#pipelineCalls == 1, "PNC bump pipeline was not called")
assert(
    pipelineCalls[1].bumpType == "PNC_Legacy_Attack2H2",
    "wrong pipeline BumpType"
)
assert(
    pipelineCalls[1].keepManagedUseless == nil,
    "debug pipeline must preserve the SP/MP body-mode contract"
)
player.Finish()
assert(finishCalls == 1, "pipeline finish was not signalled")
player.Stop("test_pipeline_stop")
assert(finishCalls == 2, "stop did not finish active pipeline")

ok, reason = player.PlayRaw(entry, "npc-1", body)
assert(ok and reason == "raw_clip_started", "raw preview failed")
assert(state.raw == entry.anim, "wrong raw animation clip")
assert(
    state.variables.BumpType == "before",
    "raw clip mode unexpectedly applied XML selectors"
)
local runtime = player.Runtime()
assert(runtime.track == "Bob_TestTrack", "runtime track inspection failed")
assert(runtime.trackTime == 0.25, "runtime track time inspection failed")
assert(
    runtime.advancedState == "not Lua-exposed",
    "runtime must not index strict AdvancedAnimator userdata"
)
player.Stop("done")

print("pnc_animation_debug_player_smoke: ok")
