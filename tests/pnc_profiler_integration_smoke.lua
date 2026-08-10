local function equal(actual, expected, message)
    if actual ~= expected then error((message or "mismatch") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "BASIC"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local now = 0
local callback
Profiler.Start("BASIC", {
    nowMs = function() return now end,
    sourceType = function() return "test" end,
    addSampleCallback = function(value) callback = value end,
    removeSampleCallback = function(value) if callback == value then callback = nil end end,
})

local originalSpatial = function() return "spatial" end
PNC = {
    SpatialIndex = { Rebuild = originalSpatial },
    WorldCensus = { Refresh = function() end, OrdinaryZombies = { 1, 2 }, ManagedBodies = { 1 } },
    Perception = { GetZombieFrame = function() end },
    BehaviorSystem = { Tick = function() end },
    PathService = { Pump = function() end },
    Scheduler = { PopDue = function() end, PumpJobs = function() end, Buckets = { one = {} } },
    Registry = { Data = { a = {}, b = {} }, LiveByID = { a = {} } },
    ZombieAggro = { ActiveSet = { order = { 1, 2 }, holes = 1 } },
}

local Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
if PNC.SpatialIndex.Rebuild == originalSpatial then error("active integration did not wrap") end
equal(PNC.SpatialIndex.Rebuild(), "spatial", "wrapper changed return")
now = 1000
Profiler.Sample(1000)
local gauges = Profiler.GetMetrics("gauge", "ProjectHoomans")
if #gauges < 6 then error("Project Hoomans samplers were not registered") end
Profiler.Stop()
equal(PNC.SpatialIndex.Rebuild, originalSpatial, "stop did not restore original hot function")
equal(callback, nil, "profiler callback survived stop")

Bootstrap.mode = "OFF"
package.loaded["PNC/Integrations/PNC_PsychopatzProfiler"] = nil
local offOriginal = function() return "off" end
PNC = { SpatialIndex = { Rebuild = offOriginal } }
require "PNC/Integrations/PNC_PsychopatzProfiler"
equal(PNC.SpatialIndex.Rebuild, offOriginal, "OFF integration changed the hot path")
equal(Profiler.GetState(), nil, "OFF integration created profiler state")

print("pnc_profiler_integration_smoke: ok")
