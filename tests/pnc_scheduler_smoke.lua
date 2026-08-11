PNC = {
    Const = {
        PRESENCE_ABSTRACT = "abstract",
        TICK_ABSTRACT_MS = 3000,
        TICK_LIVE_HOT_MS = 100,
        TICK_LIVE_WARM_MS = 250,
        TICK_LIVE_COLD_MS = 1000,
        SCHEDULER_MAX_RECORDS_PER_TICK = 24,
        SCHEDULER_MAX_JOBS_PER_TICK = 1,
    },
    Identity = {
        MixSeed = function(seed) return (tonumber(seed) or 1) * 97 end,
    },
}

dofile("Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Scheduling/PNC_Scheduler.lua")

local records = {}
for i = 1, 500 do
    records["npc_" .. tostring(i)] = {
        id = "npc_" .. tostring(i),
        identitySeed = i,
        presenceState = "abstract",
        runtime = {},
    }
end

local first = PNC.Scheduler.PopDue(records, 1000)
assert(#first < 500, "abstract scheduler processed every NPC in one tick")

local hot = {
    id = "npc_hot",
    identitySeed = 999,
    presenceState = "live",
    runtime = { attackAction = {} },
}
records[hot.id] = hot
PNC.Scheduler.Schedule(hot, 1050)
local due = PNC.Scheduler.PopDue(records, 1050)
local found = false
for i = 1, #due do found = found or due[i] == hot end
assert(found, "hot record did not retain 50ms cadence")

PNC.Scheduler.Buckets = {}
PNC.Scheduler.SlotByID = {}
PNC.Scheduler.Initialized = true
PNC.Scheduler.LastSlot = 20
local crowded = {}
for i = 1, 100 do
    local crowdedRecord = {
        id = "crowded_" .. tostring(i),
        identitySeed = i,
        presenceState = "live",
        runtime = { attackAction = {} },
    }
    crowded[crowdedRecord.id] = crowdedRecord
    PNC.Scheduler.Schedule(crowdedRecord, 1050)
end
local bounded = PNC.Scheduler.PopDue(crowded, 1050)
assert(#bounded <= 24, "scheduler exceeded the per-tick record budget")
local deferred = PNC.Scheduler.PopDue(crowded, 1100)
assert(#deferred > 0 and #deferred <= 24,
    "scheduler did not defer crowded records")

local downed = {
    presenceState = "live",
    health = { state = "incapacitated" },
    runtime = {},
}
assert(PNC.Scheduler.GetCadence(downed) <= 100, "incapacitated maintenance cadence is too slow")

local passenger = {
    presenceState = "abstract",
    runtime = {
        vehiclePassenger = { active = true },
    },
}
assert(PNC.Scheduler.GetCadence(passenger) <= 100, "vehicle passenger tracking cadence is too slow")

local strategicRuns = {}
PNC.Scheduler.RegisterJob("strategic_a", 10, function()
    strategicRuns[#strategicRuns + 1] = "a"
end, { startAt = 2000 })
PNC.Scheduler.RegisterJob("strategic_b", 10, function()
    strategicRuns[#strategicRuns + 1] = "b"
end, { startAt = 2000 })
assert(PNC.Scheduler.PumpJobs(2000) == 1,
    "scheduler ran aligned strategic jobs in one frame")
assert(#strategicRuns == 1,
    "strategic per-frame budget was not enforced")
assert(PNC.Scheduler.PumpJobs(2000) == 1 and #strategicRuns == 2,
    "deferred strategic job did not run on the next frame")

print("pnc_scheduler_smoke: ok")
