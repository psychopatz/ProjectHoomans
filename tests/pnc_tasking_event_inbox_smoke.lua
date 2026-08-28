local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "")
PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
local clock, sequence = 1000, 0
local record = { id = "npc", alive = true, runtime = {} }
PNC = {
    Core = {
        Now = function() return clock end,
        GenerateID = function(prefix)
            sequence = sequence + 1
            return prefix .. ":" .. tostring(sequence)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = item end
            return output
        end,
    },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
        ForEach = function(callback) callback(record) end,
    },
}
Events = { OnTick = { Add = function() end } }

local Priority = T.load(ROOT .. "PNC/Tasking/PNC_TaskPriority.lua")
local Intent = T.load(ROOT .. "PNC/Tasking/PNC_TaskIntent.lua")
local Leases = T.load(ROOT .. "PNC/Tasking/PNC_TaskLeaseService.lua")
package.preload["PNC/Tasking/PNC_TaskPriority"] = function() return Priority end
package.preload["PNC/Tasking/PNC_TaskIntent"] = function() return Intent end
package.preload["PNC/Tasking/PNC_TaskLeaseService"] = function() return Leases end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload[
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"
] = function() return {} end

local Tasking = T.load(ROOT .. "PNC/Tasking/PNC_Tasking.lua")
Tasking.Initialized = true

local first = Tasking.Events.Emit("NEED_CHANGED", {
    npcId = record.id, source = "test", entityId = "hunger",
})
local second = Tasking.Events.Emit("INVENTORY_CHANGED", {
    npcId = record.id, source = "test", entityId = "food",
})
T.truthy(first and second, "task events are accepted")
T.equal(Tasking.Inbox.Count(), 1, "events coalesce by NPC")
local entry = Tasking.Inbox.Pop()
T.equal(entry.cause, "INVENTORY_CHANGED", "latest cause is selected")
local causes = Tasking.Inbox.Causes(entry)
T.equal(#causes, 2, "coalesced causes remain auditable")
T.equal(Tasking.Inbox.Count(), 0, "popping clears pending state")

local observed
local listener = function(event) observed = event end
T.truthy(Tasking.Events.Subscribe("EVENT_OBSERVED", listener, "test"),
    "task event listener registers")
T.truthy(Tasking.Events.Subscribe("EVENT_OBSERVED", listener, "test"),
    "task event listener registration is idempotent")
Tasking.Events.Emit("EVENT_OBSERVED", { npcId = record.id,
    source = "test", payload = { value = 7 } }, { enqueue = false })
T.equal(observed.payload.value, 7, "task listener receives typed event")
T.equal(Tasking.Events.ClearOwner("test"), 1,
    "task event owner cleanup removes listeners")

local safe, _, reason = Tasking.Internal.SafeCall("test_callback",
    function() error("provider exploded") end, { npcId = record.id })
T.falsy(safe, "callback failure is contained")
T.contains(reason, "provider exploded", "callback failure is recorded")
T.equal(Tasking.Diagnostics.counters.callbackFailures, 1,
    "callback failure counter increments")

local lease = T.truthy(Leases.Create({
    npcId = record.id, taskId = "task:test", kind = "TEST",
    sourceDomain = "test", sourceRef = "test", precedence = "NORMAL_WORK",
    urgency = 0.5, capability = "test",
}, {}))
local valid, invalidReason = Leases.SetPhase(lease.leaseId, "DONE")
T.falsy(valid, "lease cannot skip directly to done")
T.equal(invalidReason, "INVALID_TASK_PHASE_TRANSITION",
    "invalid phase transition has a stable reason")
T.truthy(Leases.SetPhase(lease.leaseId, "WAITING_FOR_WORLD"),
    "phase aliases normalize to the canonical waiting phase")
T.equal(lease.phase, "WAITING", "waiting phase is canonical")
T.truthy(Leases.RequestCancellation(lease.leaseId, "test"),
    "lease cancellation is recorded")
T.truthy(Leases.Release(lease.leaseId, "test"),
    "lease release remains possible after cancellation")
T.truthy(Leases.CheckInvariants(), "lease indexes remain consistent")

T.finish("pnc_tasking_event_inbox_smoke")
