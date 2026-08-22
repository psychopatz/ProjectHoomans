local T = require "tests/support/test"

T.addPackagePaths()

local sampleCallback
Events = { EveryOneSecond = { Add = function(callback) sampleCallback = callback end,
    Remove = function(callback) if sampleCallback == callback then sampleCallback = nil end end } }
getTimeInMillis = function() return 2000 end
package.preload["PsychopatzCore/Profiler/PsychopatzProfilerClient"] = function()
    return { Start = function() return true end, Stop = function() return true end }
end

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "OFF"
Bootstrap.captureConfig = Bootstrap.BuildConfig({ mode = "OFF", capture = "performance" })
PsychopatzCore.BridgeBootstrap = { IsEnabled = function() return true end }
local original = function() return "original" end
PNC = { SpatialIndex = { Rebuild = original }, Registry = { Data = {}, LiveByID = {} },
    WorldCensus = { OrdinaryZombies = {}, ManagedBodies = {} }, Scheduler = { Buckets = {} } }

require "PNC/Integrations/PNC_PsychopatzProfiler"
T.equal(PNC.SpatialIndex.Rebuild, original, "lazy controller changed OFF hot path")
T.equal(PsychopatzCore.Profiler, nil, "lazy controller loaded profiler backend")
T.truthy(Bootstrap.captureControllers.ProjectHoomans, "bridge controller was not registered")

local result = Bootstrap.ApplyCaptureConfig({ mode = "DETAILED", capture = { "performance" } })
T.equal(result.applied, true, "bridge could not activate Project Hoomans profiler")
T.truthy(PNC.SpatialIndex.Rebuild ~= original, "live activation did not install wrapper")
PsychopatzCore.Profiler.Stop()
T.equal(PNC.SpatialIndex.Rebuild, original, "live activation wrapper did not restore")
T.finish("pnc_profiler_bridge_lazy_activation_smoke")

T.finish("pnc_profiler_bridge_lazy_activation_smoke")
