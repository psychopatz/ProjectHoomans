local function equal(actual, expected, message)
    if actual ~= expected then error((message or "mismatch") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

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
equal(PNC.SpatialIndex.Rebuild, original, "lazy controller changed OFF hot path")
equal(PsychopatzCore.Profiler, nil, "lazy controller loaded profiler backend")
assert(Bootstrap.captureControllers.ProjectHoomans, "bridge controller was not registered")

local result = Bootstrap.ApplyCaptureConfig({ mode = "DETAILED", capture = { "performance" } })
equal(result.applied, true, "bridge could not activate Project Hoomans profiler")
assert(PNC.SpatialIndex.Rebuild ~= original, "live activation did not install wrapper")
PsychopatzCore.Profiler.Stop()
equal(PNC.SpatialIndex.Rebuild, original, "live activation wrapper did not restore")

print("pnc profiler bridge lazy activation: ok")
