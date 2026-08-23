local Integration = PNC.ProfilerIntegration
local Internal = Integration.Internal

function Integration.ApplyCaptureConfig(config)
    Internal.Profiler = PsychopatzCore and PsychopatzCore.Profiler
    local Profiler = Internal.Profiler
    if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then
        Integration.Restore()
        return config.mode == "OFF"
    end
    if Profiler.IsSectionEnabled("moddata") then
        Internal.ModDataProfiler =
            require "PNC/Integrations/PNC_PsychopatzModDataProfiler"
        if Internal.ModDataProfiler.Register then
            Internal.ModDataProfiler.Register(config)
        end
    else
        Internal.ModDataProfiler = nil
    end
    if Profiler.IsSectionEnabled("npc") then
        local NPCProfiler =
            require "PNC/Integrations/PNC_PsychopatzNPCProfiler"
        if NPCProfiler.Register then NPCProfiler.Register(config) end
    end
    if Profiler.IsSectionEnabled("performance") then
        Internal.InstallSharedPerformance()
        Integration.InstallServer()
        if PNC.Server and type(PNC.Server.OnTick) == "function" then
            local original = PNC.Server.OnTick
            local wrapped = Integration.WrapServerTick(original)
            if wrapped ~= original then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(original)
                end
                if Events and Events.OnTick and Events.OnTick.Add then
                    Events.OnTick.Add(wrapped)
                end
                PNC.Server.OnTick = wrapped
            end
        end
    end
    return true
end

local ProfilerFeatures =
    require "PsychopatzCore/Profiler/PsychopatzProfilerFeatureRegistry"
ProfilerFeatures.Register({
    id = "ProjectHoomans",
    namespace = "ProjectHoomans",
    displayName = "Project Hoomans",
    sections = { "performance", "moddata", "npc" },
    install = function(_, config)
        return Integration.ApplyCaptureConfig(config)
    end,
    uninstall = Integration.Restore,
})

return Integration
