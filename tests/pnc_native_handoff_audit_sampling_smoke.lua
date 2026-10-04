local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local logCalls = 0

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
PNC = {
    Core = { Now = function() return now end },
    Const = {},
    EnginePathPlanner = {},
    PerformanceScalingDiagnostics = {
        NativeHandoffAuditEnabled = true,
        LogNativeHandoff = function()
            logCalls = logCalls + 1
            return true
        end,
    },
}

local Internal = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/"
        .. "PNC_EnginePathPlanner_Context_NativeState.lua"
)

local body = {
    getCurrentStateName = function() return "WalkTowardState" end,
    getPath2 = function() return nil end,
    isMoving = function() return true end,
}
local record = {
    id = "audit-sample",
    runtime = { localNavigation = {} },
}

T.truthy(Internal.RecordNativeHandoff(
    record, body, "before", record.runtime.localNavigation, "test"
), "first native audit sample was dropped")
T.equal(logCalls, 1, "first native audit sample count")

now = 1500
T.falsy(Internal.RecordNativeHandoff(
    record, body, "after", record.runtime.localNavigation, "test"
), "unchanged native audit boundary was not throttled")
T.equal(logCalls, 1, "unchanged native audit boundary logged repeatedly")

now = 2001
T.truthy(Internal.RecordNativeHandoff(
    record, body, "before", record.runtime.localNavigation, "test"
), "native audit did not resume after its sample interval")
T.equal(logCalls, 2, "native audit interval sample count")

body.getPath2 = function() return {} end
now = 2100
T.truthy(Internal.RecordNativeHandoff(
    record, body, "before", record.runtime.localNavigation, "test"
), "native path transition was not logged")
T.equal(logCalls, 3, "native path transition sample count")

now = 2200
T.falsy(Internal.RecordNativeHandoff(
    record, body, "after", record.runtime.localNavigation, "test"
), "native path sample ignored its shorter interval")
T.equal(logCalls, 3, "native path state logged repeatedly")

T.truthy(Internal.RecordNativeHandoff(
    record, body, "forced", record.runtime.localNavigation, "test", true
), "forced native audit sample was dropped")
T.equal(logCalls, 4, "forced native audit sample count")

T.finish("pnc_native_handoff_audit_sampling_smoke")
