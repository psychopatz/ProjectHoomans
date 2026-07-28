local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Behaviors/PNC_Behavior_Companion.lua"

local now = 1000
local scans = 0
local records = {}
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
        x = 10 + index,
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
        FOLLOW_IDLE_ENTER_DISTANCE = 2.4,
        FOLLOW_IDLE_EXIT_DISTANCE = 3.2,
        FOLLOW_RUN_DISTANCE = 8,
        FOLLOW_SLOT_DISTANCE = 1.5,
        FOLLOW_SLOT_LATERAL = 0.95,
        FOLLOW_SLOT_ROW_DISTANCE = 0.75,
        FOLLOW_SLOT_ROW_LATERAL = 0.2,
        FOLLOW_SLOT_STOP_DISTANCE = 0.65,
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
        MoveRecord = function() return true end,
    },
    BehaviorTargeting = {
        ResolveCompanionEngageTarget = function() return nil end,
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

dofile(FILE)

for index = 1, #records do
    assert(PNC.BehaviorCompanion.Tick(records[index], {}, "FollowOwner"))
end
assert(scans == 1, "each follower rebuilt the same formation")
local firstTarget = records[1].runtime.followSlotTarget

now = 1100
for index = 1, #records do
    PNC.BehaviorCompanion.Tick(records[index], {}, "FollowOwner")
end
assert(scans == 1, "formation cache expired too early")
assert(
    records[1].runtime.followSlotTarget == firstTarget,
    "follow steering target was reallocated"
)

now = 1300
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
assert(scans == 2, "formation cache did not refresh after its window")

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
now = 1600
PNC.BehaviorCompanion.Tick(records[1], {}, "FollowOwner")
assert(
    records[1].runtime.followSlotTarget.x == owner:getX()
        and records[1].runtime.followSlotTarget.y == owner:getY(),
    "indoor formation slot remained across a building wall"
)

print("pnc_follow_formation_cache_smoke: ok")
