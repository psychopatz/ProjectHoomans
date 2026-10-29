local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local ownerX = 0
local ownerY = 0
local ownerMoving = true
local forwardX = 0
local forwardY = 1

local owner = {
    getX = function() return ownerX end,
    getY = function() return ownerY end,
    getZ = function() return 0 end,
    getOnlineID = function() return 41 end,
    getUsername = function() return "alice" end,
    isPlayerMoving = function() return ownerMoving end,
    isRunning = function() return false end,
    isSprinting = function() return false end,
    getForwardDirection = function()
        return {
            getX = function() return forwardX end,
            getY = function() return forwardY end,
        }
    end,
}

local record = {
    id = "mp_follow",
    alive = true,
    recruited = true,
    ownerOnlineID = 41,
    ownerUsername = "alice",
    orderSpec = { kind = "follow" },
    runtime = {},
}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_OWNER_MOVE_EPSILON = 0.08,
        FOLLOW_OWNER_STOP_GRACE_MS = 450,
        FOLLOW_FORMATION_MOVING_CACHE_MS = 300,
        FOLLOW_FORMATION_IDLE_CACHE_MS = 1000,
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
        FOLLOW_RETARGET_OWNER_DISTANCE = 0.75,
        FOLLOW_RETARGET_MAX_MS = 800,
    },
    Core = {
        Now = function() return now end,
    },
    BehaviorCompanion = { Internal = {} },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        HaltMovement = function() end,
    },
    Animation = {},
    Registry = {
        ForEach = function(callback)
            callback(record)
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation.lua"
)

local Internal = PNC.BehaviorCompanion.Internal

-- Initial MP sample can say "moving" before a useful position delta exists.
local state = Internal.UpdateOwnerMotionState(record, owner, now)
T.truthy(state.ownerMoving, "reported remote movement was ignored")

-- The next network sample provides the real travel vector: east.
now = 1100
ownerX = 1
ownerY = 0
state = Internal.UpdateOwnerMotionState(record, owner, now)
T.truthy(state.ownerMoving, "physical remote-player movement was ignored")
T.near(state.ownerTravelDirX, 1, 0.001,
    "owner travel heading did not follow physical MP movement")
T.near(state.ownerTravelDirY, 0, 0.001,
    "owner travel heading drifted from physical MP movement")

-- The remote player may aim north/south while still travelling east. Follow
-- slots must remain behind the travel vector instead of orbiting with facing.
forwardX = 0
forwardY = -1
local target = Internal.ResolveFollowSlot(record, owner, true)
T.near(target.x, ownerX - 2.25, 0.001,
    "moving MP follower slot rotated away from travel heading")
T.near(target.y, ownerY, 0.001,
    "moving MP follower slot orbited with owner facing")

-- A single interpolation gap/micro-jitter must not flip moving->idle and
-- rebuild every follower's route.
now = 1300
ownerMoving = false
ownerX = 1.02
state = Internal.UpdateOwnerMotionState(record, owner, now)
T.truthy(state.ownerMoving,
    "remote-player packet gap dropped follow movement before grace expired")
T.falsy(state.ownerMovingChanged,
    "remote-player packet gap toggled the follow movement state")

-- After the grace actually expires the owner can settle, but the last travel
-- heading remains the formation axis; looking around while stationary cannot
-- make followers circle the player.
now = 1600
state = Internal.UpdateOwnerMotionState(record, owner, now)
T.falsy(state.ownerMoving, "owner stop grace never released")
forwardX = -1
forwardY = 0
target = Internal.ResolveFollowSlot(record, owner, false)
T.near(target.x, ownerX - 2.25, 0.001,
    "stationary MP formation forgot the last travel axis")
T.near(target.y, ownerY, 0.001,
    "stationary facing change rotated the follow slot")

T.finish("pnc_mp_follow_stability_smoke")
