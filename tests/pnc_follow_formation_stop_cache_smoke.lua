local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local scans = 0
local owner = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 7 end,
    getForwardDirection = function()
        return {
            getX = function() return 0 end,
            getY = function() return 1 end,
        }
    end,
}
local record = {
    id = "stop-cache-follower",
    ownerOnlineID = 7,
    ownerUsername = "alice",
    orderSpec = { kind = "follow" },
    runtime = {},
}

PNC = {
    Core = { Now = function() return now end },
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
        FOLLOW_RETARGET_OWNER_DISTANCE = 0.75,
        FOLLOW_RETARGET_MAX_MS = 650,
    },
    BehaviorCompanion = { Internal = {} },
    Registry = {
        ForEach = function(callback)
            scans = scans + 1
            callback(record)
        end,
    },
    TraversalQuery = {},
}

local Internal = PNC.BehaviorCompanion.Internal
Internal.GetFollowState = function(value)
    value.runtime.followState = value.runtime.followState or {}
    return value.runtime.followState
end
Internal.GetFollowOwnerKey = function()
    return "id:7"
end
Internal.ResolveOwnerForward = function()
    return 0, 1
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation.lua"
)

local target = Internal.ResolveSampledFollowSlot(record, owner, true, now)
T.truthy(target, "moving follower did not receive a formation target")
T.equal(scans, 1, "initial formation target did not build one cache")

now = 1100
local stoppedTarget = Internal.ResolveSampledFollowSlot(
    record,
    owner,
    false,
    now
)
T.equal(stoppedTarget, target,
    "owner stop replaced a still-fresh formation target")
T.equal(scans, 1,
    "owner stop rebuilt the formation cache for the same follower")
T.falsy(record.runtime.followState.sampledOwnerMoving,
    "owner stop did not update the sampled motion state")

T.finish("pnc_follow_formation_stop_cache_smoke")
