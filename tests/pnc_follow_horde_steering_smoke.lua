local LUA_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
package.path = LUA_ROOT .. "?.lua;" .. package.path

local FILE =
    LUA_ROOT .. "PNC/Core/"
    .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion.lua"

local now = 1000
local engageTicks = 0
local lastMove
local ownerX = 10
local ownerMoving = true
local nearbyZombies
local owner = {
    getForwardDirection = function()
        return {
            getX = function() return 1 end,
            getY = function() return 0 end,
        }
    end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "alice" end,
    getVehicle = function() return nil end,
    getX = function() return ownerX end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isPlayerMoving = function() return ownerMoving end,
    isRunning = function() return false end,
    isSprinting = function() return false end,
}

local function zombie(x, y)
    return {
        isDead = function() return false end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
    }
end

local record = {
    id = "follower",
    alive = true,
    attackType = "auto",
    orderSpec = { kind = "follow" },
    ownerOnlineID = 7,
    ownerUsername = "alice",
    presenceState = "live",
    runtime = {},
    x = 0,
    y = 0,
    z = 0,
}

PNC = {
    Const = {
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        ORDER_FOLLOW = "follow",
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_WALK_DISTANCE = 4,
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
        FOLLOW_PERSONAL_SPACE_MIN = 1.25,
        FOLLOW_FORMATION_CACHE_MS = 250,
        FOLLOW_OWNER_MOVE_EPSILON = 0.08,
        FOLLOW_COMBAT_LEASH_DISTANCE = 5.5,
        FOLLOW_HORDE_AVOID_RADIUS = 6.5,
        FOLLOW_HORDE_AVOID_COUNT = 3,
        FOLLOW_HORDE_NEAR_DISTANCE = 2.4,
        FOLLOW_HORDE_STEER_DISTANCE = 3.4,
        FOLLOW_HORDE_SCAN_MS = 150,
        FOLLOW_HORDE_STEER_MS = 350,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        IsManagedNPCBody = function() return false end,
    },
    Stealth = {
        UpdateFollowState = function() end,
        ResolveFollowMoveMode = function(_, _, _, _, hazardCount)
            return hazardCount >= 3 and "run" or "walk"
        end,
    },
    Animation = {},
    BehaviorCommon = {
        GetOwner = function() return owner end,
        ClearCombatTarget = function(current)
            current.runtime.target = nil
        end,
        MoveRecord = function(_, _, x, y, z, mode, stopDistance, reason)
            lastMove = {
                x = x,
                y = y,
                z = z,
                mode = mode,
                stopDistance = stopDistance,
                reason = reason,
            }
            return true
        end,
        HaltMovement = function() end,
    },
    BehaviorTargeting = {
        ResolveCompanionEngageTarget = function()
            return { kind = "zombie", zombieId = "zed" }
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            engageTicks = engageTicks + 1
        end,
    },
    Perception = {},
    Registry = {
        ForEach = function(callback)
            callback(record)
        end,
    },
    TraversalQuery = {
        CanStep = function() return true end,
        CanOccupy = function() return true end,
    },
    SpatialIndex = {
        QueryZombies = function()
            return nearbyZombies or {
                zombie(1.0, -0.5),
                zombie(1.0, 0),
                zombie(1.0, 0.5),
            }
        end,
    },
}

dofile(FILE)
assert(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))

assert(engageTicks == 0,
    "moving owner lost its follower to opportunistic horde combat")
assert(lastMove and lastMove.reason == "follow_owner_horde_avoidance",
    "horde-aware follow steering was not selected")
assert(math.abs(lastMove.y) > 0.5,
    "horde steering ran directly through the zombie centroid")
assert(lastMove.x > record.x,
    "horde steering stopped making progress toward the owner")
assert(lastMove.mode == "run",
    "horde escape did not use catch-up locomotion")

-- One close zombie still sets the steering hazard active flag, but it is not
-- a horde and must not suppress the follower's combat response.
now = now + 200
record.x = 6
ownerX = 10
record.runtime.followHazard = nil
nearbyZombies = {
    zombie(6.8, 0),
}
lastMove = nil
assert(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
assert(engageTicks == 1,
    "a single nearby zombie was mistaken for a horde and delayed combat")
assert(lastMove == nil,
    "single-zombie combat response was overwritten by follow movement")

-- A stationary owner is still the follower's priority once the companion
-- reaches its combat leash. Otherwise an idle player lets followers chase
-- targets indefinitely and disappear from the formation.
now = now + 200
ownerMoving = false
record.x = 0
ownerX = 10
record.runtime.followHazard = nil
record.runtime.target = { kind = "zombie", zombieId = "zed" }
nearbyZombies = { zombie(0.8, 0) }
lastMove = nil
local engagesBeforeLeash = engageTicks
assert(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
assert(engageTicks == engagesBeforeLeash,
    "far follower chased combat while its owner was stationary")
assert(lastMove ~= nil and string.find(
    tostring(lastMove.reason),
    "follow_owner",
    1,
    true
), "far follower did not resume its owner catch-up")

print("pnc_follow_horde_steering_smoke: ok")
