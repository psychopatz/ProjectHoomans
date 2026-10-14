local T = require "tests/support/test"

local now = 1000
local warnings = 0

PNC = {
    BodyLifecycle = {
        Internal = {},
        StartupCleanup = {
            begun = false,
            active = false,
            complete = false,
            passes = 0,
            quietPasses = 0,
            startedAt = 0,
            removed = 0,
            settleUntil = 0,
            nextMaterializeAt = 0,
        },
    },
    Core = {
        Now = function() return now end,
        LogInfo = function() end,
        LogWarn = function() warnings = warnings + 1 end,
    },
    Const = {
        BODY_SHELL_STARTUP_PASSES = 3,
        BODY_SHELL_STARTUP_SETTLE_MS = 1500,
        BODY_SHELL_STARTUP_MAX_WAIT_MS = 10000,
        BODY_SHELL_MAINTENANCE_MS = 1000,
    },
}
Events = {}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_Coordinator.lua"
)

PNC.BodyLifecycle.BeginStartupBodyCleanup(1000, true)
T.falsy(
    PNC.BodyLifecycle.IsStartupBodyCleanupComplete(),
    "startup cleanup became ready before its deadline"
)

now = 11001
T.truthy(
    PNC.BodyLifecycle.IsStartupBodyCleanupComplete(),
    "startup cleanup remained fail-closed after its deadline"
)
T.truthy(
    PNC.BodyLifecycle.StartupCleanup.failedOpen == true,
    "startup deadline did not record the fail-open transition"
)
T.equal(warnings, 1, "startup fail-open warning count")

return T.finish("pnc_body_lifecycle_startup_deadline_smoke")
