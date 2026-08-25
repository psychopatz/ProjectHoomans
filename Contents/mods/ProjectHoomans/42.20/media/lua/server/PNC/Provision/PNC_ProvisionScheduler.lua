-- Stable provision scheduling entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProvisionScheduler = PNC.ProvisionScheduler or {}
PNC.ProvisionScheduler.Internal =
    PNC.ProvisionScheduler.Internal or {}

local Scheduler = PNC.ProvisionScheduler
Scheduler.Queue = Scheduler.Queue or {}
Scheduler.Queued = Scheduler.Queued or {}
Scheduler.LastPumpAt = Scheduler.LastPumpAt or 0
Scheduler.LastAuditAt = Scheduler.LastAuditAt or 0
Scheduler.Bootstrapped = Scheduler.Bootstrapped == true
Scheduler.SLICE_INTERVAL_MS = 1000
Scheduler.MAX_PER_SLICE = 2
Scheduler.AUDIT_INTERVAL_MS = 10000

require "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_Queue"
require "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_Audit"
require "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_Processing"
require "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_Pump"
require "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_WorkBridge"

return Scheduler
