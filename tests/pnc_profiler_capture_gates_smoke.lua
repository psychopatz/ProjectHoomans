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
equal(PNC.SpatialIndex.Rebuild, original, "disabled performance changed hot function")
equal(#Profiler.GetMetrics(), 0, "disabled performance allocated metrics")
equal(package.loaded["PNC/Integrations/PNC_PsychopatzModDataProfiler"], nil,
    "disabled ModData loaded analyzer")
equal(package.loaded["PNC/Integrations/PNC_PsychopatzNPCProfiler"], nil,
    "disabled NPC capture loaded analyzer")
Profiler.Stop()

print("pnc profiler capture gates: ok")
