local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local queryCalls = 0
local zombie = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}

PNC = {
    Core = {
        Now = function() return now end,
        IsManagedNPCBody = function() return false end,
    },
    Const = {
        FOLLOW_HORDE_AVOID_RADIUS = 6.5,
        FOLLOW_HORDE_NEAR_DISTANCE = 2.4,
        FOLLOW_HORDE_AVOID_COUNT = 3,
        FOLLOW_HORDE_SCAN_MS = 150,
        COMBAT_HORDE_RADIUS = 5.5,
        ORDER_FOLLOW = "follow",
    },
    SpatialIndex = {
        QueryZombies = function()
            queryCalls = queryCalls + 1
            return { zombie }
        end,
    },
    PerformanceScalingDiagnostics = {
        Enabled = true,
        Increment = function() end,
    },
    BehaviorCompanion = { Internal = {} },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazards.lua")

local firstRecord = {
    ownerOnlineID = 7,
    ownerUsername = "alice",
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
local secondRecord = {
    ownerOnlineID = 7,
    ownerUsername = "alice",
    x = 2,
    y = 0,
    z = 0,
    runtime = {},
}
local firstBody = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local secondBody = {
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local first = PNC.BehaviorCompanion.Internal.AssessFollowHazards(
    firstRecord,
    firstBody,
    now
)
local second = PNC.BehaviorCompanion.Internal.AssessFollowHazards(
    secondRecord,
    secondBody,
    now + 1
)

T.equal(queryCalls, 1,
    "nearby followers did not share the short-lived candidate query")
T.equal(first.count, 1,
    "first follower lost its exact hazard-distance result")
T.equal(second.count, 1,
    "second follower lost its exact hazard-distance result")
T.equal(first.combatCount, 1,
    "hazard scan did not produce the combat horde count")
T.equal(second.combatCount, 1,
    "shared candidate scan did not preserve per-follower combat count")

T.finish("pnc_follow_hazard_cache_smoke")
