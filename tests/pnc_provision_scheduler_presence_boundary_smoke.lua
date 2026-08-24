local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Provision/"
local entry = T.read(ROOT .. "PNC_ProvisionScheduler.lua")
local providers = ROOT .. "ProvisionScheduler/"
local queue = T.read(providers .. "PNC_ProvisionScheduler_Queue.lua")
local audit = T.read(providers .. "PNC_ProvisionScheduler_Audit.lua")
local processing = T.read(
    providers .. "PNC_ProvisionScheduler_Processing.lua"
)
local pump = T.read(providers .. "PNC_ProvisionScheduler_Pump.lua")

T.contains(entry, "PNC.ProvisionScheduler.Internal",
    "entry owns the internal namespace")
T.contains(queue, "function Scheduler.MarkDirty",
    "public queue mutation remains available")
T.contains(audit, "function Scheduler.Audit",
    "public audit remains available")
T.contains(processing, "function Scheduler.ReconcileRecord",
    "public forced reconciliation remains available")
T.contains(pump, "function Scheduler.Pump",
    "public bounded pump remains available")
T.falsy(string.find(entry, "function Scheduler.Pump", 1, true),
    "entry contains wiring rather than implementation")
