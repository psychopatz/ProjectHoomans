local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "shared" },
})

local sampleCallback
Events = { EveryOneSecond = {
    Add = function(callback) sampleCallback = callback end,
    Remove = function(callback) if sampleCallback == callback then sampleCallback = nil end end,
} }
getTimeInMillis = function() return 1000 end
package.preload["PsychopatzCore/Profiler/PsychopatzProfilerClient"] = function()
    return { Start = function() return true end, Stop = function() return true end }
end

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "DETAILED"
Bootstrap.captureConfig = Bootstrap.BuildConfig({ mode = "DETAILED", capture = "performance" })
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
Profiler.Start("DETAILED", { nowMs = getTimeInMillis }, {
    snapshotEnabled = false, capture = { performance = true },
})

local original = function() return "original" end
PNC = { SpatialIndex = { Rebuild = original }, Registry = { Data = {}, LiveByID = {} },
    WorldCensus = { OrdinaryZombies = {}, ManagedBodies = {} }, Scheduler = { Buckets = {} } }
local Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
assert(PNC.SpatialIndex.Rebuild ~= original, "performance was not initially wrapped")

local result = Bootstrap.ApplyCaptureConfig({ mode = "DETAILED", capture = { "moddata" } })
T.equal(result.applied, true, "ModData live configuration")
T.equal(result.restart_required, false, "live controller requested restart")
T.equal(PNC.SpatialIndex.Rebuild, original, "disabled performance wrapper survived")
T.equal(Profiler.IsSectionEnabled("moddata"), true, "ModData capture not enabled")
assert(Profiler.GetState().snapshotProviders["ProjectHoomans.modData"], "ModData provider missing")

result = Bootstrap.ApplyCaptureConfig({ mode = "DETAILED", capture = { "performance" } })
T.equal(result.applied, true, "performance live configuration")
assert(PNC.SpatialIndex.Rebuild ~= original, "performance wrapper not restored live")
Profiler.Stop()
T.equal(PNC.SpatialIndex.Rebuild, original, "live wrapper did not restore")

T.finish("pnc_profiler_live_reconfigure_smoke")
