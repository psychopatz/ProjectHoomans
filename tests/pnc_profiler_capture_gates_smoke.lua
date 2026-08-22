local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "DETAILED"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
Profiler.Start("DETAILED", { nowMs = function() return 0 end }, {
    snapshotEnabled = false,
    capture = { performance = false, moddata = false, npc = false },
})

local original = function() return "unchanged" end
PNC = {
    SpatialIndex = { Rebuild = original },
    Registry = { Data = {} },
}
package.loaded["PNC/Integrations/PNC_PsychopatzProfiler"] = nil
require "PNC/Integrations/PNC_PsychopatzProfiler"
T.equal(PNC.SpatialIndex.Rebuild, original, "disabled performance changed hot function")
T.equal(#Profiler.GetMetrics(), 0, "disabled performance allocated metrics")
T.equal(package.loaded["PNC/Integrations/PNC_PsychopatzModDataProfiler"], nil,
    "disabled ModData loaded analyzer")
T.equal(package.loaded["PNC/Integrations/PNC_PsychopatzNPCProfiler"], nil,
    "disabled NPC capture loaded analyzer")
Profiler.Stop()
T.finish("pnc_profiler_capture_gates_smoke")

T.finish("pnc_profiler_capture_gates_smoke")
