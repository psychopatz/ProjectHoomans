local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local tickHandlers = {}
local sampleCallback = nil

getTimeInMillis = function() return now end
isServer = function() return true end
isClient = function() return false end
Events = {
    OnTick = {
        Add = function(fn)
            for i = 1, #tickHandlers do
                if tickHandlers[i] == fn then return end
            end
            tickHandlers[#tickHandlers + 1] = fn
        end,
        Remove = function(fn)
            for i = #tickHandlers, 1, -1 do
                if tickHandlers[i] == fn then table.remove(tickHandlers, i) end
            end
        end,
    },
    EveryOneSecond = {
        Add = function(fn) sampleCallback = fn end,
        Remove = function(fn) if sampleCallback == fn then sampleCallback = nil end end,
    },
}
package.preload["PsychopatzCore/Profiler/PsychopatzProfilerClient"] = function()
    return { Start = function() return true end, Stop = function() return true end,
        SetCaptureActive = function() end, ClearServerSnapshot = function() end }
end

local function makeCallback(label)
    return function() return label end
end

local origSpatialRebuild = makeCallback("spatial_rebuild")
local origCensusRefresh = makeCallback("census_refresh")
local origBroadcast = makeCallback("broadcast")
local origBuildSnapshot = makeCallback("full_snapshot")
local origCombatDelta = makeCallback("combat_delta")
local origPresenceDelta = makeCallback("presence_delta")
local origFlushDeltas = makeCallback("flush_deltas")
local origCommit = makeCallback("commit")
local origFlushDirty = makeCallback("flush_dirty")
local origMaterialize = makeCallback("materialize")
local origBehaviorTick = makeCallback("behavior_tick")
local origPathPump = makeCallback("path_pump")
local origProcessRecord = makeCallback("process_record")
local origServerTick = makeCallback("server_tick")
local origExistingJob = makeCallback("existing_job")
local origNewJob = makeCallback("new_job")

local function createWorld()
    tickHandlers = { origServerTick }
    local registerJob = function(name, interval, cb)
        PNC.Scheduler.Jobs[name] = { interval = interval, callback = cb }
        return true, PNC.Scheduler.Jobs[name]
    end
    PNC = {
        Core = { Now = function() return now end },
        Server = {
            OnTick = origServerTick,
            Internal = { ProcessRecord = origProcessRecord },
            InstallProfilerWrappers = function(wrap)
                wrap(PNC.Server.Internal, "ProcessRecord", "Server.Update.NPC.ProcessRecord")
            end,
        },
        Registry = { Data = {}, LiveByID = {}, DirtyByID = {}, FlushDirty = origFlushDirty },
        PersistenceCoordinator = { Commit = origCommit },
        Presence = { Materialize = origMaterialize },
        WorldCensus = { Refresh = origCensusRefresh, OrdinaryZombies = {}, ManagedBodies = {} },
        SpatialIndex = { Rebuild = origSpatialRebuild },
        BehaviorSystem = { Tick = origBehaviorTick },
        PathService = { Pump = origPathPump },
        Scheduler = {
            Buckets = {},
            Jobs = { Existing = { interval = 1000, callback = origExistingJob } },
            RegisterJob = registerJob,
        },
        Network = {
            BroadcastRecord = origBroadcast,
            BuildSnapshot = origBuildSnapshot,
            BuildCombatDamageDelta = origCombatDelta,
            BuildPresenceDelta = origPresenceDelta,
            FlushRosterDeltas = origFlushDeltas,
        },
    }
    return registerJob
end

-- 1. Strict OFF without bridge installs zero wrappers and does not load backend.
local origRegisterJob = createWorld()
PsychopatzCore = nil
PSYCHOPATZ_PROFILER_MODE = nil
getFileReader = function() return nil end
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.Initialize()
local Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
T.equal(PsychopatzCore.Profiler, nil, "OFF without bridge must not load Profiler backend")
T.equal(PNC.SpatialIndex.Rebuild, origSpatialRebuild, "OFF touched SpatialIndex.Rebuild")
T.equal(PNC.BehaviorSystem.Tick, origBehaviorTick, "OFF touched BehaviorSystem.Tick")
T.equal(PNC.Server.OnTick, origServerTick, "OFF touched Server.OnTick")

-- 2. Strict OFF with bridge enabled registers controller only and installs zero wrappers.
package.loaded["PNC/Integrations/PNC_PsychopatzProfiler"] = nil
package.loaded["PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"] = nil
package.loaded["PsychopatzCore/Profiler/PsychopatzProfilerFeatureRegistry"] = nil
PsychopatzCore = { BridgeBootstrap = { IsEnabled = function() return true end } }
origRegisterJob = createWorld()
Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.Initialize()
Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
T.equal(PsychopatzCore.Profiler, nil, "OFF with bridge must not load Profiler backend")
T.equal(Integration.GetInstalledWrapperCounts().total, 0, "OFF with bridge installed wrappers")
T.equal(PNC.SpatialIndex.Rebuild, origSpatialRebuild, "OFF bridge touched SpatialIndex")
T.equal(PNC.BehaviorSystem.Tick, origBehaviorTick, "OFF bridge touched BehaviorSystem")
T.equal(PNC.Server.OnTick, origServerTick, "OFF bridge touched Server.OnTick")

-- 3. Live switch to COARSE wraps only coarse boundaries and leaves deep untouched.
local res = Bootstrap.ApplyCaptureConfig({ mode = "BASIC", capture = { "performance" } })
T.equal(res.applied, true, "coarse live apply")
T.equal(res.performance_depth, "coarse", "coarse performance depth")
local counts = Integration.GetInstalledWrapperCounts()
T.truthy(counts.coarse > 0 and counts.coarse <= 15, "expected bounded coarse wrappers")
T.equal(counts.deep, 0, "coarse mode installed deep wrappers")
T.truthy(PNC.SpatialIndex.Rebuild ~= origSpatialRebuild, "coarse did not wrap SpatialIndex")
T.truthy(PNC.WorldCensus.Refresh ~= origCensusRefresh, "coarse did not wrap WorldCensus")
T.truthy(PNC.PersistenceCoordinator.Commit ~= origCommit, "coarse did not wrap Commit")
T.truthy(PNC.Registry.FlushDirty ~= origFlushDirty, "coarse did not wrap FlushDirty")
T.truthy(PNC.Presence.Materialize ~= origMaterialize, "coarse did not wrap Materialize")
T.truthy(PNC.Server.OnTick ~= origServerTick, "coarse did not wrap Server.OnTick")
T.equal(tickHandlers[1], PNC.Server.OnTick, "OnTick event not updated to coarse wrapper")
T.equal(#tickHandlers, 1, "coarse duplicated OnTick listener")
T.equal(PNC.BehaviorSystem.Tick, origBehaviorTick, "coarse wrapped deep BehaviorSystem.Tick")
T.equal(PNC.PathService.Pump, origPathPump, "coarse wrapped deep PathService.Pump")
T.equal(PNC.Server.Internal.ProcessRecord, origProcessRecord, "coarse wrapped deep ProcessRecord")
T.equal(PNC.Scheduler.RegisterJob, origRegisterJob, "coarse wrapped deep Scheduler.RegisterJob")

-- 4. Live switch to explicit time-bounded DEEP installs deep + job hooks, then expires cleanly.
now = 5000
res = Bootstrap.ApplyCaptureConfig({
    mode = "DETAILED",
    capture = { "performance" },
    performance_depth = "deep",
    deep_duration_ms = 5000,
})
T.equal(res.applied, true, "deep live apply")
T.equal(res.performance_depth, "deep", "deep performance depth")
T.equal(res.deep_expires_at_ms, 10000, "deep expiry timestamp")
counts = Integration.GetInstalledWrapperCounts()
T.truthy(counts.coarse > 0 and counts.deep > 0, "deep mode missing coarse or deep wrappers")
T.truthy(PNC.BehaviorSystem.Tick ~= origBehaviorTick, "deep missing BehaviorSystem")
T.truthy(PNC.PathService.Pump ~= origPathPump, "deep missing PathService")
T.truthy(PNC.Server.Internal.ProcessRecord ~= origProcessRecord, "deep missing ProcessRecord")
T.truthy(PNC.Scheduler.Jobs.Existing.callback ~= origExistingJob, "deep missing existing job wrapper")
T.truthy(PNC.Scheduler.RegisterJob ~= origRegisterJob, "deep missing RegisterJob hook")
PNC.Scheduler.RegisterJob("Dynamic", 500, origNewJob)
T.truthy(PNC.Scheduler.Jobs.Dynamic.callback ~= origNewJob, "deep RegisterJob did not wrap new job")

-- Advance clock past expiry and run Sample.
now = 10000
PsychopatzCore.Profiler.Sample(1000)
T.equal(PsychopatzCore.Profiler.GetPerformanceDepth(), "coarse", "expiry downgraded profiler depth")
T.equal(Bootstrap.GetPerformanceDepth(), "coarse", "expiry updated bootstrap depth")
counts = Integration.GetInstalledWrapperCounts()
T.equal(counts.deep, 0, "deep wrappers remained after expiry")
T.truthy(counts.coarse > 0, "coarse wrappers lost after deep expiry")
T.equal(PNC.BehaviorSystem.Tick, origBehaviorTick, "BehaviorSystem not restored on expiry")
T.equal(PNC.PathService.Pump, origPathPump, "PathService not restored on expiry")
T.equal(PNC.Server.Internal.ProcessRecord, origProcessRecord, "ProcessRecord not restored on expiry")
T.equal(PNC.Scheduler.Jobs.Existing.callback, origExistingJob, "existing job not restored on expiry")
T.equal(PNC.Scheduler.Jobs.Dynamic.callback, origNewJob, "dynamic job not restored on expiry")
T.equal(PNC.Scheduler.RegisterJob, origRegisterJob, "RegisterJob hook not restored on expiry")
T.truthy(PNC.SpatialIndex.Rebuild ~= origSpatialRebuild, "coarse SpatialIndex lost on expiry")
T.truthy(PNC.Server.OnTick ~= origServerTick, "coarse Server.OnTick lost on expiry")

-- 5. Disable transitions back to OFF and restores every remaining coarse wrapper and OnTick.
Bootstrap.Disable()
counts = Integration.GetInstalledWrapperCounts()
T.equal(counts.total, 0, "Disable left wrappers installed")
T.equal(PNC.SpatialIndex.Rebuild, origSpatialRebuild, "SpatialIndex not restored on Disable")
T.equal(PNC.WorldCensus.Refresh, origCensusRefresh, "WorldCensus not restored on Disable")
T.equal(PNC.Network.BroadcastRecord, origBroadcast, "BroadcastRecord not restored on Disable")
T.equal(PNC.Network.BuildSnapshot, origBuildSnapshot, "BuildSnapshot not restored on Disable")
T.equal(PNC.Network.BuildCombatDamageDelta, origCombatDelta, "CombatDelta not restored on Disable")
T.equal(PNC.Network.BuildPresenceDelta, origPresenceDelta, "PresenceDelta not restored on Disable")
T.equal(PNC.Network.FlushRosterDeltas, origFlushDeltas, "FlushRosterDeltas not restored on Disable")
T.equal(PNC.PersistenceCoordinator.Commit, origCommit, "Commit not restored on Disable")
T.equal(PNC.Registry.FlushDirty, origFlushDirty, "FlushDirty not restored on Disable")
T.equal(PNC.Presence.Materialize, origMaterialize, "Materialize not restored on Disable")
T.equal(PNC.Server.OnTick, origServerTick, "Server.OnTick not restored on Disable")
T.equal(#tickHandlers, 1, "Disable left duplicate OnTick listener")
T.equal(tickHandlers[1], origServerTick, "Events.OnTick not restored to original Server.OnTick")
T.equal(sampleCallback, nil, "EveryOneSecond sample callback survived Disable")

T.finish("pnc_profiler_off_and_expiry_smoke")
