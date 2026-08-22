local T = require "tests/support/test"

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
local clock, sequence = 1000, 0
PNC = { Core = {
    Now = function() return clock end,
    GenerateID = function(prefix) sequence = sequence + 1
        return prefix .. ":" .. tostring(sequence) end,
} }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Tasking/PNC_TaskRequestDefinitions.lua")
local Leases = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskLeaseService.lua")

local lease = T.truthy(Leases.Create({ npcId = "npc", taskId = "task",
    kind = "SLEEP", sourceDomain = "needs", sourceRef = "fatigue",
    precedence = "NORMAL_NEED", urgency = 0.8, capability = "sleep.bed",
    interruptPolicy = "NORMAL" }, {}))
T.truthy(Leases.SetPhase(lease.leaseId, "ATOMIC_COMMIT"),
    "lease enters atomic commit")
local ok, reason = Leases.RequestCancellation(lease.leaseId, "player")
T.truthy(ok, "atomic cancellation is recorded")
T.equal(reason, "CANCELLATION_DEFERRED", "atomic cancellation is deferred")
T.equal(lease.phase, "ATOMIC_COMMIT", "atomic phase is not interrupted")
ok, reason = Leases.RequestCancellation(lease.leaseId, "player_again")
T.truthy(ok, "repeated cancellation is idempotent")
T.equal(reason, "CANCELLATION_DEFERRED", "idempotent result remains deferred")
T.truthy(Leases.SetPhase(lease.leaseId, "WORKING"), "atomic section finishes")
T.truthy(lease.cancellationRequested, "cancellation remains pending for cleanup")

T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkDefinitions.lua")
local releasedReservation, cancelledInputs
local order = { id = "work:1", operation = "CRAFT", status = "WORKING",
    completionStarted = true, workerId = "npc", stationId = "station",
    facilityReservationId = "reservation", progress = 4, requiredWork = 10,
    revision = 1, payload = { input = { staged = true } } }
PNC.WorkRepository = {
    Get = function(id) return id == order.id and order or nil end,
    MarkDirty = function() end,
}
PNC.WorkInputService = { Cancel = function() cancelledInputs = true end }
PNC.FacilityReservations = { Release = function(id)
    releasedReservation = id; return true
end }
PNC.Registry = { Get = function() return { id = "npc", runtime = {
    workOrderId = order.id,
} } end }
PNC.OrderSystem = { SetOrder = function() end }
local Work = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkService.lua")
ok, reason = Work.Commands.Cancel(order.id, "player")
T.truthy(ok, "work cancellation is accepted during atomic completion")
T.equal(reason, "CANCELLATION_DEFERRED", "work cancellation reports deferral")
T.equal(order.status, "CANCELLING", "durable request exposes cancelling state")
T.equal(releasedReservation, nil, "atomic cancellation does not clean up early")
order.completionStarted = false
T.truthy(Work.Commands.Cancel(order.id, "player"),
    "deferred cancellation resumes through the same command")
T.equal(order.status, "CANCELLED", "deferred work reaches cancelled")
T.equal(releasedReservation, "reservation", "facility reservation is released")
T.truthy(cancelledInputs, "input reservation cleanup shares cancellation path")
T.truthy(Work.Commands.Cancel(order.id, "player_again"),
    "terminal cancellation remains idempotent")

T.finish("pnc_task_cancellation_smoke")
