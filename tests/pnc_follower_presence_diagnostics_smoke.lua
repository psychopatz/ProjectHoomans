local T = require "tests/support/test"
T.addPackagePaths()

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

local beforeBoundedBurst = logCount
for i = 1, 40 do
    Diagnostics.LogFollowerPresence("client_presence_position", {
        "npc=npc-" .. tostring(i),
    })
end
T.equal(
    logCount - beforeBoundedBurst,
    8,
    "position audit is capped per time window"
)
T.truthy(
    (Diagnostics.FollowerPresenceAuditBudget.dropped or 0) > 0,
    "bounded follower audit records dropped events without logging them"
)

definition.apply(false)
T.falsy(
    Diagnostics.IsFollowerPresenceAuditEnabled(),
    "follower audit can be disabled at runtime"
)
T.falsy(
    Diagnostics.LogFollowerPresence("disabled_again", { "unexpected=true" }),
    "disabled follower audit remains silent"
)
T.equal(logCount, 9, "disabled follower audit has no logger overhead")

local traversalDefinition = definitions["ProjectHoomans.PresenceTraversalAudit"]
T.truthy(traversalDefinition, "presence traversal setting was registered")
T.falsy(traversalDefinition.defaultEnabled, "traversal audit defaults off")
T.truthy(traversalDefinition.runtimeMutable, "traversal audit is runtime mutable")
T.falsy(
    Diagnostics.IsPresenceTraversalAuditEnabled(),
    "traversal audit starts disabled"
)
traversalDefinition.apply(true)
T.truthy(
    Diagnostics.IsPresenceTraversalAuditEnabled(),
    "traversal audit applies at runtime"
)
T.truthy(
    Diagnostics.LogPresenceTraversal("enabled", { "expected=true" }),
    "enabled traversal audit logs"
)
T.equal(logCount, 10, "enabled traversal audit emits one log")
traversalDefinition.apply(false)
T.falsy(
    Diagnostics.IsPresenceTraversalAuditEnabled(),
    "traversal audit can be disabled at runtime"
)

T.finish("pnc_follower_presence_diagnostics_smoke")
