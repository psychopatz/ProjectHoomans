local T = require "tests/support/test"

local PLAYER_FILE =
    T.path("ProjectHoomans", "client", "PNC/Debug/")
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
        T.truthy(
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
T.load(PLAYER_FILE)

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
T.truthy(
    ok and reason == "xml_selectors_clip_started",
    "XML preview did not start"
)
T.truthy(state.raw == "Bob_Idle", "XML clip was not started")
T.truthy(state.variables.DebugSelector == "chosen", "XML selector was not applied")
T.truthy(state.hitForce == 1.01, "GTR selector value was not satisfied")
T.truthy(
    state.targetSeenTime == 0.49,
    "targetSeenTime adapter did not satisfy LESS selector"
)
T.truthy(
    state.variables.bHasTarget == nil,
    "read-only derived selector was written"
)
T.truthy(
    player.active.skippedSelectors[1] == "bHasTarget",
    "read-only selector was not reported"
)
T.truthy(state.useless == false, "preview body must be engine-active")
T.truthy(player.IsPreviewing(body), "preview body ownership missing")
T.truthy(traceEvents[#traceEvents] == "debug_xml_play", "XML trace stage missing")

player.Stop("test_xml_stop")
T.truthy(state.variables.DebugSelector == "", "selector was not restored")
T.truthy(state.hitForce == 0, "numeric selector was not restored")
T.truthy(state.targetSeenTime == 3.0, "callback selector was not restored")
T.truthy(state.useless == true, "managed useless state was not restored")
T.truthy(not player.IsPreviewing(body), "preview ownership survived stop")

ok, reason = player.PlayPipeline(entry, "npc-1", body)
T.truthy(ok and reason == "bump_type_setter", "pipeline preview failed")
T.truthy(#pipelineCalls == 1, "PNC bump pipeline was not called")
T.truthy(
    pipelineCalls[1].bumpType == "PNC_Legacy_Attack2H2",
    "wrong pipeline BumpType"
)
T.truthy(
    pipelineCalls[1].keepManagedUseless == nil,
    "debug pipeline must preserve the SP/MP body-mode contract"
)
player.Finish()
T.truthy(finishCalls == 1, "pipeline finish was not signalled")
player.Stop("test_pipeline_stop")
T.truthy(finishCalls == 2, "stop did not finish active pipeline")

ok, reason = player.PlayRaw(entry, "npc-1", body)
T.truthy(ok and reason == "raw_clip_started", "raw preview failed")
T.truthy(state.raw == entry.anim, "wrong raw animation clip")
T.truthy(
    state.variables.BumpType == "before",
    "raw clip mode unexpectedly applied XML selectors"
)
local runtime = player.Runtime()
T.truthy(runtime.track == "Bob_TestTrack", "runtime track inspection failed")
T.truthy(runtime.trackTime == 0.25, "runtime track time inspection failed")
T.truthy(
    runtime.advancedState == "not Lua-exposed",
    "runtime must not index strict AdvancedAnimator userdata"
)
player.Stop("done")

-- Build 42 model playback uses AnimationPlayer tracks. Verify the debugger
-- owns a native track and freezes its final frame instead of relying on the
-- legacy PlayAnim* stubs.
local nativeTrack = {
    time = 0,
    duration = 1.25,
    isPlaying = true,
}
function nativeTrack:getDuration() return self.duration end
function nativeTrack:getCurrentTimeValue() return self.time end
function nativeTrack:setCurrentTimeValue(value) self.time = value end
function nativeTrack:setPreviousTimeValue(value) self.previous = value end
function nativeTrack:isFinished() return self.time >= self.duration end
function nativeTrack:setBlendWeight(value) self.blendWeight = value end
function nativeTrack:setSpeedDelta(value) self.speed = value end
function nativeTrack:reset() self.currentClip = nil end
local nativeMultiTrack = {}
function nativeMultiTrack:removeTrack(track)
    self.removed = track
end
local nativePlayer = {}
function nativePlayer:play(clip, looped)
    self.clip = clip
    self.looped = looped
    return nativeTrack
end
function nativePlayer:getMultiTrack() return nativeMultiTrack end
local nativeBody = {}
for key, value in pairs(body) do nativeBody[key] = value end
nativeBody.getModData = function() return { PNC_UUID = "npc-1" } end
nativeBody.getAnimationPlayer = function() return nativePlayer end

player.SetHoldPose(true)
ok, reason = player.PlayRaw(entry, "npc-1", nativeBody)
T.truthy(ok and reason == "raw_clip_started", "native raw preview failed")
T.equal(nativePlayer.clip, entry.anim, "native track received selected clip")
T.equal(nativeTrack.blendWeight, 1.0, "native track was given visible blend weight")
T.equal(nativeTrack.speed, entry.speed, "native track received clip speed")
nativeTrack.time = nativeTrack.duration
player.Maintain(nativeBody, now)
T.equal(nativeTrack.time, nativeTrack.duration, "held track moved to final frame")
T.equal(nativeTrack.isPlaying, false, "held track stopped advancing")
T.truthy(player.active.poseHeld, "native pose hold state was not recorded")
runtime = player.Runtime()
T.equal(runtime.trackSource, "AnimationPlayer.play", "native track source missing")
T.equal(runtime.trackDuration, nativeTrack.duration, "native track duration missing")
player.Stop("native_done")
T.equal(nativeMultiTrack.removed, nativeTrack, "owned native track was removed")

local originalPrimary = { id = "original_primary" }
local originalSecondary = { id = "original_secondary" }
local heldPrimary = originalPrimary
local heldSecondary = originalSecondary
local rangedItem = { fullType = "Base.Pistol" }
function rangedItem:getFullType() return self.fullType end
function rangedItem:isRanged() return true end
function nativeBody:getPrimaryHandItem() return heldPrimary end
function nativeBody:getSecondaryHandItem() return heldSecondary end
function nativeBody:setPrimaryHandItem(item) heldPrimary = item end
function nativeBody:setSecondaryHandItem(item) heldSecondary = item end
function nativeBody:getInventory()
    return {
        getItems = function()
            return {
                size = function() return 1 end,
                get = function(_, index) return index == 0 and rangedItem or nil end,
            }
        end,
    }
end
state.variables.PNCPrimary = "original.primary"
state.variables.PNCSecondary = "original.secondary"
state.variables.PNCPrimaryType = "onehanded"
ok, reason = player.PlayRaw(entry, "npc-1", nativeBody)
T.truthy(ok, "native preview did not restart for equipment test")
ok, reason = player.ToggleRangedWeapon()
T.truthy(ok and reason == "temporary_inventory_item", "temporary ranged equip failed")
T.equal(heldPrimary, rangedItem, "temporary ranged weapon was equipped")
T.equal(state.variables.PNCPrimaryType, "handgun", "ranged selector type was applied")
T.truthy(player.IsRangedOverrideActive(), "ranged override was not recorded")
ok, reason = player.PlayRaw(entry, "npc-1", nativeBody)
T.truthy(ok, "native preview did not replay with ranged override")
T.equal(heldPrimary, rangedItem,
    "ranged override was not preserved while replacing the clip")
T.truthy(player.IsRangedOverrideActive(),
    "ranged override was lost while replacing the clip")
player.Stop("equipment_done")
T.equal(heldPrimary, originalPrimary, "temporary primary hand was restored")
T.equal(heldSecondary, originalSecondary, "temporary secondary hand was restored")
T.equal(state.variables.PNCPrimary, "original.primary", "primary selector was restored")
T.equal(state.variables.PNCPrimaryType, "onehanded", "primary type selector was restored")

T.finish("pnc_animation_debug_player_smoke")
