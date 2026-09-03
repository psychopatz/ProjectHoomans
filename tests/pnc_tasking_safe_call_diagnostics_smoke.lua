local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "server" } })

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local warnings = {}
PNC = {
    Core = {
        Now = function() return now end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
    },
    Tasking = {
        Commands = {},
        Queries = {},
        Events = {},
        Inbox = {},
        Providers = {},
        Executors = {},
        Internal = {},
        Diagnostics = {
            counters = { callbackFailures = 0 },
            recentFailures = {},
        },
    },
    TaskPriority = {},
    TaskLeaseService = {},
    PerformanceScalingDiagnostics = {},
}

local Tasking = T.load("ProjectHoomans", "server",
    "PNC/Tasking/Tasking/PNC_Tasking_Core.lua")

local safe, _, reason = Tasking.Internal.SafeCall(
    "executor.tick",
    function() error("provider exploded", 0) end,
    { npcId = "darin", leaseId = "lease-1", domain = "needs" }
)
T.falsy(safe, "callback failure remains contained")
T.contains(reason, "provider exploded", "callback reason is returned")
T.equal(Tasking.Diagnostics.counters.callbackFailures, 1,
    "callback failure counter increments")
T.equal(#warnings, 1, "callback failure is visible in the warning log")
T.contains(warnings[1], "stage=executor.tick", "warning includes stage")
T.contains(warnings[1], "npc=darin", "warning includes npc")
T.contains(warnings[1], "lease=lease-1", "warning includes lease")
T.contains(warnings[1], "domain=needs", "warning includes domain")
T.contains(warnings[1], "provider exploded", "warning includes error")

Tasking.Internal.SafeCall(
    "executor.tick",
    function() error("provider exploded", 0) end,
    { npcId = "darin", leaseId = "lease-1", domain = "needs" }
)
T.equal(#warnings, 1, "identical callback failures are rate limited")

T.finish("pnc_tasking_safe_call_diagnostics_smoke")
