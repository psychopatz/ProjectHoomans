local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
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
        FOLLOW_RUN_DISTANCE = 10,
        FOLLOW_CATCHUP_EXIT_DISTANCE = 6,
        FOLLOW_HORDE_AVOID_COUNT = 3,
    },
    Core = {},
}

T.load(FILE)

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

T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "walk",
    "shared stealth flag forced a normal follower to sneak"
)
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 5, 5, 0)
        == "walk",
    "follower ran for an ordinary formation gap"
)
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 11, 11, 0)
        == "run",
    "follower did not run for severe separation"
)
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 7, 7, 0)
        == "run",
    "catch-up hysteresis released too early"
)
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 5, 5, 0)
        == "walk",
    "catch-up mode did not exit near the owner"
)

sneaking = true
record.runtime.stealthActive = false
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "sneak",
    "follower did not mirror a sneaking owner"
)

sneaking = false
running = true
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 2, 2, 0)
        == "walk",
    "nearby follower mirrored running and created locomotion churn"
)
T.truthy(
    PNC.Stealth.ResolveFollowMoveMode(record, owner, 5, 5, 0)
        == "run",
    "trailing follower did not catch a running owner"
)
T.finish("pnc_follow_move_mode_smoke")

T.finish("pnc_follow_move_mode_smoke")
