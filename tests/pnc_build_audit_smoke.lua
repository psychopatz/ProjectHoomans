-- The build pipeline audit is the trace surface used to diagnose a build that
-- opens an overlay and then vanishes. It must register with the central debug
-- settings, stay silent and allocation-free while disabled, and carry one
-- correlation id plus millisecond stamps when enabled.
local T = require "tests/support/test"
T.addPackagePaths()

local definitions = {}
local lines = {}

PNC = {
    Core = {
        LogInfo = function(message) lines[#lines + 1] = message end,
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

local Diagnostics = T.load("ProjectHoomans", "shared",
    "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua")
local BuildAudit = T.load("ProjectHoomans", "shared",
    "PNC/Core/Diagnostics/PNC_BuildAudit.lua")

local setting = definitions["ProjectHoomans.BuildAudit"]
T.truthy(setting, "build audit setting was registered")
T.falsy(setting.defaultEnabled, "build audit defaults off")
T.truthy(setting.runtimeMutable, "build audit is runtime mutable")
T.falsy(BuildAudit.Enabled(), "build audit starts disabled")
T.falsy(BuildAudit.Log("placement_cancel", { "reason=test" }),
    "disabled build audit does not log")
T.equal(#lines, 0, "disabled build audit writes nothing")

setting.apply(true)
T.truthy(BuildAudit.Enabled(), "build audit applies at runtime")
T.truthy(BuildAudit.Log("placement_cancel", { "reason=placement_restart" }),
    "enabled build audit logs")
T.equal(#lines, 1, "enabled build audit writes one line")
T.contains(lines[1], "build_audit", "audit line carries the channel tag")
T.contains(lines[1], "stage=placement_cancel", "audit line carries the stage")
T.contains(lines[1], "reason=placement_restart",
    "audit line carries the reason")
T.contains(lines[1], "t=", "audit line carries a millisecond stamp")

-- Correlation between the click, the request and the verdict.
local traceId = BuildAudit.TraceId()
T.truthy(type(traceId) == "string" and traceId ~= "",
    "trace id is a non-empty string")
T.truthy(BuildAudit.MarkSent(traceId), "request send time was recorded")
T.truthy(BuildAudit.ElapsedMs(traceId) ~= nil,
    "elapsed time is available for a sent request")
T.contains(BuildAudit.ElapsedField(traceId, "rtt_ms"), "rtt_ms=",
    "elapsed field is labelled")
T.equal(BuildAudit.ElapsedField("build-unknown", "rtt_ms"), "rtt_ms=?",
    "unknown request reports an unknown elapsed time")

local request = BuildAudit.RequestField(traceId)
T.contains(request, "req=" .. traceId, "request field carries the trace id")

-- The gate must survive a module that loads before the diagnostics channel.
local savedChannel = PNC.PerformanceScalingDiagnostics
PNC.PerformanceScalingDiagnostics = nil
T.falsy(BuildAudit.Enabled(), "missing channel keeps the audit disabled")
T.falsy(BuildAudit.Log("click", { "button=test" }),
    "missing channel does not log")
T.equal(BuildAudit.NowMs(), 0,
    "missing channel falls back to a zero clock")
PNC.PerformanceScalingDiagnostics = savedChannel

T.finish("pnc_build_audit_smoke")
