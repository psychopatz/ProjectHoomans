local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local owner = {
    x = 100,
    y = 100,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getUsername = function() return "owner" end,
    getOnlineID = function() return 1 end,
}

local followers = {}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_RETARGET_MAX_MS = 650,
        ABSTRACT_TRAVEL_STEP = 5,
        ABSTRACT_TRAVEL_SPEED = 1.6666667,
        ABSTRACT_FOLLOW_CATCHUP_SPEED = 5,
        ABSTRACT_FOLLOW_LONG_RANGE_DISTANCE = 64,
        ABSTRACT_FOLLOW_LONG_RANGE_CLOSE = 0.35,
        ABSTRACT_FOLLOW_LONG_RANGE_SPEED = 80,
        TICK_ABSTRACT_MS = 3000,
    },
    Core = {
        Now = function() return 3000 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    BehaviorCommon = {},
    BehaviorCompanion = { Internal = {} },
    Registry = {
        ForEach = function(callback)
            for i = 1, #followers do callback(followers[i]) end
        end,
    },
    TraversalQuery = {},
    PerformanceScalingDiagnostics = nil,
}

PNC.BehaviorCompanion.Internal.GetFollowState = function(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState or {}
    return record.runtime.followState
end
PNC.BehaviorCompanion.Internal.ResolveOwnerForward = function()
    return 0, 1
end
PNC.BehaviorCompanion.Internal.GetFollowOwnerKey = function()
    return "id:1"
end
PNC.BehaviorCommon.GetOwner = function() return owner end
PNC.BehaviorCommon.MoveRecord = function(
    record, _, targetX, targetY, targetZ
)
    local dx = targetX - record.x
    local dy = targetY - record.y
    local length = math.sqrt(dx * dx + dy * dy)
    local step = math.min(5, length)
    if length > 0 then
        record.x = record.x + (dx / length) * step
        record.y = record.y + (dy / length) * step
    end
    record.z = targetZ
    return true, "abstract_move"
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua"
)

followers[1] = {
    id = "follower_a",
    x = 0,
    y = 0,
    z = 0,
    ownerUsername = "owner",
    ownerOnlineID = 1,
    orderSpec = { kind = "follow" },
    runtime = {},
}
followers[2] = {
    id = "follower_b",
    x = 0,
    y = 0,
    z = 0,
    ownerUsername = "owner",
    ownerOnlineID = 1,
    orderSpec = { kind = "follow" },
    runtime = {},
}

local tick = PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner
tick(followers[1], 3000)
tick(followers[2], 3000)

T.near(followers[1].x, followers[2].x, 0.0001,
    "abstract followers must use the same authoritative owner target")
T.near(followers[1].y, followers[2].y, 0.0001,
    "abstract followers must use the same authoritative owner target")
T.truthy(followers[1].x > 0 and followers[1].y > 0,
    "abstract follower did not chase the owner coordinates")

local handoff = {
    id = "follower_handoff",
    x = 80,
    y = 100,
    z = 0,
    ownerUsername = "owner",
    ownerOnlineID = 1,
    orderSpec = { kind = "follow" },
    runtime = {},
}
tick(handoff, 3000)
T.truthy(handoff.runtime.forceLive == true,
    "abstract follower did not request live handoff inside owner radius")
T.truthy(handoff.runtime.forcePresenceCheck == true,
    "abstract follower did not wake presence at owner radius")
T.finish("pnc_abstract_follow_formation_smoke")
