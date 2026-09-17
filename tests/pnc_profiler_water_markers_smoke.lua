local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "BASIC"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local now = 0

local function callback(name)
    return function() return name end
end

Profiler.Start("BASIC", {
    nowMs = function() return now end,
    sourceType = function() return "test" end,
})

PNC = {
    Core = { Now = function() return now end },
    Server = { Internal = { ProcessRecord = callback("process") } },
    Registry = { Data = {}, LiveByID = {}, DirtyByID = {} },
    WorldCensus = { OrdinaryZombies = {}, ManagedBodies = {} },
    Scheduler = { PopDue = callback("pop"), PumpJobs = callback("jobs"),
        Schedule = callback("schedule"), Buckets = {} },
    SpatialIndex = { Rebuild = callback("rebuild"),
        UpdateNPC = callback("update") },
    Perception = { GetZombieFrame = callback("frame") },
    BehaviorSystem = { Tick = callback("behavior") },
    PathService = { Pump = callback("path") },
    Network = {
        BroadcastRecord = callback("broadcast"),
        BuildSnapshot = callback("snapshot"),
        BuildPresenceDelta = callback("presence"),
        FlushRosterDeltas = callback("flush"),
        Internal = {
            QueueBroadcastRoster = callback("queue"),
            CollectRecordRecipients = callback("recipients"),
            BuildRecordPayload = callback("payload"),
            SendRecordPayload = callback("send"),
        },
    },
    NeedFacilityTriggers = {
        GetCandidates = callback("candidates"),
        Assign = callback("assign"),
        Start = callback("start"),
    },
    NeedFacilityEffects = { Tick = callback("effect") },
    NearbyWaterService = {
        ResolveHydrationPlan = callback("plan"),
        FindSource = callback("source"),
        BuildApproach = callback("approach"),
        Consume = callback("drink"),
    },
    WaterContainerService = {
        CanRefill = callback("admission"),
        Refill = callback("refill"),
    },
    FacilityJobsBehaviorInternal = {
        Tick = callback("facility_tick"),
        OnSceneTick = callback("scene_tick"),
    },
}

local targets = {
    { PNC.NeedFacilityTriggers, "GetCandidates",
        "ProjectHoomans.Server.Update.NPC.Needs.Candidates" },
    { PNC.NeedFacilityTriggers, "Assign",
        "ProjectHoomans.Server.Update.NPC.Needs.Assignment" },
    { PNC.NeedFacilityTriggers, "Start",
        "ProjectHoomans.Server.Update.NPC.Needs.Start" },
    { PNC.NeedFacilityEffects, "Tick",
        "ProjectHoomans.Server.Update.NPC.Needs.EffectTick" },
    { PNC.NearbyWaterService, "ResolveHydrationPlan",
        "ProjectHoomans.Server.Update.NPC.Water.Plan" },
    { PNC.NearbyWaterService, "FindSource",
        "ProjectHoomans.Server.Update.NPC.Water.SourceSearch" },
    { PNC.NearbyWaterService, "BuildApproach",
        "ProjectHoomans.Server.Update.NPC.Water.Approach" },
    { PNC.NearbyWaterService, "Consume",
        "ProjectHoomans.Server.Update.NPC.Water.DrinkCommit" },
    { PNC.WaterContainerService, "CanRefill",
        "ProjectHoomans.Server.Update.NPC.Water.RefillAdmission" },
    { PNC.WaterContainerService, "Refill",
        "ProjectHoomans.Server.Update.NPC.Water.RefillTransaction" },
    { PNC.FacilityJobsBehaviorInternal, "Tick",
        "ProjectHoomans.Server.Update.NPC.FacilityActivity.Tick" },
    { PNC.FacilityJobsBehaviorInternal, "OnSceneTick",
        "ProjectHoomans.Server.Update.NPC.FacilityActivity.SceneTick" },
}

local originals = {}
for index = 1, #targets do
    local owner = targets[index][1]
    local key = targets[index][2]
    originals[index] = {
        callback = owner[key],
        returnValue = owner[key](),
    }
end

local Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
Integration.InstallServer()

for index = 1, #targets do
    local owner = targets[index][1]
    local key = targets[index][2]
    local metric = targets[index][3]
    T.truthy(owner[key] ~= originals[index].callback,
        metric .. " was not installed")
    T.equal(owner[key](), originals[index].returnValue,
        metric .. " changed the wrapped return value")
end

now = 1000
PNC.Registry.Data.water = {
    runtime = { facilityActivity = {
        resourceKind = "water_refill", manualOverride = true,
    }},
}
Profiler.Sample(1000)
local metrics = Profiler.GetMetrics("timer", "ProjectHoomans")
local seen = {}
for index = 1, #metrics do seen[metrics[index].name] = true end
for index = 1, #targets do
    T.truthy(seen[targets[index][3]],
        targets[index][3] .. " was not recorded")
end
local gauges = Profiler.GetMetrics("gauge", "ProjectHoomans")
local seenGauges = {}
for index = 1, #gauges do seenGauges[gauges[index].name] = true end
T.truthy(seenGauges["ProjectHoomans.NPC.Water.Active"],
    "water activity gauge was not registered")
T.truthy(seenGauges["ProjectHoomans.NPC.Water.RefillActive"],
    "refill activity gauge was not registered")
T.truthy(seenGauges["ProjectHoomans.NPC.Water.ManualOverrides"],
    "manual water override gauge was not registered")

Profiler.Stop()
for index = 1, #targets do
    T.equal(targets[index][1][targets[index][2]], originals[index].callback,
        targets[index][3] .. " was not restored")
end

T.finish("pnc_profiler_water_markers_smoke")
