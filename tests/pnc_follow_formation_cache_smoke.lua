local T = require "tests/support/test"

local LUA_ROOT =
    T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

local FILE =
    LUA_ROOT .. "PNC/Core/"
    .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion.lua"

local now = 1000
local scans = 0
local targetScans = 0
local records = {}
local moves = {}
local ownerMoving = true
local owner = {
    getForwardDirection = function()
        return {
            getX = function() return 0 end,
            getY = function() return 1 end,
        }
    end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "alice" end,
    getVehicle = function() return nil end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isPlayerMoving = function() return ownerMoving end,
    isRunning = function() return false end,
    isSprinting = function() return false end,
}

for index = 1, 5 do
    records[index] = {
        id = "follower_" .. tostring(index),
        alive = true,
        attackType = "auto",
        orderSpec = { kind = "follow" },
        ownerOnlineID = 7,
        ownerUsername = "alice",
        presenceState = "live",
        runtime = {},
        x = 2 + (index * 0.2),
        y = 0,
        z = 0,
    }
end

PNC = {
    Const = {
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_FORMATION_CACHE_MS = 250,
        FOLLOW_FORMATION_MOVING_CACHE_MS = 200,
        FOLLOW_FORMATION_IDLE_CACHE_MS = 1000,
        FOLLOW_THREAT_ACTIVE_SCAN_MS = 150,
        FOLLOW_THREAT_IDLE_SCAN_MS = 350,
        FOLLOW_IDLE_ENTER_DISTANCE = 2.4,
        FOLLOW_IDLE_EXIT_DISTANCE = 3.2,
        FOLLOW_RUN_DISTANCE = 8,
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
        FOLLOW_PERSONAL_SPACE_MIN = 1.25,
        ORDER_FOLLOW = "follow",
    },
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        Now = function() return now end,
    },
    Animation = {},
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        GetOwner = function() return owner end,
        HaltMovement = function() end,
        MoveRecord = function(record, _, x, y, z, mode, stopDistance)
            moves[tostring(record.id)] = {
                x = x,
                y = y,
                z = z,
                mode = mode,
                stopDistance = stopDistance,
            }
            return true
        end,
    },
    BehaviorTargeting = {
        ResolveCompanionEngageTarget = function()
            targetScans = targetScans + 1
            return nil
        end,
    },
    BehaviorCombat = {},
    Perception = {},
    Registry = {
        ForEach = function(callback)
            scans = scans + 1
            for index = 1, #records do
                callback(records[index])
            end
        end,
    },
}

T.load(FILE)

for index = 1, #records do
    T.truthy(PNC.BehaviorCompanion.Tick(records[index], {}, "FollowOwner"))
end
T.truthy(scans == 1, "each follower rebuilt the same formation")
T.truthy(targetScans == 5,
    "initial follower safety scans did not run")
local firstTarget = records[1].runtime.followSlotTarget

now = 1100
for index = 1, #records do
    PNC.BehaviorCompanion.Tick(records[index], {}, "FollowOwner")
end
T.truthy(scans == 1, "formation cache expired too early")
T.truthy(targetScans == 5,
    "active follower threat scans ignored their negative cache")
T.truthy(
    records[1].runtime.followSlotTarget == firstTarget,
    "follow steering target was reallocated"
)

-- Being close to the owner is not itself a valid formation hold. A lone
-- follower inside personal space must move back to its assigned rear slot.
now = 1251
ownerMoving = false
records = {
    {
        id = "solo",
        alive = true,
        attackType = "auto",
        orderSpec = { kind = "follow" },
        ownerOnlineID = 7,
        ownerUsername = "alice",
        presenceState = "live",
        runtime = {},
        x = 0.25,
        y = 0,
        z = 0,
    },
}
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
T.truthy(targetScans == 6,
    "new follower did not perform an initial safety scan")
local soloMove = moves.solo
T.truthy(soloMove ~= nil,
    "close follower accepted a player-blocking hold position")
T.truthy(
    math.sqrt((soloMove.x * soloMove.x)
        + (soloMove.y * soloMove.y)) >= 2.2,
    "solo follow slot remained inside player personal space"
)
T.truthy(soloMove.stopDistance <= 0.35,
    "follow slot tolerance erased the configured spacing")

now = 1300
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
T.truthy(scans == 2, "formation cache did not refresh after its window")
T.truthy(targetScans == 6,
    "idle follower repeated a cached threat scan")

local building = {}
local room = {}
owner.getSquare = function()
    return {
        getBuilding = function() return building end,
        getRoom = function() return room end,
    }
end
getCell = function()
    return {
        getGridSquare = function()
            return {
                getBuilding = function() return nil end,
                getRoom = function() return nil end,
            }
        end,
    }
end
records[1].x = 4
records[1].runtime.followState.sampledTargetExpiresAt = 0
now = 1600
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
T.truthy(targetScans == 6,
    "stationary follower threat cache expired too early")
T.truthy(
    records[1].runtime.followSlotTarget.x == owner:getX()
        and records[1].runtime.followSlotTarget.y == owner:getY(),
    "indoor formation slot remained across a building wall"
)
T.truthy(
    records[1].runtime.followSlotTarget.stopDistance == 1.6,
    "indoor doorway approach collapsed into the player's body"
)

now = 1601
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
T.truthy(targetScans == 7,
    "stationary follower safety scan did not refresh on schedule")
T.finish("pnc_follow_formation_cache_smoke")

T.finish("pnc_follow_formation_cache_smoke")
