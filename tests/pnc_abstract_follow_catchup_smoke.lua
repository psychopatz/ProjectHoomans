local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

-- Exercises the REAL abstract motion pipeline (MoveRecord -> AdvanceAbstract)
-- instead of a mocked mover, so catch-up tuning cannot silently regress.
PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_RUN_DISTANCE = 10.0,
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        TICK_ABSTRACT_MS = 3000,
        ABSTRACT_TRAVEL_SPEED = 1.6666667,
        ABSTRACT_FOLLOW_CATCHUP_SPEED = 5.0,
        ABSTRACT_FOLLOW_LONG_RANGE_DISTANCE = 64,
        ABSTRACT_FOLLOW_LONG_RANGE_CLOSE = 0.35,
        ABSTRACT_FOLLOW_LONG_RANGE_SPEED = 80,
    },
    Core = {
        Now = function() return 0 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    BehaviorCommon = {},
    BehaviorCompanion = { Internal = {} },
    PathService = {
        Internal = {
            Core = {
                Now = function() return 0 end,
                Distance = function(x1, y1, x2, y2)
                    local dx = x2 - x1
                    local dy = y2 - y1
                    return math.sqrt(dx * dx + dy * dy)
                end,
            },
        },
    },
    PerformanceScalingDiagnostics = nil,
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionApi.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Common.lua"
)

PNC.BehaviorCompanion.Internal.GetFollowState = function(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState or {}
    return record.runtime.followState
end

local ownerX = 1000
local owner = {
    getX = function() return ownerX end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getUsername = function() return "owner" end,
    getOnlineID = function() return 1 end,
}
PNC.BehaviorCommon.GetOwner = function() return owner end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua"
)

local follow = PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner

local function follower()
    return {
        id = "abstract_follower", x = 0, y = 0, z = 0,
        presenceState = "abstract",
        orderSpec = { kind = "follow" },
        runtime = { abstractStepElapsedMs = 3000 },
        ownerUsername = "owner",
        ownerOnlineID = 1,
    }
end

-- A teleport-sized gap must close by a large, bounded step per tick instead
-- of crawling at the flat catch-up speed for minutes.
local far = follower()
follow(far, 3000)
T.truthy(far.x > 200, "far abstract follower did not close a long-range gap")
T.truthy(far.x <= ownerX - PNC.Const.FOLLOW_DISTANCE,
    "long-range abstract catch-up overshot the owner")
T.equal(far.activeBehavior, "FollowOwner:abstract",
    "far abstract follower behavior label")

-- Ordinary separations keep the gentle catch-up and never overshoot.
ownerX = 20
local near = follower()
follow(near, 3000)
T.truthy(near.x > 0, "near abstract follower did not move toward owner")
T.truthy(near.x < ownerX, "near abstract follower overshot the owner")
T.truthy(near.x < 15, "near abstract follower used long-range speed")

-- The durable follow order owns the owner identity; the abstract tick must
-- recover it when the record fields were cleared (rehydration/radio orders).
ownerX = 500
PNC.BehaviorCommon.GetOwner = function(record)
    if record.ownerUsername == "owner" then return owner end
    return nil
end
local recovered = follower()
recovered.ownerUsername = nil
recovered.ownerOnlineID = nil
recovered.orderSpec = {
    kind = "follow", ownerUsername = "owner", ownerOnlineID = 1,
}
follow(recovered, 3000)
T.equal(recovered.ownerUsername, "owner",
    "abstract follower did not recover owner identity from its order")
T.truthy(recovered.x > 0,
    "ownerless-looking abstract follower walked to its anchor")

T.finish("pnc_abstract_follow_catchup_smoke")
