PNC = PNC or {}
PNC.NPCProfiler = PNC.NPCProfiler or {}

local NPCProfiler = PNC.NPCProfiler
local Profiler = PsychopatzCore and PsychopatzCore.Profiler
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local Content = require "PNC/Integrations/PNC_PsychopatzModDataContent"

if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then
    return NPCProfiler
end

function NPCProfiler.Scan()
    local config = Bootstrap.GetCaptureConfig()
    return Content.Scan({ scope = config.npcScope, ids = config.npcIDs })
end

function NPCProfiler.Register(config)
    Profiler = PsychopatzCore and PsychopatzCore.Profiler
    if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then return false end
    config = config or Bootstrap.GetCaptureConfig()
    return Profiler.RegisterSnapshotProvider("ProjectHoomans.npcData", NPCProfiler.Scan, {
        section = "npc", intervalMs = config.npcIntervalMs,
    })
end

NPCProfiler.Register(Bootstrap.GetCaptureConfig())

return NPCProfiler
