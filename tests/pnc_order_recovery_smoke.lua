local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1000
local resetCalls = 0
local attackCancels = 0
local movement = {
    active = true, phase = "active", watchable = true,
    lastProgressAt = 1000,
}

local function copy(value)
    local output
    if type(value) ~= "table" then return value end
    output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local body = {
    getX = function() return 5 end,
    getY = function() return 5 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow", ORDER_CAMP = "camp",
        ORDER_GUARD = "guard", ORDER_PATROL = "patrol",
        ORDER_ROAM = "roam", ORDER_HOSTILE_ROAM = "hostile_roam",
        ORDER_HOSTILE_HUNT = "hostile_hunt", ORDER_TRAVEL = "travel",
    },
    Core = {
        Now = function() return now end,
        DeepCopy = copy,
    },
    PathService = {
        GetMovementRecoveryState = function() return movement end,
        Commands = {
            Reset = function(record)
                resetCalls = resetCalls + 1
                record.runtime.pathing = nil
                record.runtime.moveIntent = nil
            end,
        },
    },
    Registry = {
        GetLiveZombie = function() return body end,
        MarkDirty = function() end,
    },
    Combat = {
        CancelAttackAction = function(record)
            attackCancels = attackCancels + 1
            record.runtime.attackAction = nil
            return true
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Orders/PNC_OrderSystem.lua")
local OrderSystem = PNC.OrderSystem
local record = {
    id = "direct-order-npc", alive = true, x = 5, y = 5, z = 0,
    anchorX = 5, anchorY = 5, anchorZ = 0,
    orderSpec = { kind = "follow", ownerUsername = "PlayerOne" },
    runtime = {
        moveIntent = {
            kind = "move", x = 50, y = 50, z = 0,
            stopDistance = 0.7, requestedOrder = "follow",
        },
    },
}

now = 70001
T.truthy(OrderSystem.RecoverStalled(record, body, now),
    "stale direct order should be reissued")
T.equal(resetCalls, 1, "direct order recovery resets the movement owner")
T.equal(record.orderSpec.kind, "follow",
    "first direct order recovery preserves the requested order")

record.runtime.moveIntent = {
    kind = "move", x = 50, y = 50, z = 0,
    stopDistance = 0.7, requestedOrder = "follow",
}
now = 130002
T.truthy(OrderSystem.RecoverStalled(record, body, now),
    "repeated stale follow order should be retried")
T.equal(resetCalls, 2, "follow retry resets the old movement owner")
T.equal(record.orderSpec.kind, "follow",
    "repeated follow stalls preserve the player order")
T.equal(record.ownerUsername, "PlayerOne",
    "follow recovery preserves the player owner")
T.equal(record.runtime.orderRecovery.attempts, 0,
    "preserved follow order gets a fresh recovery budget")

local guardRecord = {
    id = "direct-order-guard-npc", alive = true, x = 5, y = 5, z = 0,
    anchorX = 5, anchorY = 5, anchorZ = 0,
    orderSpec = { kind = "guard", x = 50, y = 50, z = 0 },
    runtime = {
        moveIntent = {
            kind = "move", x = 50, y = 50, z = 0,
            stopDistance = 0.7, requestedOrder = "guard",
        },
    },
}
now = 200000
T.truthy(OrderSystem.RecoverStalled(guardRecord, body, now),
    "stale autonomous order should still be reissued")
guardRecord.runtime.moveIntent = {
    kind = "move", x = 50, y = 50, z = 0,
    stopDistance = 0.7, requestedOrder = "guard",
}
now = 260001
T.truthy(OrderSystem.RecoverStalled(guardRecord, body, now),
    "repeated stale autonomous order should use its safe fallback")
T.equal(guardRecord.orderSpec.kind, "guard",
    "repeated autonomous order stalls fall back to a local guard")
T.equal(guardRecord.orderSpec.x, guardRecord.x,
    "safe guard fallback is anchored at the current body position")

movement = {
    active = true, phase = "active", watchable = false, traversal = true,
    lastProgressAt = 1000,
}
record.orderSpec = { kind = "guard", x = 50, y = 50, z = 0 }
record.runtime.orderRecovery = nil
record.runtime.moveIntent = {
    kind = "move", x = 50, y = 50, z = 0,
    stopDistance = 0.7, requestedOrder = "guard",
}
T.falsy(OrderSystem.RecoverStalled(record, body, now + 100000),
    "active traversal remains owned by PathService")

movement = { active = false, phase = "idle", watchable = false }
record.runtime.orderRecovery = nil
record.runtime.moveIntent = { kind = "hold", requestedOrder = "guard" }
T.falsy(OrderSystem.RecoverStalled(record, body, now + 200000),
    "a valid hold must not be treated as a direct order stall")

record.runtime.moveIntent = {
    kind = "move", x = 50, y = 50, z = 0,
    stopDistance = 0.7, requestedOrder = "guard",
}
now = 2000
T.falsy(OrderSystem.RecoverStalled(record, body, now),
    "a newly missing path lane gets a coordination grace period")
now = 17001
T.truthy(OrderSystem.RecoverStalled(record, body, now),
    "a path lane missing beyond the grace period is recoverable")

record.runtime.attackAction = { startedAt = 1000, finishAt = 1500 }
now = 30000
T.truthy(OrderSystem.RecoverStalled(record, body, now),
    "an expired committed attack action is recoverable")
T.equal(attackCancels, 1, "expired attack action is cancelled once")

T.finish("pnc_order_recovery_smoke")
