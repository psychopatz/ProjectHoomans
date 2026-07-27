local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local now = 1000
local spatialQueries = 0
local losChecks = 0
local zombies = {}

for i = 1, 20 do
    zombies[i] = {
        isDead = function() return false end,
        getX = function() return i * 0.5 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end

PNC = {
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        ROAM_TARGET_RADIUS = 12,
        COMBAT_HORDE_RADIUS = 5.5,
        PERCEPTION_FRAME_MS = 200,
        PERCEPTION_FRAME_MOVE_TOLERANCE = 0.5,
        PERCEPTION_LOS_MAX_CANDIDATES = 6,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function() return false end,
    },
    SpatialIndex = {
        QueryZombies = function()
            spatialQueries = spatialQueries + 1
            return zombies
        end,
    },
    Perception = {
        CanSeeWorldObject = function()
            losChecks = losChecks + 1
            return true, "clear"
        end,
    },
}

dofile(ROOT .. "Perception/PNC_Perception_Frame.lua")

local record = {
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}

local visible = PNC.Perception.GetVisibleZombieEntries(record, 12)
assert(#visible == 6, "LOS candidate budget was not enforced")
assert(losChecks == 6, "unexpected LOS check count")
assert(PNC.Perception.CountZombiesInFrame(record, 3) == 6,
    "multi-radius count did not reuse the frame")
assert(spatialQueries == 1,
    "perception count rebuilt an already-valid frame")

record.x = 0.2
PNC.Perception.GetVisibleZombieEntries(record, 12)
assert(spatialQueries == 1 and losChecks == 6,
    "small observer movement invalidated the reusable frame")

now = 1300
PNC.Perception.GetVisibleZombieEntries(record, 12)
assert(spatialQueries == 2 and losChecks == 12,
    "expired perception frame was not rebuilt")

local blockedRecord = {
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
PNC.Perception.CanSeeWorldObject = function(_, zombie)
    losChecks = losChecks + 1
    return zombie:getX() > 3, "blocked_test"
end
now = 2000
assert(#PNC.Perception.GetVisibleZombieEntries(blockedRecord, 12) == 0,
    "blocked first LOS window unexpectedly found a target")
now = 2300
assert(#PNC.Perception.GetVisibleZombieEntries(blockedRecord, 12) > 0,
    "blocked LOS window did not rotate to farther candidates")

print("pnc_perception_frame_smoke: ok")
