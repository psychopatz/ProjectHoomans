local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

local clock = 1000
local lease = {
    leaseId = "lease:1", npcId = "camped", sourceDomain = "work",
}
local cancelCalls = 0
local cancelReason
local fallbackCalls = 0
local emitted = {}
local changes = {}

local record = {
    id = "camped", alive = true, anchorX = 10, anchorY = 10, anchorZ = 0,
    runtime = { workOrderId = "work:1" },
    orderSpec = { kind = "production_work", workOrderId = "work:1" },
}

PNC = {
    Const = {
        ORDER_CAMP = "camp", ORDER_GUARD = "guard",
        ORDER_FOLLOW = "follow", ORDER_PATROL = "patrol",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
    },
    Core = {
        Now = function() return clock end,
        DeepCopy = deepCopy,
        LogWarn = function() end,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
        MarkDirty = function() end,
    },
    Scheduler = { SLOT_MS = 50, Schedule = function() end },
    PathService = { Commands = { Reset = function() end } },
    TaskLeaseService = {
        ForNPC = function() return lease end,
    },
    Tasking = {
        Commands = {},
        Events = { Emit = function(eventType, payload)
            emitted[#emitted + 1] = { eventType = eventType, payload = payload }
        end },
    },
    CampResourceService = {
        OnOrderChanged = function(_, previous, current)
            changes[#changes + 1] = { previous = previous, current = current }
        end,
    },
}

require "PNC/Core/Orders/PNC_OrderSystem"
local OrderSystem = PNC.OrderSystem
OrderSystem.RegisterNormalizer("camp", function(_, spec)
    return { kind = "camp", campId = spec.campId }
end)

PNC.Tasking.Commands.CancelLease = function(leaseId, reason)
    cancelCalls = cancelCalls + 1
    cancelReason = reason
    T.equal(leaseId, "lease:1", "work lease id")
    -- Simulate the real release path restoring the previous durable order.
    record.runtime.workOrderId = nil
    OrderSystem.SetOrder(record, { kind = "guard" })
    return true
end

OrderSystem.SetOrder(record, { kind = "camp", campId = "camp:1" })
T.equal(cancelCalls, 1, "active work lease cancelled on camp entry")
T.equal(cancelReason, "camp_entered", "camp cancellation reason")
T.equal(record.orderSpec.kind, "camp", "camp remains the durable order")
T.equal(record.runtime.workOrderId, nil, "work assignment cleared")
T.equal(#emitted, 1, "camp entry emits one needs refresh")
T.equal(emitted[1].eventType, "NPC_NEEDS_CHANGED", "camp refresh event")
T.equal(emitted[1].payload.cause, "CAMP_ENTERED", "camp refresh cause")
T.equal(#changes, 2, "restore and camp order changes observed")
T.equal(changes[2].previous.kind, "guard",
    "camp order is installed after work restoration")

for _, domain in ipairs({ "farming", "fishing", "scavenge" }) do
    lease.sourceDomain = domain
    record.orderSpec = { kind = "guard" }
    record.runtime.workOrderId = nil
    OrderSystem.SetOrder(record, { kind = "camp", campId = "camp:" .. domain })
end
T.equal(cancelCalls, 4, "camp cancels blocked non-work task domains")

lease = nil
record.orderSpec = { kind = "production_work", workOrderId = "work:2" }
record.runtime.workOrderId = "work:2"
PNC.WorkService = { Commands = {
    ReleaseWorker = function(workerId, reason)
        fallbackCalls = fallbackCalls + 1
        T.equal(workerId, "camped", "fallback worker id")
        T.equal(reason, "camp_entered", "fallback release reason")
        record.runtime.workOrderId = nil
        return true
    end,
} }

OrderSystem.SetOrder(record, { kind = "camp", campId = "camp:2" })
T.equal(fallbackCalls, 1, "legacy work assignment released on camp entry")
T.equal(record.orderSpec.kind, "camp", "fallback still installs camp")

return T.finish("pnc_camp_work_release_smoke")
