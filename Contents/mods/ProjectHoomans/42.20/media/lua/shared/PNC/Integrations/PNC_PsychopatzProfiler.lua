-- Project Hoomans owns names and observation points only. PsychopatzCore owns
-- the profiler engine, lifecycle, histories, snapshots, and UI.
PNC = PNC or {}
PNC.ProfilerIntegration = PNC.ProfilerIntegration or {}

local Integration = PNC.ProfilerIntegration
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"

if not Bootstrap.IsEnabled() then
    return Integration
end

local Profiler = PsychopatzCore and PsychopatzCore.Profiler
if not Profiler or not Profiler.IsRunning() then return Integration end

local function wrap(owner, key, metricName)
    if not owner or type(owner[key]) ~= "function" then return false end
    Integration.originals = Integration.originals or {}
    if Integration.originals[metricName] then return false end
    Integration.originals[metricName] = { owner = owner, key = key, callback = owner[key] }
    owner[key] = Profiler.Wrap(metricName, owner[key])
    return true
end

local function countMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do count = count + 1 end
    return count
end

function Integration.Restore()
    for _, entry in pairs(Integration.originals or {}) do
        if entry.owner and entry.owner[entry.key] then entry.owner[entry.key] = entry.callback end
    end
    Integration.originals = nil
    Integration.serverInstalled = false
end

Profiler.RegisterNamespace("ProjectHoomans", { displayName = "Project Hoomans" })
Profiler.RegisterStopHook("ProjectHoomans.restore", Integration.Restore)

wrap(PNC.SpatialIndex, "Rebuild", "ProjectHoomans.Spatial.Rebuild")
wrap(PNC.WorldCensus, "Refresh", "ProjectHoomans.WorldCensus.Refresh")
wrap(PNC.Perception, "GetZombieFrame", "ProjectHoomans.CompanionAI.Perception")
wrap(PNC.BehaviorSystem, "Tick", "ProjectHoomans.CompanionAI.Decision")
wrap(PNC.PathService, "Pump", "ProjectHoomans.CompanionAI.Pathfinding")
wrap(PNC.Scheduler, "PopDue", "ProjectHoomans.Scheduler.PopDue")
wrap(PNC.Scheduler, "PumpJobs", "ProjectHoomans.Director.ScheduledJobs")
wrap(PNC.Network, "BroadcastRecord", "ProjectHoomans.Network.BroadcastRecord")
wrap(PNC.Network, "FlushRosterDeltas", "ProjectHoomans.Network.FlushRosterDeltas")

Profiler.RegisterSampler("ProjectHoomans.shared", function(api)
    local Registry = PNC.Registry
    local Census = PNC.WorldCensus
    local Aggro = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
    api.SetGauge("ProjectHoomans.NPC.Total", countMap(Registry and Registry.Data))
    api.SetGauge("ProjectHoomans.NPC.Live", countMap(Registry and Registry.LiveByID))
    api.SetGauge("ProjectHoomans.World.LoadedZombies", #(Census and Census.OrdinaryZombies or {}))
    api.SetGauge("ProjectHoomans.World.ManagedBodies", #(Census and Census.ManagedBodies or {}))
    api.SetGauge("ProjectHoomans.ZombieAggro.Active", Aggro and (#Aggro.order - (Aggro.holes or 0)) or 0)
    api.SetGauge("ProjectHoomans.Scheduler.PendingBuckets", countMap(PNC.Scheduler and PNC.Scheduler.Buckets))
end)

function Integration.InstallServer()
    if Integration.serverInstalled then return false end
    wrap(PNC.WorldDirector, "Pump", "ProjectHoomans.Director.Update")
    wrap(PNC.PopulationDirector, "Pump", "ProjectHoomans.Director.Population")
    wrap(PNC.PersistenceCoordinator, "Commit", "ProjectHoomans.Persistence.Commit")
    Profiler.RegisterSampler("ProjectHoomans.server", function(api)
        local groups = PNC.AbstractGroups and PNC.AbstractGroups.List and PNC.AbstractGroups.List() or {}
        local sites = PNC.Communities and PNC.Communities.ListSites and PNC.Communities.ListSites() or {}
        local dirty = countMap(PNC.Registry and PNC.Registry.DirtyByID)
        api.SetGauge("ProjectHoomans.Groups.Total", #groups)
        api.SetGauge("ProjectHoomans.Settlements.Total", #sites)
        api.SetGauge("ProjectHoomans.Persistence.DirtyRecords", dirty)
    end)
    Integration.serverInstalled = true
    return true
end

function Integration.WrapServerTick(callback)
    if type(callback) ~= "function" then return callback end
    local wrapped = Profiler.Wrap("ProjectHoomans.Server.Update", callback)
    Profiler.RegisterStopHook("ProjectHoomans.serverTick", function()
        if Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(wrapped)
            Events.OnTick.Add(callback)
        end
        if PNC.Server then PNC.Server.OnTick = callback end
    end)
    return wrapped
end

return Integration
