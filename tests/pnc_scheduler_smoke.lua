PNC = {
    Const = {
        PRESENCE_ABSTRACT = "abstract",
        TICK_ABSTRACT_MS = 3000,
        TICK_LIVE_HOT_MS = 100,
        TICK_LIVE_WARM_MS = 250,
        TICK_LIVE_COLD_MS = 1000,
    },
    Identity = {
        MixSeed = function(seed) return (tonumber(seed) or 1) * 97 end,
    },
}

dofile("Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Scheduling/PNC_Scheduler.lua")

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

print("pnc_scheduler_smoke: ok")
