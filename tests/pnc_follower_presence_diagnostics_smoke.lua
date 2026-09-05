local T = require "tests/support/test"

local definitions = {}
local logCount = 0

PNC = {
    Core = {
        LogInfo = function() logCount = logCount + 1 end,
    },
}
PsychopatzCore = {
    DebugSettings = {
        Register = function(definition)
            definitions[definition.id] = definition
        end,
        IsEnabled = function() return false end,
    },
}

local Diagnostics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua"
)
local definition = definitions["ProjectHoomans.FollowerPresenceAudit"]

T.truthy(definition, "follower presence setting was registered")
T.falsy(definition.defaultEnabled, "follower audit defaults off")
T.truthy(definition.runtimeMutable, "follower audit is runtime mutable")
T.falsy(
    Diagnostics.IsFollowerPresenceAuditEnabled(),
    "follower audit starts disabled"
)
T.falsy(
    Diagnostics.LogFollowerPresence("disabled", { "unexpected=true" }),
    "disabled follower audit does not log"
)
T.equal(logCount, 0, "disabled follower audit does not call the logger")

definition.apply(true)
T.truthy(
    Diagnostics.IsFollowerPresenceAuditEnabled(),
    "follower audit applies at runtime"
)
T.truthy(
    Diagnostics.LogFollowerPresence("enabled", { "expected=true" }),
    "enabled follower audit logs"
)
T.equal(logCount, 1, "enabled follower audit emits one log")

definition.apply(false)
T.falsy(
    Diagnostics.IsFollowerPresenceAuditEnabled(),
    "follower audit can be disabled at runtime"
)
T.falsy(
    Diagnostics.LogFollowerPresence("disabled_again", { "unexpected=true" }),
    "disabled follower audit remains silent"
)
T.equal(logCount, 1, "disabled follower audit has no logger overhead")

T.finish("pnc_follower_presence_diagnostics_smoke")
