local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Stealth/PNC_Stealth.lua"

local sneaking = false
local running = false
local owner = {
    isDead = function() return false end,
    isSneaking = function() return sneaking end,
    isRunning = function() return running end,
    isSprinting = function() return false end,
    getVehicle = function() return nil end,
}

PNC = {
    Const = {
        FOLLOW_WALK_DISTANCE = 4,
        FOLLOW_CATCHUP_EXIT_DISTANCE = 3,
        FOLLOW_HORDE_AVOID_COUNT = 3,
    },
    Core = {},
}

dofile(FILE)

local record = {
    runtime = {
        followState = {
            ownerMoving = false,
        },
        -- Discovery policy must not silently rewrite locomotion posture.
        stealthActive = true,
        ownerSneaking = false,
    },
}

assert(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "walk",
    "shared stealth flag forced a normal follower to sneak"
)
assert(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 5, 5, 0)
        == "run",
    "follower did not run at the catch-up threshold"
)
assert(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "walk",
    "catch-up mode did not exit near the owner"
)

sneaking = true
record.runtime.stealthActive = false
assert(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "sneak",
    "follower did not mirror a sneaking owner"
)

sneaking = false
running = true
assert(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "run",
    "follower did not immediately mirror a running owner"
)

print("pnc_follow_move_mode_smoke: ok")
