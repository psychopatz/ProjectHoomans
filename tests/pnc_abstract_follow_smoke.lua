local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_DISTANCE = 1.8,
    },
    Core = {},
    BehaviorCommon = {},
    BehaviorCompanion = { Internal = {} },
}

local now = 0
local owner = {
    x = 30,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getUsername = function() return "owner" end,
    getOnlineID = function() return 42 end,
}

PNC.Core.Now = function() return now end
PNC.Core.Distance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end
PNC.BehaviorCompanion.Internal.GetFollowState = function(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState or {}
    return record.runtime.followState
end
PNC.BehaviorCommon.GetOwner = function(record)
    return record.testOwner
end
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
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua"
)

local record = {
    id = "abstract_follower",
    x = 0,
    y = 0,
    z = 0,
    anchorX = -20,
    anchorY = 0,
    anchorZ = 0,
    ownerUsername = "owner",
    ownerOnlineID = 42,
    orderSpec = { kind = "follow" },
    runtime = {
        target = { kind = "zombie" },
        attackAction = { finishAt = 9000 },
    },
    testOwner = owner,
}

now = 3000
PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
T.truthy(record.x > 0, "abstract follower did not move toward its owner")
T.equal(record.activeJob, "FollowOwner", "abstract follower job")
T.equal(
    record.activeBehavior,
    "FollowOwner:abstract",
    "abstract follower behavior"
)
T.equal(record.runtime.followState.mode, "abstract_follow",
    "abstract follower mode")
T.falsy(record.runtime.target, "abstract follower clears stale combat target")
T.falsy(record.runtime.attackAction,
    "abstract follower clears stale attack action")

record.testOwner = nil
now = 6000
local previousX = record.x
PNC.BehaviorCompanion.Internal.TickAbstractFollowOwner(record, now)
T.truthy(record.x < previousX,
    "ownerless abstract follower did not return toward its anchor")
T.equal(record.runtime.followState.mode, "returning_to_anchor",
    "ownerless abstract follower mode")

T.finish("pnc_abstract_follow_smoke")
