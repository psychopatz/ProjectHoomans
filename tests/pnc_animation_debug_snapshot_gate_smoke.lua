local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PresenceSync/"
        .. "PNC_ClientPresenceVisuals.lua"

local maintained = 0
local locomotionWrites = 0
local humanizedWrites = 0
local modData = {}
local variables = {}
local body = {
    isDead = function() return false end,
    getModData = function() return modData end,
    setVariable = function(_, name, value)
        variables[name] = value
    end,
    setFemaleEtc = function(_, value)
        variables.female = value
    end,
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
            assert(candidate == body, "wrong preview body")
            assert(now == 5000, "wrong preview time")
            maintained = maintained + 1
        end,
    },
}

dofile(FILE)
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

assert(maintained == 1, "debug player did not retain snapshot ownership")
assert(humanizedWrites == 0, "normal body maintenance raced debug playback")
assert(locomotionWrites == 0, "snapshot locomotion overwrote debug playback")
assert(variables.PNCActor == true, "NPC identity variable was not maintained")
assert(variables.PNCLive == true, "live identity variable was not maintained")
assert(modData.PNC_UUID == "debug-npc", "body identity tag was not maintained")
assert(modData.PNC_NPC == true, "NPC body tag was not maintained")

print("pnc_animation_debug_snapshot_gate_smoke: ok")
