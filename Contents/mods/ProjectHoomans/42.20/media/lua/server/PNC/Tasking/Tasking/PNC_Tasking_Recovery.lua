-- Server-authoritative task recovery composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H

Tasking.PROGRESS_TIMEOUT_MS = Tasking.PROGRESS_TIMEOUT_MS or 60000
Tasking.RECOVERY_RETRY_INTERVAL_MS =
    Tasking.RECOVERY_RETRY_INTERVAL_MS or 5000
Tasking.MAX_STALL_RECOVERY_ATTEMPTS =
    Tasking.MAX_STALL_RECOVERY_ATTEMPTS or 2
Tasking.WATCHDOG_DOMAINS = Tasking.WATCHDOG_DOMAINS or {}
Tasking.WATCHDOG_DOMAINS.work = true
-- NeedFacility now reports effect progress from FacilityJobs. Travel remains
-- outside this watchdog; PathService owns movement liveness.
Tasking.WATCHDOG_DOMAINS.NeedFacility = true
-- Direct task providers must expose the same liveness contract as the
-- durable WorkService and NeedFacility providers. Their domain-specific
-- services still own cleanup; this table only opts them into the shared
-- lease watchdog.
Tasking.WATCHDOG_DOMAINS.farming = true
Tasking.WATCHDOG_DOMAINS.fishing = true
Tasking.WATCHDOG_DOMAINS.lumber = true
Tasking.WATCHDOG_DOMAINS.scavenge = true
Tasking.WATCHDOG_DOMAINS.medical = true

require "PNC/Tasking/Tasking/PNC_Tasking_Recovery_Context"
require "PNC/Tasking/Tasking/PNC_Tasking_Recovery_Retry"
require "PNC/Tasking/Tasking/PNC_Tasking_Recovery_Stall"
require "PNC/Tasking/Tasking/PNC_Tasking_Recovery_Executor"

return Tasking
