local T = require "tests/support/test"

local LUA_ROOT =
    T.path("ProjectHoomans", "client", "")
local FILE = LUA_ROOT .. "PNC/PresenceSync/PresenceVisuals/"
    .. "PNC_ClientPresenceVisuals.lua"

T.addPackagePaths()

local maintained = 0
local locomotionWrites = 0
local humanizedWrites = 0
local femaleWrites = 0
local modData = {}
local variables = {}
local body = {
    isDead = function() return false end,
    getModData = function() return modData end,
    setVariable = function(_, name, value)
        variables[name] = value
    end,
    setFemaleEtc = function(_, value)
        femaleWrites = femaleWrites + 1
        variables.female = value
    end,
    isFemale = function() return variables.female == true end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
    },
    Core = {
        Now = function() return 5000 end,
    },
    ClientPresenceSync = {
        Internal = {
            LogClientMotionDebug = function() end,
        },
    },
    Animation = {
        Apply = function() locomotionWrites = locomotionWrites + 1 end,
    },
    LiveBodyControl = {
        MaintainHumanizedBody = function()
            humanizedWrites = humanizedWrites + 1
        end,
    },
    AnimationDebugPlayer = {
        IsPreviewing = function(candidate)
            return candidate == body
        end,
        Maintain = function(candidate, now)
            T.truthy(candidate == body, "wrong preview body")
            T.truthy(now == 5000, "wrong preview time")
            maintained = maintained + 1
        end,
    },
}

T.load(FILE)
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody({
    id = "debug-npc",
    presenceState = "live",
    isFemale = true,
    visualState = {
        moving = true,
        anim = "Run",
        nativeMoveActive = true,
    },
}, body, true)

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody({
    id = "debug-npc",
    presenceState = "live",
    isFemale = true,
    visualState = {
        moving = true,
        anim = "Run",
        nativeMoveActive = true,
    },
}, body, true)

T.truthy(maintained == 2, "debug player did not retain snapshot ownership")
T.equal(femaleWrites, 1,
    "repeated debug snapshots reset the native voice identity")
T.truthy(humanizedWrites == 0, "normal body maintenance raced debug playback")
T.truthy(locomotionWrites == 0, "snapshot locomotion overwrote debug playback")
T.truthy(variables.PNCActor == true, "NPC identity variable was not maintained")
T.truthy(variables.PNCLive == true, "live identity variable was not maintained")
T.truthy(modData.PNC_UUID == "debug-npc", "body identity tag was not maintained")
T.truthy(modData.PNC_NPC == true, "NPC body tag was not maintained")
T.finish("pnc_animation_debug_snapshot_gate_smoke")

T.finish("pnc_animation_debug_snapshot_gate_smoke")
