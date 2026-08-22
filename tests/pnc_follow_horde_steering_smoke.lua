local T = require "tests/support/test"

local LUA_ROOT =
    T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

local FILE =
    LUA_ROOT .. "PNC/Core/"
    .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion.lua"

local now = 1000
local engageTicks = 0
local lastMove
local moveCalls = 0
local haltCalls = 0
local ownerX = 10
local ownerMoving = true
local ownerAttacking = false
local nearbyZombies
local urgentThreat
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
    isAttacking = function() return ownerAttacking end,
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
        FOLLOW_RUN_DISTANCE = 10,
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
        FOLLOW_PERSONAL_SPACE_MIN = 1.25,
        FOLLOW_FORMATION_CACHE_MS = 250,
        FOLLOW_RETARGET_OWNER_DISTANCE = 0.75,
        FOLLOW_RETARGET_MAX_MS = 650,
        FOLLOW_MOVE_INTENT_EPSILON = 0.35,
        FOLLOW_MOVE_INTENT_REFRESH_MS = 1500,
        FOLLOW_OWNER_MOVE_EPSILON = 0.08,
        FOLLOW_COMBAT_LEASH_DISTANCE = 5.5,
        FOLLOW_HORDE_AVOID_RADIUS = 6.5,
        FOLLOW_HORDE_AVOID_COUNT = 3,
        FOLLOW_HORDE_NEAR_DISTANCE = 2.4,
        FOLLOW_HORDE_STEER_DISTANCE = 1.8,
        FOLLOW_HORDE_SCAN_MS = 150,
        FOLLOW_HORDE_STEER_MS = 700,
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
        ResolveFollowMoveMode = function(_, _, ownerDist)
            return ownerDist >= 10 and "run" or "walk"
        end,
    },
    Animation = {},
    BehaviorCommon = {
        GetOwner = function() return owner end,
        ClearCombatTarget = function(current)
            current.runtime.target = nil
        end,
        MoveRecord = function(_, _, x, y, z, mode, stopDistance, reason)
            moveCalls = moveCalls + 1
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
        HaltMovement = function()
            haltCalls = haltCalls + 1
        end,
    },
    BehaviorTargeting = {
        ResolveCompanionProtectionTarget = function(_, ownerEngaged)
            if not ownerEngaged then return nil end
            return {
                kind = "zombie",
                zombieId = "zed",
                x = ownerX - 1,
                y = 0,
            }
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            engageTicks = engageTicks + 1
        end,
    },
    Perception = {
        ResolveRecentAttacker = function()
            return urgentThreat
        end,
        FindImmediateZombieThreat = function()
            return urgentThreat
        end,
    },
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

T.load(FILE)
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))

T.truthy(engageTicks == 0,
    "moving owner lost its follower to opportunistic horde combat")
T.truthy(lastMove and lastMove.reason == "follow_owner_horde_avoidance",
    "horde-aware follow steering was not selected")
T.truthy(math.abs(lastMove.y) > 0.5,
    "horde steering ran directly through the zombie centroid")
T.truthy(lastMove.x > record.x,
    "horde steering stopped making progress toward the owner")
T.truthy(lastMove.mode == "run",
    "severely separated follower did not use catch-up locomotion")

-- Sub-tile owner movement keeps the existing path intent. The path pump still
-- advances it, but behavior does not rebuild routing or increment revisions.
local movesBeforeSmallStep = moveCalls
now = now + 100
ownerX = ownerX + 0.2
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(moveCalls == movesBeforeSmallStep,
    "sub-tile owner movement rebuilt the follow intent")

-- A nearby follower holds where it is when the owner stops. Facing changes
-- must not make it orbit around freshly recomputed formation slots.
now = now + 200
ownerMoving = false
ownerX = 2.8
nearbyZombies = {}
record.runtime.followHazard = nil
lastMove = nil
local haltsBeforeStandstill = haltCalls
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(lastMove == nil, "stationary owner caused formation roaming")
T.truthy(haltCalls == haltsBeforeStandstill + 1,
    "stationary owner did not cancel the active follow path")
T.truthy(record.runtime.followState.mode == "idle_near_owner",
    "stationary follower did not enter idle cadence")

-- Local hazard steering must never turn a close formation correction into a
-- long step past the owner's sampled anchor.
record.runtime.followAvoidanceTarget = nil
local closeSteer = PNC.BehaviorCompanion.Internal
    .ResolveHordeAwareFollowTarget(
        record,
        { x = 0.5, y = 0, z = 0, stopDistance = 0.35 },
        0.5,
        { active = true, count = 3, repelX = 0, repelY = 1 },
        now
    )
T.truthy(closeSteer ~= nil, "close hazard steering was not resolved")
T.truthy(PNC.Core.Distance(record.x, record.y, closeSteer.x, closeSteer.y)
    <= 0.651, "hazard steering overshot a close follow anchor")

-- One close zombie still sets the steering hazard active flag, but it is not
-- a horde and must not suppress the follower's combat response.
now = now + 200
record.x = 6
ownerX = 10
ownerMoving = true
ownerAttacking = true
record.runtime.followHazard = nil
nearbyZombies = {
    zombie(6.8, 0),
}
lastMove = nil
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(engageTicks == 1,
    "a single nearby zombie was mistaken for a horde and delayed combat")
T.truthy(lastMove == nil,
    "single-zombie combat response was overwritten by follow movement")

-- Once the owner's short combat intent expires, a passive nearby zombie must
-- not drag the follower into an opportunistic chase.
now = now + 1600
ownerAttacking = false
record.runtime.followState.ownerEngagedUntil = 0
record.runtime.target = nil
record.runtime.nextTargetReassessAt = 0
lastMove = nil
local engagesBeforePassive = engageTicks
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(engageTicks == engagesBeforePassive,
    "passive nearby zombie pulled follower out of formation")
T.truthy(lastMove ~= nil,
    "passive follower did not resume formation movement")

-- A stationary owner is still the follower's priority once the companion
-- reaches its combat leash. Otherwise an idle player lets followers chase
-- targets indefinitely and disappear from the formation.
now = now + 200
ownerMoving = false
ownerAttacking = false
record.x = 0
ownerX = 10
record.runtime.followHazard = nil
record.runtime.target = { kind = "zombie", zombieId = "zed" }
nearbyZombies = { zombie(0.8, 0) }
lastMove = nil
local engagesBeforeLeash = engageTicks
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(engageTicks == engagesBeforeLeash,
    "far follower chased combat while its owner was stationary")
T.truthy(lastMove ~= nil and string.find(
    tostring(lastMove.reason),
    "follow_owner",
    1,
    true
), "far follower did not resume its owner catch-up")

-- A direct attacker is the sole exception to the owner leash. The companion
-- must defend itself immediately even while badly separated from the owner.
now = now + 200
record.runtime.recentThreat = { kind = "zombie" }
urgentThreat = {
    kind = "zombie",
    zombieId = "direct_attacker",
    x = record.x + 1,
    y = record.y,
    threatening = true,
}
local engagesBeforeDefense = engageTicks
T.truthy(PNC.BehaviorCompanion.Tick(record, {
    getX = function() return record.x end,
    getY = function() return record.y end,
    getZ = function() return record.z end,
}, "FollowOwner"))
T.truthy(engageTicks == engagesBeforeDefense + 1,
    "direct self-defense was blocked by the owner leash")
T.truthy(record.runtime.followState.mode == "combat_self_defense",
    "direct attacker did not short-circuit follow movement")
T.finish("pnc_follow_horde_steering_smoke")

T.finish("pnc_follow_horde_steering_smoke")
