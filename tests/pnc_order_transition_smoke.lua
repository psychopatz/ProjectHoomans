local T = require "tests/support/test"

local LUA_ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")

local resetCount = 0
local liveBody = {}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
    },
    Core = {
        Now = function() return 1000 end,
        DeepCopy = function(value) return value end,
    },
    Registry = {
        GetLiveZombie = function(id)
            return id == "companion" and liveBody or nil
        end,
        MarkDirty = function() end,
    },
    PathService = {
        Reset = function(zombie, record)
            T.truthy(zombie == liveBody, "wrong live body reset")
            resetCount = resetCount + 1
            record.runtime.pathing = nil
            record.runtime.moveIntent = nil
        end,
    },
}

T.load(LUA_ROOT .. "Orders/PNC_OrderSystem.lua")

local record = {
    id = "companion",
    faction = "colonist",
    anchorX = 1,
    anchorY = 2,
    anchorZ = 0,
    activeJob = "FollowOwner",
    activeBehavior = "FollowOwner:moving",
    runtime = {
        moveIntent = { kind = "move", x = 20, y = 20 },
        pathing = { goal = { x = 20, y = 20 } },
        target = { kind = "zombie" },
        followState = { mode = "moving" },
    },
}

PNC.OrderSystem.SetOrder(record, {
    kind = "guard",
    x = 4,
    y = 5,
    z = 0,
})

T.truthy(record.orderSpec.kind == "guard", "guard order not installed")
T.truthy(record.orderSpec.x == 4 and record.orderSpec.y == 5,
    "guard anchor changed")
T.truthy(resetCount == 1, "live movement lane was not reset")
T.truthy(record.runtime.moveIntent == nil and record.runtime.pathing == nil,
    "stale follow movement survived order change")
T.truthy(record.runtime.target == nil and record.runtime.followState == nil,
    "stale follow/combat runtime survived order change")
T.truthy(record.activeJob == nil and record.activeBehavior == nil,
    "old behavior remained active after order change")
T.finish("pnc_order_transition_smoke")

T.finish("pnc_order_transition_smoke")
